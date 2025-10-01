<?php

namespace App\Events;

use Illuminate\Queue\SerializesModels;
use App\Models\Booking;

class BookingRejected {
    use SerializesModels;
    public function __construct(public Booking $booking) {}
}
