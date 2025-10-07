<?php

namespace App\Interfaces;

use Carbon\Carbon;
use Illuminate\Support\Collection;

interface TimetableInterface
{
    public function getWorkingHoursForDate(Carbon $date): ?array;

    public function getBreaksForDate(Carbon $date): Collection;

    public function getNextAvailableSlots(Carbon $from, int $count = 10, bool $onlyToday = true): array;
}
