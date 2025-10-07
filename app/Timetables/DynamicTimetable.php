<?php

namespace App\Timetables;

use App\Interfaces\TimetableInterface;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class DynamicTimetable implements TimetableInterface
{
    protected array $dates;

    public function __construct(array $dates)
    {
        $this->dates = $dates;
    }

    public function getWorkingHoursForDate(Carbon $date): ?array
    {
        $key = $date->format('Y-m-d');
        return $this->dates[$key]['working_hours'] ?? null;
    }

    public function getBreaksForDate(Carbon $date): Collection
    {
        $key = $date->format('Y-m-d');
        return collect($this->dates[$key]['breaks'] ?? []);
    }

    public function getNextAvailableSlots(Carbon $from, int $count = 10, bool $onlyToday = true): array
    {
        $date = $from->copy();
        $slots = [];

        while (count($slots) < $count) {
            $hours = $this->getWorkingHoursForDate($date);
            if (!$hours) {
                if ($onlyToday) break;
                $date->addDay();
                continue;
            }

            $start = Carbon::parse($hours['start'], $date->timezone)->setDateFrom($date);
            $end = Carbon::parse($hours['end'], $date->timezone)->setDateFrom($date);
            $duration = 60;

            while ($start->lt($end) && count($slots) < $count) {
                $slotEnd = $start->copy()->addMinutes($duration);
                if ($slotEnd->gt($end)) break;
                $slots[] = ['start' => $start->toDateTimeString(), 'end' => $slotEnd->toDateTimeString()];
                $start->addMinutes($duration);
            }

            if ($onlyToday) break;
            $date->addDay();
        }

        return $slots;
    }
}
