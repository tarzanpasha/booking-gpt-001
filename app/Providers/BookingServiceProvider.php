<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class BookingServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        if ($this->app->runningInConsole()) {
            $this->commands([
                \App\Console\Commands\SeedBookingDemoCommand::class,
                \App\Console\Commands\ShowBookingDemoCurlCommand::class,
                \App\Console\Commands\RunBookingDemoActionsCommand::class,
                \App\Console\Commands\SendBookingRemindersCommand::class,
            ]);
        }

        $this->loadRoutesFrom(base_path('routes/booking.php'));
    }
}
