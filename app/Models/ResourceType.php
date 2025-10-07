<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ResourceType extends Model
{
    protected $fillable = [
        'company_id',
        'type',
        'name',
        'description',
        'options',
        'resource_config'
    ];

    protected $casts = [
        'options' => 'array',
        'resource_config' => \App\Casts\ResourceConfigCast::class,
    ];

    public function resources()
    {
        return $this->hasMany(Resource::class);
    }
}
