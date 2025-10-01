<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Booking;
use App\Events\BookingReminder;
use DateTime;

class SendBookingRemindersCommand extends Command {
    protected $signature = 'booking:send-reminders {--minutes=1 : window minutes to check}';
    protected $description = 'Send booking reminders according to resource config';

    public function handle() {
        $window = (int)$this->option('minutes');
        $now = new DateTime();
        $until = (new DateTime())->add(new \DateInterval("PT{$window}M"));

        $bookings = Booking::where('status','confirmed')
            ->get();

        foreach ($bookings as $b) {
            $cfg = $b->resource->resource_config;
            if (!$cfg->remind_before_minutes) continue;
            $triggerAt = (new DateTime($b->start))->sub(new \DateInterval("PT{$cfg->remind_before_minutes}M"));
            if ($triggerAt >= $now && $triggerAt <= $until) {
                event(new BookingReminder($b));
            }
        }
        $this->info('Reminders scanned');
    }
}
