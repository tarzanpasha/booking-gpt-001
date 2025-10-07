<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Resource extends Model
{
    protected $fillable = [
        'company_id',
        'resource_type_id',
        'options',
        'payload',
        'resource_config',
    ];

    protected $casts = [
        'options' => 'array',
        'payload' => 'array',
        'resource_config' => \App\Casts\ResourceConfigCast::class,
    ];

    public function type()
    {
        return $this->belongsTo(ResourceType::class, 'resource_type_id');
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }
}
