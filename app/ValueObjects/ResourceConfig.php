<?php

namespace App\ValueObjects;

class ResourceConfig
{
    public bool $require_confirmation;
    public ?int $slot_duration_minutes;
    public ?string $slot_strategy;
    public ?int $max_participants;
    public ?int $min_advance_time;
    public ?int $cancel_before_minutes;
    public ?int $reschedule_before_minutes;
    public ?int $reminder_before_minutes;

    public function __construct(array $data = [])
    {
        $this->require_confirmation = $data['require_confirmation'] ?? false;
        $this->slot_duration_minutes = $data['slot_duration_minutes'] ?? 60;
        $this->slot_strategy = $data['slot_strategy'] ?? 'fixed';
        $this->max_participants = $data['max_participants'] ?? null;
        $this->min_advance_time = $data['min_advance_time'] ?? 0;
        $this->cancel_before_minutes = $data['cancel_before_minutes'] ?? null;
        $this->reschedule_before_minutes = $data['reschedule_before_minutes'] ?? null;
        $this->reminder_before_minutes = $data['reminder_before_minutes'] ?? null;
    }

    public function toArray(): array
    {
        return get_object_vars($this);
    }
}
