<?php

namespace App\ValueObjects;

use JsonSerializable;

final class ResourceConfig implements JsonSerializable
{
    public bool $require_confirmation = false;
    public ?int $remind_before_minutes = null;
    public ?int $cancel_before_minutes = null;
    public ?int $reschedule_before_minutes = null;
    public int $min_advance_time = 0;
    public int $slot_duration_minutes = 60;
    public ?int $max_participants = null;
    public string $slot_strategy = 'fixed';
    public array $handlers = [];

    public static function fromArray(array $data = []): self {
        $c = new self();
        foreach ($data as $k => $v) {
            if (property_exists($c, $k)) $c->$k = $v;
        }
        return $c;
    }

    public function jsonSerialize(): array {
        return [
            'require_confirmation' => $this->require_confirmation,
            'remind_before_minutes' => $this->remind_before_minutes,
            'cancel_before_minutes' => $this->cancel_before_minutes,
            'reschedule_before_minutes' => $this->reschedule_before_minutes,
            'min_advance_time' => $this->min_advance_time,
            'slot_duration_minutes' => $this->slot_duration_minutes,
            'max_participants' => $this->max_participants,
            'slot_strategy' => $this->slot_strategy,
            'handlers' => $this->handlers
        ];
    }
}
