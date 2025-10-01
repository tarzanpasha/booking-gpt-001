<?php

namespace App\Timetables;

use App\Interfaces\TimetableInterface;
use App\Models\Timetable;
use DateTimeImmutable;
use DateInterval;

class StaticTimetable implements TimetableInterface
{
    protected Timetable $model;
    protected array $payload;

    public function __construct(Timetable $model) {
        $this->model = $model;
        $this->payload = $model->payload ?? [];
    }

    public function getWorkingIntervalsForDate(\DateTimeInterface $date): array {
        $dayName = strtolower($date->format('l'));
        $schedule = $this->payload['schedule'] ?? [];
        $default = $schedule['default'] ?? null;
        $exceptions = $schedule['exceptions'] ?? [];
        $holidays = $schedule['holidays'] ?? [];

        $mmdd = $date->format('m-d');
        if (in_array($mmdd, $holidays, true)) {
            return [];
        }

        $cfg = $default;
        if (isset($exceptions[$dayName])) $cfg = $exceptions[$dayName];
        if (!$cfg || !isset($cfg['working_hours']) || $cfg['working_hours']['start'] === null) {
            return [];
        }

        $start = DateTimeImmutable::createFromFormat('Y-m-d H:i', $date->format('Y-m-d') . ' ' . $cfg['working_hours']['start']);
        $end = DateTimeImmutable::createFromFormat('Y-m-d H:i', $date->format('Y-m-d') . ' ' . $cfg['working_hours']['end']);
        $breaks = $cfg['breaks'] ?? [];

        $intervals = [];
        $cursor = $start;
        if (empty($breaks)) {
            $intervals[] = ['start' => $start, 'end' => $end];
            return $intervals;
        }
        foreach ($breaks as $b) {
            if (!isset($b['start']) || !isset($b['end'])) continue;
            $bStart = DateTimeImmutable::createFromFormat('Y-m-d H:i', $date->format('Y-m-d') . ' ' . $b['start']);
            $bEnd = DateTimeImmutable::createFromFormat('Y-m-d H:i', $date->format('Y-m-d') . ' ' . $b['end']);
            if ($cursor < $bStart) {
                $intervals[] = ['start'=>$cursor, 'end'=>$bStart];
            }
            $cursor = $bEnd > $cursor ? $bEnd : $cursor;
        }
        if ($cursor < $end) $intervals[] = ['start'=>$cursor,'end'=>$end];
        return $intervals;
    }
}
