<?php

namespace App\Listeners;

use Illuminate\Support\Facades\Log;

class NotifyAdminOfBookingListener
{
    public function handle($event): void
    {
        $booking = $event->booking;
        $eventClass = class_basename($event);

        $adminMessage = sprintf(
            '[NotifyAdmin] %s: Booking #%s (%s - %s, status: %s)',
            $eventClass,
            $booking->id,
            $booking->start,
            $booking->end,
            $booking->status
        );

        Log::channel('booking')->info($adminMessage, [
            'event' => $eventClass,
            'booking_id' => $booking->id,
            'status' => $booking->status,
            'start' => $booking->start,
            'end' => $booking->end,
            'timestamp' => now()->toDateTimeString(),
            'notified_admin' => true,
        ]);
    }
}
