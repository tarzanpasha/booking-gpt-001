<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;
use App\Events\{
    BookingCreated,
    BookingPendingConfirmation,
    BookingConfirmed,
    BookingRejected,
    BookingCancelled,
    BookingRescheduled,
    BookingReminder
};
use App\Listeners\{
    LogBookingActivityListener,
    SendBookingReminderListener,
    NotifyAdminOfBookingListener
};

class EventServiceProvider extends ServiceProvider
{
    protected $listen = [
        BookingCreated::class => [
            LogBookingActivityListener::class,
            NotifyAdminOfBookingListener::class,
        ],
        BookingPendingConfirmation::class => [
            LogBookingActivityListener::class,
            NotifyAdminOfBookingListener::class,
        ],
        BookingConfirmed::class => [
            LogBookingActivityListener::class,
            NotifyAdminOfBookingListener::class,
        ],
        BookingRejected::class => [
            LogBookingActivityListener::class,
            NotifyAdminOfBookingListener::class,
        ],
        BookingCancelled::class => [
            LogBookingActivityListener::class,
            NotifyAdminOfBookingListener::class,
        ],
        BookingRescheduled::class => [
            LogBookingActivityListener::class,
            NotifyAdminOfBookingListener::class,
        ],
        BookingReminder::class => [
            LogBookingActivityListener::class,
            SendBookingReminderListener::class,
            NotifyAdminOfBookingListener::class,
        ],
    ];

    public function boot(): void
    {
        parent::boot();
    }
}
