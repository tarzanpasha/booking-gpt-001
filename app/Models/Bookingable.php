<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Bookingable extends Model
{
    protected $table = 'bookingables';
    protected $fillable = ['booking_id','bookingable_type','bookingable_id'];
    public function booking() { return $this->belongsTo(Booking::class, 'booking_id'); }
    public function bookingable() { return $this->morphTo(); }
}
