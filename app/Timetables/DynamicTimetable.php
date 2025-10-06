<?php

namespace App\Timetables;

use App\Interfaces\TimetableInterface;
use App\Models\Timetable;
use Carbon\Carbon;

class DynamicTimetable implements TimetableInterface
{
    protected Timetable $timetable;

    public function __construct(Timetable $timetable)
    {
        $this->timetable = $timetable;
    }

    public function getWorkingHoursForDate(Carbon $date): ?array
    {
        $day = $this->timetable->dates()->where('date', $date->toDateString())->first();
        if (!$day) return null;
        return ['start' => $day->start, 'end' => $day->end];
    }

    public function getBreaksForDate(Carbon $date): array
    {
        $day = $this->timetable->dates()->where('date', $date->toDateString())->first();
        return $day ? $day->breaks : [];
    }
}
