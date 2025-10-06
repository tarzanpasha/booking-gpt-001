<?php

namespace App\ValueObjects;

class ResourceConfig
{
    public ?bool $require_confirmation;
    public ?int $slot_duration_minutes;
    public ?string $slot_strategy;
    public ?int $max_participants;
    public ?int $min_advance_time;
    public ?int $cancel_before_minutes;
    public ?int $reschedule_before_minutes;
    public ?int $reminder_before_minutes;

    public function __construct(array $config = [])
    {
        $this->require_confirmation = $config['require_confirmation'] ?? null;
        $this->slot_duration_minutes = $config['slot_duration_minutes'] ?? null;
        $this->slot_strategy = $config['slot_strategy'] ?? null;
        $this->max_participants = $config['max_participants'] ?? null;
        $this->min_advance_time = $config['min_advance_time'] ?? null;
        $this->cancel_before_minutes = $config['cancel_before_minutes'] ?? null;
        $this->reschedule_before_minutes = $config['reschedule_before_minutes'] ?? null;
        $this->reminder_before_minutes = $config['reminder_before_minutes'] ?? null;
    }

    public function toArray(): array
    {
        return [
            'require_confirmation' => $this->require_confirmation,
            'slot_duration_minutes' => $this->slot_duration_minutes,
            'slot_strategy' => $this->slot_strategy,
            'max_participants' => $this->max_participants,
            'min_advance_time' => $this->min_advance_time,
            'cancel_before_minutes' => $this->cancel_before_minutes,
            'reschedule_before_minutes' => $this->reschedule_before_minutes,
            'reminder_before_minutes' => $this->reminder_before_minutes,
        ];
    }
}
