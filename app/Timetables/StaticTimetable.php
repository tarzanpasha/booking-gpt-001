<?php

namespace App\Timetables;

use App\Interfaces\TimetableInterface;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class StaticTimetable implements TimetableInterface
{
    protected array $config;

    public function __construct(array $config)
    {
        $this->config = $config;
    }

    public function getWorkingHoursForDate(Carbon $date): ?array
    {
        $weekday = strtolower($date->format('l'));
        $exceptions = $this->config['exceptions'][$weekday] ?? null;
        $default = $this->config['schedule']['default']['working_hours'] ?? null;

        if (in_array($date->format('m-d'), $this->config['holidays'] ?? [])) {
            return null;
        }

        if ($exceptions && isset($exceptions['working_hours'])) {
            return $exceptions['working_hours'];
        }

        return $default;
    }

    public function getBreaksForDate(Carbon $date): Collection
    {
        $weekday = strtolower($date->format('l'));
        $exceptions = $this->config['exceptions'][$weekday]['breaks'] ?? [];
        $default = $this->config['schedule']['default']['breaks'] ?? [];
        return collect($exceptions ?: $default);
    }

    public function getNextAvailableSlots(Carbon $from, int $count = 10, bool $onlyToday = true): array
    {
        $date = $from->copy();
        $slots = [];
        $collected = 0;

        while ($collected < $count) {
            $hours = $this->getWorkingHoursForDate($date);
            if (!$hours) {
                if ($onlyToday) break;
                $date->addDay();
                continue;
            }

            $start = Carbon::parse($hours['start'], $date->timezone)->setDateFrom($date);
            $end = Carbon::parse($hours['end'], $date->timezone)->setDateFrom($date);

            $slotLength = 60;
            while ($start->lt($end) && $collected < $count) {
                $slotEnd = $start->copy()->addMinutes($slotLength);
                if ($slotEnd->gt($end)) break;
                $slots[] = ['start' => $start->toDateTimeString(), 'end' => $slotEnd->toDateTimeString()];
                $start->addMinutes($slotLength);
                $collected++;
            }

            if ($onlyToday) break;
            $date->addDay();
        }

        return $slots;
    }
}
