<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Casts\ResourceConfigCast;

class Resource extends Model
{
    protected $table = 'resources';
    protected $fillable = ['company_id','resource_type_id','options','payload','resource_config'];
    protected $casts = [
        'options'=>'array',
        'payload'=>'array',
        'resource_config' => ResourceConfigCast::class,
    ];

    public function type() { return $this->belongsTo(ResourceType::class,'resource_type_id'); }
    public function timetable() { return $this->hasOne(Timetable::class); }
    public function bookings() { return $this->hasMany(Booking::class); }
}
