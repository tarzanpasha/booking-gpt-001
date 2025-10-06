<?php

namespace App\Timetables;

use App\Interfaces\TimetableInterface;
use Carbon\Carbon;

class StaticTimetable implements TimetableInterface
{
    protected array $schedule;

    public function __construct(array $schedule)
    {
        $this->schedule = $schedule;
    }

    public function getWorkingHoursForDate(Carbon $date): ?array
    {
        $day = strtolower($date->format('l'));

        if (in_array($date->format('m-d'), $this->schedule['holidays'] ?? [])) {
            return null;
        }

        if (isset($this->schedule['exceptions'][$day])) {
            return $this->schedule['exceptions'][$day]['working_hours'] ?? null;
        }

        return $this->schedule['default']['working_hours'] ?? null;
    }

    public function getBreaksForDate(Carbon $date): array
    {
        $day = strtolower($date->format('l'));
        if (isset($this->schedule['exceptions'][$day])) {
            return $this->schedule['exceptions'][$day]['breaks'] ?? [];
        }
        return $this->schedule['default']['breaks'] ?? [];
    }
}
