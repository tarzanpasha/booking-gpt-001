<?php

namespace App\Listeners;

use Illuminate\Support\Facades\Log;

class LogBookingActivityListener
{
    public function handle($event): void
    {
        $eventClass = class_basename($event);
        $bookingId = $event->booking->id ?? null;
        $status = $event->booking->status ?? 'unknown';

        $message = sprintf('[BookingEvent] %s: Booking #%s (status: %s)', $eventClass, $bookingId, $status);

        Log::channel('booking')->info($message, [
            'event' => $eventClass,
            'booking_id' => $bookingId,
            'status' => $status,
            'timestamp' => now()->toDateTimeString(),
        ]);
    }
}
