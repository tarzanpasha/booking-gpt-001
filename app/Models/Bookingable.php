<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Bookingable extends Model
{
    protected $fillable = [
        'booking_id',
        'bookingable_id',
        'bookingable_type',
    ];

    public function booking()
    {
        return $this->belongsTo(Booking::class);
    }

    public function bookingable()
    {
        return $this->morphTo();
    }
}
