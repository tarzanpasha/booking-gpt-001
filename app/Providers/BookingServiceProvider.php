<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Services\BookingService;
use App\Console\Commands\SendBookingRemindersCommand;

class BookingServiceProvider extends ServiceProvider
{
    public function register()
    {
        $this->app->singleton(BookingService::class, function ($app) {
            return new BookingService($app['db'], $app['cache.store']);
        });
    }

    public function boot()
    {
        if ($this->app->runningInConsole()) {
            $this->commands([
                SendBookingRemindersCommand::class,
            ]);
        }
    }
}
