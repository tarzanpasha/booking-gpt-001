<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TimetableDate extends Model
{
    protected $fillable = [
        'timetable_id',
        'date',
        'start',
        'end',
        'breaks',
    ];

    protected $casts = [
        'date' => 'date',
        'breaks' => 'array',
    ];

    public function timetable()
    {
        return $this->belongsTo(Timetable::class);
    }
}
