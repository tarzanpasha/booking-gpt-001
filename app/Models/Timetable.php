<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Timetable extends Model
{
    protected $fillable = [
        'company_id',
        'resource_id',
        'name',
        'type',
        'payload',
    ];

    protected $casts = [
        'payload' => 'array',
    ];

    public function resource()
    {
        return $this->belongsTo(Resource::class);
    }

    public function dates()
    {
        return $this->hasMany(TimetableDate::class);
    }
}
