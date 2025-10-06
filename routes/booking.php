<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\BookingController;

Route::prefix('api')->group(function () {
    Route::post('resources/{resource}/bookings', [BookingController::class, 'store']);
    Route::post('bookings/{booking}/confirm', [BookingController::class, 'confirm']);
    Route::post('bookings/{booking}/cancel', [BookingController::class, 'cancel']);
    Route::post('bookings/{booking}/reschedule', [BookingController::class, 'reschedule']);
});
