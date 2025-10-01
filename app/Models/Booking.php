<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    protected $table = 'bookings';
    protected $fillable = [
        'company_id','resource_id','timetable_id','is_group_booking','start','end','status','reason','meta','participants_count'
    ];
    protected $casts = [
        'meta' => 'array',
        'is_group_booking' => 'boolean',
        'start' => 'datetime',
        'end' => 'datetime',
    ];

    public function participants() {
        return $this->hasMany(Bookingable::class, 'booking_id');
    }
    public function resource() { return $this->belongsTo(Resource::class,'resource_id'); }
}
