<?php

namespace App\Slots\Strategies;

use App\Interfaces\SlotGenerationStrategyInterface;
use App\Interfaces\TimetableInterface;
use App\Models\Resource;
use App\Models\Booking;
use DateTimeImmutable;
use DateInterval;

class FixedStrategy implements SlotGenerationStrategyInterface
{
    public function getNextSlots(TimetableInterface $timetable, Resource $resource, \DateTimeInterface $from, int $count, bool $onlyToday = true): array {
        $slots = [];
        $slotMinutes = $resource->resource_config->slot_duration_minutes;
        $date = $from;
        $daysChecked = 0;
        while (count($slots) < $count && $daysChecked < 365) {
            $intervals = $timetable->getWorkingIntervalsForDate($date);
            foreach ($intervals as $int) {
                $cursor = DateTimeImmutable::createFromFormat('Y-m-d H:i:s', $int['start']->format('Y-m-d H:i:s'));
                while ($cursor < $int['end']) {
                    $slotEnd = $cursor->add(new DateInterval("PT{$slotMinutes}M"));
                    if ($slotEnd > $int['end']) break;
                    if ($slotEnd <= $from) {
                        $cursor = $slotEnd;
                        continue;
                    }
                    $exists = Booking::where('resource_id', $resource->id)
                        ->where('start','<',$slotEnd->format('Y-m-d H:i:s'))
                        ->where('end','>',$cursor->format('Y-m-d H:i:s'))
                        ->whereIn('status',['confirmed','pending_confirmation','awaiting_payment','created'])
                        ->exists();
                    if (!$exists) {
                        $slots[] = ['start'=>$cursor,'end'=>$slotEnd];
                        if (count($slots) >= $count) return $slots;
                    }
                    $cursor = $slotEnd;
                }
            }
            if ($onlyToday) break;
            $date = $date->add(new DateInterval('P1D'));
            $daysChecked++;
        }
        return $slots;
    }
}
