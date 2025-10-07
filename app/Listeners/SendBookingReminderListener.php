<?php

namespace App\Listeners;

use Illuminate\Support\Facades\Log;

class SendBookingReminderListener
{
    public function handle($event): void
    {
        $booking = $event->booking;

        $message = sprintf(
            '[BookingReminder] Reminder sent for Booking #%s (%s - %s)',
            $booking->id,
            $booking->start,
            $booking->end
        );

        Log::channel('booking')->info($message, [
            'booking_id' => $booking->id,
            'start' => $booking->start,
            'end' => $booking->end,
            'timestamp' => now()->toDateTimeString(),
        ]);
    }
}
