<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Resource;
use App\Services\BookingService;
use Carbon\Carbon;

class RunBookingDemoActionsCommand extends Command
{
    protected $signature = 'booking:run-demo-actions';
    protected $description = 'Run demo scenario: create, confirm, cancel, reschedule booking';

    public function handle(BookingService $service)
    {
        $this->info("Running demo actions...");

        $ivan = Resource::find(1);
        $booking = $service->createBooking($ivan, Carbon::parse('2025-10-01 10:00:00'), Carbon::parse('2025-10-01 11:00:00'));
        $this->info("Created booking #{$booking->id} (pending)");

        $service->confirmBooking($booking);
        $this->info("Confirmed booking #{$booking->id}");

        $service->rescheduleBooking($booking, Carbon::parse('2025-10-02 11:00:00'), Carbon::parse('2025-10-02 12:00:00'));
        $this->info("Rescheduled booking #{$booking->id}");

        $service->cancelBooking($booking, 'client', 'Client changed mind');
        $this->info("Cancelled booking #{$booking->id}");
    }
}
