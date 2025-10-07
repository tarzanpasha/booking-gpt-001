<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\BookingController;

Route::prefix('resources/{resourceId}/bookings')->group(function () {
    Route::post('/', [BookingController::class, 'store']);
});

Route::prefix('bookings')->group(function () {
    Route::post('{id}/confirm', [BookingController::class, 'confirm']);
    Route::post('{id}/cancel', [BookingController::class, 'cancel']);
    Route::post('{id}/reschedule', [BookingController::class, 'reschedule']);
});
