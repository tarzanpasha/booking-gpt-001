<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Booking;
use Carbon\Carbon;

class SendBookingRemindersCommand extends Command
{
    protected $signature = 'booking:send-reminders {--minutes=10}';
    protected $description = 'Send reminders for upcoming bookings';

    public function handle()
    {
        $minutes = (int)$this->option('minutes');
        $from = now();
        $to = now()->addMinutes($minutes);

        $bookings = Booking::where('status','confirmed')
            ->whereBetween('start', [$from, $to])
            ->get();

        foreach ($bookings as $booking) {
            $this->info("Reminder: booking #{$booking->id} at {$booking->start}");
        }
    }
}
