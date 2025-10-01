<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Casts\ResourceConfigCast;

class ResourceType extends Model
{
    protected $table = 'resource_types';
    protected $fillable = ['company_id','type','name','description','options','resource_config'];
    protected $casts = [
        'options' => 'array',
        'resource_config' => ResourceConfigCast::class,
    ];

    public function resources() { return $this->hasMany(Resource::class); }
}
