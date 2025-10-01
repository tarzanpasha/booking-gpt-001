<?php

namespace App\Services;

use App\Models\Resource;
use App\Models\Booking;
use App\Models\Bookingable;
use Illuminate\Contracts\Cache\Repository as CacheRepository;
use Illuminate\Database\ConnectionInterface;
use Illuminate\Support\Str;
use App\Events\{
    BookingCreated, BookingPendingConfirmation, BookingConfirmed,
    BookingRejected, BookingCancelled, BookingRescheduled, BookingReminder
};
use DateTime;
use DateInterval;
use Illuminate\Support\Facades\Log;
use Throwable;

class BookingService
{
    public function __construct(
        protected ConnectionInterface $db,
        protected CacheRepository $cache
    ) {}

    public function getBookingsForResourceInRange(Resource $resource, DateTime $from, DateTime $to)
    {
        return Booking::where('resource_id', $resource->id)
            ->where('start','<',$to->format('Y-m-d H:i:s'))
            ->where('end','>',$from->format('Y-m-d H:i:s'))
            ->get();
    }

    public function isRangeAvailable(Resource $resource, DateTime $from, DateTime $to, int $additionalParticipants = 1): bool {
        $query = Booking::where('resource_id', $resource->id)
            ->where('start','<',$to->format('Y-m-d H:i:s'))
            ->where('end','>',$from->format('Y-m-d H:i:s'))
            ->whereIn('status',['confirmed','pending_confirmation','awaiting_payment','created']);

        if (!$resource->resource_config->max_participants) {
            return !$query->exists();
        }
        $total = $query->sum('participants_count');
        $max = $resource->resource_config->max_participants;
        return ($total + $additionalParticipants) <= $max;
    }

    public function createBooking(Resource $resource, DateTime $start, DateTime $end, $participant, int $participantsCount = 1, array $meta = []): Booking {
        $lockKey = "booking_lock:resource:{$resource->id}";
        $lock = $this->cache->lock($lockKey, 8);

        if (!$lock->get()) {
            throw new \RuntimeException('Resource locked, try again');
        }

        try {
            return $this->db->transaction(function() use($resource,$start,$end,$participant,$participantsCount,$meta,$lock) {
                $minAdv = $resource->resource_config->min_advance_time ?? 0;
                $now = new DateTime();
                $minAllowed = (clone $now)->add(new DateInterval("PT{$minAdv}M"));
                if ($start < $minAllowed) {
                    throw new \DomainException('Booking too soon according to min_advance_time');
                }

                if (!$this->isRangeAvailable($resource, $start, $end, $participantsCount)) {
                    throw new \DomainException('Range not available');
                }

                $isGroup = (bool)$resource->resource_config->max_participants;
                $status = $resource->resource_config->require_confirmation ? 'pending_confirmation' : 'confirmed';
                $booking = Booking::create([
                    'company_id' => $resource->company_id,
                    'resource_id' => $resource->id,
                    'timetable_id' => $resource->timetable?->id,
                    'is_group_booking' => $isGroup,
                    'start' => $start->format('Y-m-d H:i:s'),
                    'end' => $end->format('Y-m-d H:i:s'),
                    'status' => $status,
                    'meta' => $meta,
                    'participants_count' => $participantsCount,
                ]);

                Bookingable::create([
                    'booking_id' => $booking->id,
                    'bookingable_type' => get_class($participant),
                    'bookingable_id' => $participant->id,
                ]);

                event(new BookingCreated($booking));
                if ($status === 'pending_confirmation') {
                    event(new BookingPendingConfirmation($booking));
                } else {
                    event(new BookingConfirmed($booking));
                }

                Log::info('booking.created', ['booking_id'=>$booking->id, 'resource'=>$resource->id]);

                return $booking;
            });
        } catch (Throwable $e) {
            Log::error('booking.create_error', ['error'=>$e->getMessage()]);
            throw $e;
        } finally {
            try { $lock->release(); } catch (\Throwable $ignore) {}
        }
    }

    public function confirmBooking(Booking $booking): Booking {
        if ($booking->status !== 'pending_confirmation') {
            throw new \DomainException('Booking is not pending confirmation');
        }
        $booking->status = 'confirmed';
        $booking->save();
        event(new BookingConfirmed($booking));
        return $booking;
    }

    public function rejectBooking(Booking $booking, ?string $reason = null): Booking {
        if (!in_array($booking->status, ['pending_confirmation','created','creating'])) {
            throw new \DomainException('Booking cannot be rejected in current status');
        }
        $booking->status = 'rejected';
        $booking->reason = $reason;
        $booking->save();
        event(new BookingRejected($booking));
        return $booking;
    }

    public function cancelBooking(Booking $booking, string $cancelledBy = 'client', ?string $reason = null): Booking {
        if (\Str::startsWith($cancelledBy,'client')) {
            $cfg = $booking->resource->resource_config;
            if (!is_null($cfg->cancel_before_minutes)) {
                $limit = (new DateTime($booking->start))->sub(new DateInterval("PT{$cfg->cancel_before_minutes}M"));
                if ((new DateTime()) > $limit) {
                    throw new \DomainException('Too late to cancel by client');
                }
            }
            $booking->status = 'cancelled_by_client';
        } else {
            $booking->status = 'cancelled_by_admin';
        }
        $booking->reason = $reason;
        $booking->save();
        event(new BookingCancelled($booking));
        return $booking;
    }

    public function rescheduleBooking(Booking $booking, DateTime $newStart, DateTime $newEnd, string $requestedBy = 'client'): Booking {
        if (in_array($booking->status, ['cancelled_by_client','cancelled_by_admin','rejected'])) {
            throw new \DomainException('Cannot reschedule cancelled or rejected booking');
        }
        if ($requestedBy === 'client') {
            $cfg = $booking->resource->resource_config;
            if (!is_null($cfg->reschedule_before_minutes)) {
                $limit = (new DateTime($booking->start))->sub(new DateInterval("PT{$cfg->reschedule_before_minutes}M"));
                if ((new DateTime()) > $limit) {
                    throw new \DomainException('Too late to reschedule by client');
                }
            }
        }

        $overlapExists = Booking::where('resource_id', $booking->resource_id)
            ->where('id','<>',$booking->id)
            ->where('start','<',$newEnd->format('Y-m-d H:i:s'))
            ->where('end','>',$newStart->format('Y-m-d H:i:s'))
            ->whereIn('status',['confirmed','pending_confirmation','awaiting_payment','created'])
            ->exists();

        if ($overlapExists) {
            throw new \DomainException('Target range not available');
        }

        $old = ['start'=>$booking->start, 'end'=>$booking->end];
        $booking->start = $newStart->format('Y-m-d H:i:s');
        $booking->end = $newEnd->format('Y-m-d H:i:s');
        $booking->save();
        event(new BookingRescheduled($booking, $old));
        return $booking;
    }
}
