<?php

namespace App\Events;

use Illuminate\Queue\SerializesModels;
use App\Models\Booking;

class BookingPendingConfirmation {
    use SerializesModels;
    public function __construct(public Booking $booking) {}
}
