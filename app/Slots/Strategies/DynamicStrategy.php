<?php

namespace App\Slots\Strategies;

use App\Interfaces\SlotGenerationStrategyInterface;
use App\Models\Resource;
use Carbon\Carbon;

class DynamicStrategy implements SlotGenerationStrategyInterface
{
    public function generateSlots(Resource $resource, Carbon $date): array
    {
        $slots = [];
        $config = $resource->resource_config;
        $duration = $config['slot_duration_minutes'] ?? 60;

        $timetable = $resource->timetable;
        if (!$timetable) return [];

        $tt = $timetable->type === 'static'
            ? new \App\Timetables\StaticTimetable($timetable->payload)
            : new \App\Timetables\DynamicTimetable($timetable);

        $hours = $tt->getWorkingHoursForDate($date);
        if (!$hours) return [];

        $start = Carbon::parse($date->toDateString() . ' ' . $hours['start']);
        $end = Carbon::parse($date->toDateString() . ' ' . $hours['end']);

        $breaks = $tt->getBreaksForDate($date);

        while ($start->copy()->addMinutes($duration) <= $end) {
            $slotEnd = $start->copy()->addMinutes($duration);
            $conflict = false;
            foreach ($breaks as $b) {
                $bStart = Carbon::parse($date->toDateString() . ' ' . $b['start']);
                $bEnd = Carbon::parse($date->toDateString() . ' ' . $b['end']);
                if ($start < $bEnd && $slotEnd > $bStart) {
                    $conflict = true;
                    break;
                }
            }
            if (!$conflict) {
                $slots[] = ['start' => $start->copy(), 'end' => $slotEnd];
            }
            $start->addMinutes($duration);
        }

        return $slots;
    }
}
