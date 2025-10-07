<?php

namespace App\Interfaces;

use Carbon\Carbon;
use App\Models\Resource;
use Illuminate\Support\Collection;

interface SlotGenerationStrategyInterface
{
    public function generateSlots(Resource $resource, Carbon $date): Collection;
}
