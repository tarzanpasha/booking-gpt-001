<?php

namespace App\Interfaces;

interface TimetableInterface
{
    /**
     * @param \DateTimeInterface $date
     * @return array each element: ['start' => DateTimeImmutable, 'end' => DateTimeImmutable]
     */
    public function getWorkingIntervalsForDate(\DateTimeInterface $date): array;
}
