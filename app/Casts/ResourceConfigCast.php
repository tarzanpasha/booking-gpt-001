<?php

namespace App\Casts;

use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
use App\ValueObjects\ResourceConfig;

class ResourceConfigCast implements CastsAttributes
{
    public function get($model, string $key, $value, array $attributes) {
        $arr = $value ? json_decode($value, true) : [];
        return ResourceConfig::fromArray($arr);
    }

    public function set($model, string $key, $value, array $attributes) {
        if ($value instanceof ResourceConfig) {
            return json_encode($value->jsonSerialize());
        }
        if (is_array($value)) {
            return json_encode($value);
        }
        return $value;
    }
}
