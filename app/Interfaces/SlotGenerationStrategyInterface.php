<?php

namespace App\Interfaces;

use App\Models\Resource;

interface SlotGenerationStrategyInterface
{
    public function getNextSlots(TimetableInterface $timetable, Resource $resource, \DateTimeInterface $from, int $count, bool $onlyToday = true): array;
}
