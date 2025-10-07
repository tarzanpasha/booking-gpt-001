<?php

namespace App\Slots\Strategies;

use App\Interfaces\SlotGenerationStrategyInterface;
use App\Models\Resource;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class DynamicStrategy implements SlotGenerationStrategyInterface
{
    public function generateSlots(Resource $resource, Carbon $date): Collection
    {
        $timetable = $resource->timetable;
        $hours = $timetable->getWorkingHoursForDate($date);

        if (!$hours) return collect();

        $start = Carbon::parse($hours['start'], $date->timezone)->setDateFrom($date);
        $end = Carbon::parse($hours['end'], $date->timezone)->setDateFrom($date);

        $duration = $resource->resource_config->slot_duration_minutes ?? 60;
        $slots = collect();

        while ($start->lt($end)) {
            $slotEnd = $start->copy()->addMinutes($duration);
            if ($slotEnd->gt($end)) break;
            $slots->push(['start' => $start->toDateTimeString(), 'end' => $slotEnd->toDateTimeString()]);
            $start->addMinutes($duration);
        }

        return $slots;
    }
}
