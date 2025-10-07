<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    protected $fillable = [
        'company_id',
        'resource_id',
        'timetable_id',
        'is_group_booking',
        'start',
        'end',
        'status',
        'reason',
    ];

    protected $casts = [
        'start' => 'datetime',
        'end' => 'datetime',
        'is_group_booking' => 'boolean',
    ];

    public function resource()
    {
        return $this->belongsTo(Resource::class);
    }
}
