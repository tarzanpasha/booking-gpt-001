<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Route;

class BookingServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Здесь можно регистрировать сервисы
    }

    public function boot(): void
    {
        Route::middleware('api')
            ->prefix('api')
            ->group(base_path('routes/booking.php'));
    }
}

        // Регистрируем слушатели событий бронирования
        $this->app->register(\App\Providers\EventServiceProvider::class);
