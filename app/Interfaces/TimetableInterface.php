<?php

namespace App\Interfaces;

use Carbon\Carbon;

interface TimetableInterface
{
    public function getWorkingHoursForDate(Carbon $date): ?array;
    public function getBreaksForDate(Carbon $date): array;
}
