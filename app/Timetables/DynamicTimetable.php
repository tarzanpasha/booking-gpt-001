<?php

namespace App\Timetables;

use App\Interfaces\TimetableInterface;
use App\Models\Timetable;
use DateTimeImmutable;

class DynamicTimetable implements TimetableInterface
{
    protected Timetable $model;

    public function __construct(Timetable $model) {
        $this->model = $model;
    }

    public function getWorkingIntervalsForDate(\DateTimeInterface $date): array {
        $dateStr = $date->format('Y-m-d');
        $td = $this->model->dates()->where('date', $dateStr)->first();
        if (!$td) return [];

        if ($td->start === null || $td->end === null) return [];
        $start = DateTimeImmutable::createFromFormat('Y-m-d H:i', $dateStr . ' ' . substr($td->start,0,5));
        $end = DateTimeImmutable::createFromFormat('Y-m-d H:i', $dateStr . ' ' . substr($td->end,0,5));
        $breaks = $td->breaks ?? [];
        $intervals = [];
        $cursor = $start;
        foreach ($breaks as $b) {
            if (!isset($b['start']) || !isset($b['end'])) continue;
            $bStart = DateTimeImmutable::createFromFormat('Y-m-d H:i', $dateStr.' '.$b['start']);
            $bEnd = DateTimeImmutable::createFromFormat('Y-m-d H:i', $dateStr.' '.$b['end']);
            if ($cursor < $bStart) $intervals[] = ['start'=>$cursor,'end'=>$bStart];
            $cursor = $bEnd > $cursor ? $bEnd : $cursor;
        }
        if ($cursor < $end) $intervals[] = ['start'=>$cursor,'end'=>$end];
        return $intervals;
    }
}
