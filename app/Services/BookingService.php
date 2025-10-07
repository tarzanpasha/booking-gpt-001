<?php

namespace App\Services;

use App\Models\{Booking, Resource};
use App\Events\{
    BookingCreated,
    BookingPendingConfirmation,
    BookingConfirmed,
    BookingCancelled,
    BookingRescheduled
};
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Exception;

class BookingService
{
    protected function log(string $message, array $context = []): void
    {
        Log::channel('booking')->info($message, array_merge([
            'timestamp' => now()->toDateTimeString(),
        ], $context));
    }

    public function createBooking(Resource $resource, Carbon $start, Carbon $end, bool $isGroup = false): Booking
    {
        $this->log('🔹 createBooking() вызван', [
            'resource_id' => $resource->id,
            'start' => $start,
            'end' => $end,
            'is_group_booking' => $isGroup,
        ]);

        return DB::transaction(function () use ($resource, $start, $end, $isGroup) {
            $key = "booking_lock_{$resource->id}";

            return Cache::lock($key, 5)->block(3, function () use ($resource, $start, $end, $isGroup) {

                $this->log('Проверяем пересечение броней...', [
                    'resource_id' => $resource->id,
                    'start' => $start,
                    'end' => $end,
                ]);

                $overlap = Booking::where('resource_id', $resource->id)
                    ->where('start', '<', $end)
                    ->where('end', '>', $start)
                    ->exists();

                if ($overlap) {
                    $this->log('❌ Слот занят', ['resource_id' => $resource->id]);
                    throw new Exception("Slot not available");
                }

                $status = $resource->resource_config->require_confirmation
                    ? 'pending_confirmation'
                    : 'confirmed';

                $booking = Booking::create([
                    'company_id' => $resource->company_id,
                    'resource_id' => $resource->id,
                    'is_group_booking' => $isGroup,
                    'start' => $start,
                    'end' => $end,
                    'status' => $status,
                ]);

                $this->log('✅ Бронирование создано', [
                    'booking_id' => $booking->id,
                    'status' => $booking->status,
                ]);

                event(new BookingCreated($booking));

                if ($booking->status === 'pending_confirmation') {
                    event(new BookingPendingConfirmation($booking));
                } else {
                    event(new BookingConfirmed($booking));
                }

                return $booking;
            });
        });
    }

    public function confirmBooking(Booking $booking): Booking
    {
        $this->log('🔹 confirmBooking() вызван', ['booking_id' => $booking->id]);

        if ($booking->status !== 'pending_confirmation') {
            throw new Exception("Booking is not pending confirmation");
        }

        $booking->update(['status' => 'confirmed']);
        $this->log('✅ Бронирование подтверждено', ['booking_id' => $booking->id]);
        event(new BookingConfirmed($booking));

        return $booking;
    }

    public function cancelBooking(Booking $booking, string $by = 'client', ?string $reason = null): Booking
    {
        $this->log('🔹 cancelBooking() вызван', [
            'booking_id' => $booking->id,
            'cancelled_by' => $by,
            'reason' => $reason,
        ]);

        if (!in_array($booking->status, ['pending_confirmation', 'confirmed'])) {
            throw new Exception("Booking cannot be cancelled");
        }

        $status = $by === 'admin' ? 'cancelled_by_admin' : 'cancelled_by_client';
        $booking->update(['status' => $status, 'reason' => $reason]);

        $this->log('❌ Бронирование отменено', [
            'booking_id' => $booking->id,
            'status' => $status,
            'reason' => $reason,
        ]);

        event(new BookingCancelled($booking));
        return $booking;
    }

    public function rescheduleBooking(Booking $booking, Carbon $newStart, Carbon $newEnd, string $by = 'client'): Booking
    {
        $this->log('🔹 rescheduleBooking() вызван', [
            'booking_id' => $booking->id,
            'new_start' => $newStart,
            'new_end' => $newEnd,
            'requested_by' => $by,
        ]);

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
        $this->log('✅ Бронирование перенесено', [
            'booking_id' => $booking->id,
            'new_start' => $newStart,
            'new_end' => $newEnd,
        ]);

        event(new BookingRescheduled($booking));
        return $booking;
    }
}
