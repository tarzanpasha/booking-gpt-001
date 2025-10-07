<?php

namespace App\Casts;

use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
use App\ValueObjects\ResourceConfig;

class ResourceConfigCast implements CastsAttributes
{
    public function get($model, string $key, $value, array $attributes)
    {
        return new ResourceConfig(json_decode($value ?? '{}', true));
    }

    public function set($model, string $key, $value, array $attributes)
    {
        if ($value instanceof ResourceConfig) {
            return [$key => json_encode($value->toArray())];
        }
        return [$key => json_encode($value)];
    }
}
