<?php

namespace App\Interfaces;

use Carbon\Carbon;
use App\Models\Resource;

interface SlotGenerationStrategyInterface
{
    public function generateSlots(Resource $resource, Carbon $date): array;
}
