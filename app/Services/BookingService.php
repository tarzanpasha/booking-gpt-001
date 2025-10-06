<?php

namespace App\Services;

use App\Models\{Booking, Resource};
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Exception;

class BookingService
{
    public function createBooking(Resource $resource, Carbon $start, Carbon $end, bool $isGroup = false, int $participants = 1): Booking
    {
        return DB::transaction(function () use ($resource, $start, $end, $isGroup, $participants) {
            $key = "booking_lock_{$resource->id}";
            return Cache::lock($key, 5)->block(3, function () use ($resource, $start, $end, $isGroup, $participants) {

                $overlap = Booking::where('resource_id', $resource->id)
                    ->where('start', '<', $end)
                    ->where('end', '>', $start)
                    ->exists();

                if ($overlap) {
                    throw new Exception("Slot not available");
                }

                return Booking::create([
                    'company_id' => $resource->company_id,
                    'resource_id' => $resource->id,
                    'timetable_id' => optional($resource->timetable)->id,
                    'is_group_booking' => $isGroup,
                    'start' => $start,
                    'end' => $end,
                    'status' => $resource->resource_config['require_confirmation'] ? 'pending_confirmation' : 'confirmed',
                ]);
            });
        });
    }

    public function confirmBooking(Booking $booking): Booking
    {
        if ($booking->status !== 'pending_confirmation') {
            throw new Exception("Booking is not pending confirmation");
        }
        $booking->update(['status' => 'confirmed']);
        return $booking;
    }

    public function cancelBooking(Booking $booking, string $by = 'client', ?string $reason = null): Booking
    {
        if (!in_array($booking->status, ['pending_confirmation','confirmed'])) {
            throw new Exception("Booking cannot be cancelled");
        }
        $status = $by === 'admin' ? 'cancelled_by_admin' : 'cancelled_by_client';
        $booking->update(['status' => $status, 'reason' => $reason]);
        return $booking;
    }

    public function rescheduleBooking(Booking $booking, Carbon $newStart, Carbon $newEnd, string $by = 'client'): Booking
    {
        if ($booking->status !== 'confirmed') {
            throw new Exception("Only confirmed bookings can be rescheduled");
        }
        if ($by === 'client' && $booking->is_group_booking) {
            throw new Exception("Clients cannot reschedule group bookings");
        }

        $overlap = Booking::where('resource_id', $booking->resource_id)
            ->where('id', '<>', $booking->id)
            ->where('start', '<', $newEnd)
            ->where('end', '>', $newStart)
            ->exists();

        if ($overlap) {
            throw new Exception("New time not available");
        }

        $booking->update(['start' => $newStart, 'end' => $newEnd]);
        return $booking;
    }
}
