<?php

namespace App\Slots;

use App\Interfaces\SlotGenerationStrategyInterface;
use App\Models\Resource;
use App\Interfaces\TimetableInterface;
use DateTimeInterface;

class SlotGenerator {
    public function __construct(protected SlotGenerationStrategyInterface $strategy) {}
    public function getNextAvailableSlots(TimetableInterface $timetable, Resource $resource, DateTimeInterface $from, int $count = 5, bool $onlyToday = true): array {
        return $this->strategy->getNextSlots($timetable, $resource, $from, $count, $onlyToday);
    }
}
