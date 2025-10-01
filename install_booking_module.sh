#!/usr/bin/env bash
set -e

# Скрипт добавляет модуль бронирования в монолит Laravel 10 (в папку app/).
# Запуск: bash install_booking_module.sh
# Требует: bash, php, composer (для composer dump-autoload), git optional.

ROOT="$(pwd)"
echo "Installing Booking module into $ROOT ..."

mk() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    echo " Created dir $1"
  fi
}

writef() {
  DIR="$(dirname "$1")"
  mk "$DIR"
  cat > "$1" <<'PHP'
<?php
PHP
}

# --- create directories
mk app/Models
mk app/Services
mk app/Events
mk app/Console/Commands
mk app/ValueObjects
mk app/Casts
mk app/Interfaces
mk app/Timetables
mk app/Slots/Strategies
mk app/Http/Controllers
mk app/Providers
mk database/migrations
mk routes
mk tests/Feature

# --- write files -----------------------------------------------------------
# ResourceType model
cat > app/Models/ResourceType.php <<'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Casts\ResourceConfigCast;

class ResourceType extends Model
{
    protected $table = 'resource_types';
    protected $fillable = ['company_id','type','name','description','options','resource_config'];
    protected $casts = [
        'options' => 'array',
        'resource_config' => ResourceConfigCast::class,
    ];

    public function resources() { return $this->hasMany(Resource::class); }
}
PHP

# Resource model
cat > app/Models/Resource.php <<'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Casts\ResourceConfigCast;

class Resource extends Model
{
    protected $table = 'resources';
    protected $fillable = ['company_id','resource_type_id','options','payload','resource_config'];
    protected $casts = [
        'options'=>'array',
        'payload'=>'array',
        'resource_config' => ResourceConfigCast::class,
    ];

    public function type() { return $this->belongsTo(ResourceType::class,'resource_type_id'); }
    public function timetable() { return $this->hasOne(Timetable::class); }
    public function bookings() { return $this->hasMany(Booking::class); }
}
PHP

# Timetable model
cat > app/Models/Timetable.php <<'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Timetable extends Model
{
    protected $table = 'timetables';
    protected $fillable = ['company_id','resource_id','name','type','payload'];
    protected $casts = ['payload'=>'array'];

    public function dates() { return $this->hasMany(TimetableDate::class); }
    public function resource() { return $this->belongsTo(Resource::class,'resource_id'); }
}
PHP

# TimetableDate model
cat > app/Models/TimetableDate.php <<'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class TimetableDate extends Model
{
    protected $table = 'timetable_dates';
    protected $fillable = ['timetable_id','date','start','end','breaks'];
    protected $casts = ['breaks'=>'array', 'date'=>'date:Y-m-d'];

    public function timetable() { return $this->belongsTo(Timetable::class); }
}
PHP

# Booking model
cat > app/Models/Booking.php <<'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    protected $table = 'bookings';
    protected $fillable = [
        'company_id','resource_id','timetable_id','is_group_booking','start','end','status','reason','meta','participants_count'
    ];
    protected $casts = [
        'meta' => 'array',
        'is_group_booking' => 'boolean',
        'start' => 'datetime',
        'end' => 'datetime',
    ];

    public function participants() {
        return $this->hasMany(Bookingable::class, 'booking_id');
    }
    public function resource() { return $this->belongsTo(Resource::class,'resource_id'); }
}
PHP

# Bookingable model
cat > app/Models/Bookingable.php <<'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Bookingable extends Model
{
    protected $table = 'bookingables';
    protected $fillable = ['booking_id','bookingable_type','bookingable_id'];
    public function booking() { return $this->belongsTo(Booking::class, 'booking_id'); }
    public function bookingable() { return $this->morphTo(); }
}
PHP

# ValueObject ResourceConfig
cat > app/ValueObjects/ResourceConfig.php <<'PHP'
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
PHP

# Cast ResourceConfigCast
cat > app/Casts/ResourceConfigCast.php <<'PHP'
<?php

namespace App\Casts;

use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
use App\ValueObjects\ResourceConfig;

class ResourceConfigCast implements CastsAttributes
{
    public function get($model, string $key, $value, array $attributes) {
        $arr = $value ? json_decode($value, true) : [];
        return ResourceConfig::fromArray($arr);
    }

    public function set($model, string $key, $value, array $attributes) {
        if ($value instanceof ResourceConfig) {
            return json_encode($value->jsonSerialize());
        }
        if (is_array($value)) {
            return json_encode($value);
        }
        return $value;
    }
}
PHP

# Interfaces
cat > app/Interfaces/TimetableInterface.php <<'PHP'
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
PHP

cat > app/Interfaces/SlotGenerationStrategyInterface.php <<'PHP'
<?php

namespace App\Interfaces;

use App\Models\Resource;

interface SlotGenerationStrategyInterface
{
    public function getNextSlots(TimetableInterface $timetable, Resource $resource, \DateTimeInterface $from, int $count, bool $onlyToday = true): array;
}
PHP

# Timetables
cat > app/Timetables/StaticTimetable.php <<'PHP'
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
PHP

cat > app/Timetables/DynamicTimetable.php <<'PHP'
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
PHP

# Slot generator and strategies
cat > app/Slots/SlotGenerator.php <<'PHP'
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
PHP

cat > app/Slots/Strategies/FixedStrategy.php <<'PHP'
<?php

namespace App\Slots\Strategies;

use App\Interfaces\SlotGenerationStrategyInterface;
use App\Interfaces\TimetableInterface;
use App\Models\Resource;
use App\Models\Booking;
use DateTimeImmutable;
use DateInterval;

class FixedStrategy implements SlotGenerationStrategyInterface
{
    public function getNextSlots(TimetableInterface $timetable, Resource $resource, \DateTimeInterface $from, int $count, bool $onlyToday = true): array {
        $slots = [];
        $slotMinutes = $resource->resource_config->slot_duration_minutes;
        $date = $from;
        $daysChecked = 0;
        while (count($slots) < $count && $daysChecked < 365) {
            $intervals = $timetable->getWorkingIntervalsForDate($date);
            foreach ($intervals as $int) {
                $cursor = DateTimeImmutable::createFromFormat('Y-m-d H:i:s', $int['start']->format('Y-m-d H:i:s'));
                while ($cursor < $int['end']) {
                    $slotEnd = $cursor->add(new DateInterval("PT{$slotMinutes}M"));
                    if ($slotEnd > $int['end']) break;
                    if ($slotEnd <= $from) {
                        $cursor = $slotEnd;
                        continue;
                    }
                    $exists = Booking::where('resource_id', $resource->id)
                        ->where('start','<',$slotEnd->format('Y-m-d H:i:s'))
                        ->where('end','>',$cursor->format('Y-m-d H:i:s'))
                        ->whereIn('status',['confirmed','pending_confirmation','awaiting_payment','created'])
                        ->exists();
                    if (!$exists) {
                        $slots[] = ['start'=>$cursor,'end'=>$slotEnd];
                        if (count($slots) >= $count) return $slots;
                    }
                    $cursor = $slotEnd;
                }
            }
            if ($onlyToday) break;
            $date = $date->add(new DateInterval('P1D'));
            $daysChecked++;
        }
        return $slots;
    }
}
PHP

cat > app/Slots/Strategies/DynamicStrategy.php <<'PHP'
<?php

namespace App\Slots\Strategies;

use App\Interfaces\SlotGenerationStrategyInterface;
use App\Interfaces\TimetableInterface;
use App\Models\Resource;
use App\Models\Booking;
use DateTimeImmutable;
use DateInterval;

class DynamicStrategy implements SlotGenerationStrategyInterface
{
    public function getNextSlots(TimetableInterface $timetable, Resource $resource, \DateTimeInterface $from, int $count, bool $onlyToday = true): array {
        $slots = [];
        $slotMinutes = $resource->resource_config->slot_duration_minutes;
        $date = $from;
        $daysChecked = 0;
        while (count($slots) < $count && $daysChecked < 365) {
            $intervals = $timetable->getWorkingIntervalsForDate($date);
            foreach ($intervals as $int) {
                $dayStart = $int['start']->format('Y-m-d H:i:s');
                $dayEnd = $int['end']->format('Y-m-d H:i:s');
                $bookings = Booking::where('resource_id', $resource->id)
                    ->where('start','<',$dayEnd)
                    ->where('end','>',$dayStart)
                    ->whereIn('status',['confirmed','pending_confirmation','awaiting_payment','created'])
                    ->orderBy('start')
                    ->get();

                $cursor = $int['start'];
                if ($cursor < $from) $cursor = DateTimeImmutable::createFromFormat('Y-m-d H:i:s', $from->format('Y-m-d H:i:s'));

                foreach ($bookings as $b) {
                    $bStart = new DateTimeImmutable($b->start);
                    $bEnd = new DateTimeImmutable($b->end);

                    while ($cursor->add(new DateInterval("PT0S")) < $bStart) {
                        $slotEnd = $cursor->add(new DateInterval("PT{$slotMinutes}M"));
                        if ($slotEnd > $bStart || $slotEnd > $int['end']) break;
                        $slots[] = ['start'=>$cursor,'end'=>$slotEnd];
                        if (count($slots) >= $count) return $slots;
                        $cursor = $slotEnd;
                    }
                    if ($bEnd > $cursor) $cursor = $bEnd;
                    if ($cursor >= $int['end']) break;
                }

                while ($cursor->add(new DateInterval("PT0S")) < $int['end']) {
                    $slotEnd = $cursor->add(new DateInterval("PT{$slotMinutes}M"));
                    if ($slotEnd > $int['end']) break;
                    if ($slotEnd <= $from) { $cursor = $slotEnd; continue; }
                    $exists = Booking::where('resource_id', $resource->id)
                        ->where('start','<',$slotEnd->format('Y-m-d H:i:s'))
                        ->where('end','>',$cursor->format('Y-m-d H:i:s'))
                        ->whereIn('status',['confirmed','pending_confirmation','awaiting_payment','created'])
                        ->exists();
                    if (!$exists) {
                        $slots[] = ['start'=>$cursor,'end'=>$slotEnd];
                        if (count($slots) >= $count) return $slots;
                    }
                    $cursor = $slotEnd;
                }
            }
            if ($onlyToday) break;
            $date = $date->add(new DateInterval('P1D'));
            $daysChecked++;
        }
        return $slots;
    }
}
PHP

# BookingService
cat > app/Services/BookingService.php <<'PHP'
<?php

namespace App\Services;

use App\Models\Resource;
use App\Models\Booking;
use App\Models\Bookingable;
use Illuminate\Contracts\Cache\Repository as CacheRepository;
use Illuminate\Database\ConnectionInterface;
use Illuminate\Support\Str;
use App\Events\{
    BookingCreated, BookingPendingConfirmation, BookingConfirmed,
    BookingRejected, BookingCancelled, BookingRescheduled, BookingReminder
};
use DateTime;
use DateInterval;
use Illuminate\Support\Facades\Log;
use Throwable;

class BookingService
{
    public function __construct(
        protected ConnectionInterface $db,
        protected CacheRepository $cache
    ) {}

    public function getBookingsForResourceInRange(Resource $resource, DateTime $from, DateTime $to)
    {
        return Booking::where('resource_id', $resource->id)
            ->where('start','<',$to->format('Y-m-d H:i:s'))
            ->where('end','>',$from->format('Y-m-d H:i:s'))
            ->get();
    }

    public function isRangeAvailable(Resource $resource, DateTime $from, DateTime $to, int $additionalParticipants = 1): bool {
        $query = Booking::where('resource_id', $resource->id)
            ->where('start','<',$to->format('Y-m-d H:i:s'))
            ->where('end','>',$from->format('Y-m-d H:i:s'))
            ->whereIn('status',['confirmed','pending_confirmation','awaiting_payment','created']);

        if (!$resource->resource_config->max_participants) {
            return !$query->exists();
        }
        $total = $query->sum('participants_count');
        $max = $resource->resource_config->max_participants;
        return ($total + $additionalParticipants) <= $max;
    }

    public function createBooking(Resource $resource, DateTime $start, DateTime $end, $participant, int $participantsCount = 1, array $meta = []): Booking {
        $lockKey = "booking_lock:resource:{$resource->id}";
        $lock = $this->cache->lock($lockKey, 8);

        if (!$lock->get()) {
            throw new \RuntimeException('Resource locked, try again');
        }

        try {
            return $this->db->transaction(function() use($resource,$start,$end,$participant,$participantsCount,$meta,$lock) {
                $minAdv = $resource->resource_config->min_advance_time ?? 0;
                $now = new DateTime();
                $minAllowed = (clone $now)->add(new DateInterval("PT{$minAdv}M"));
                if ($start < $minAllowed) {
                    throw new \DomainException('Booking too soon according to min_advance_time');
                }

                if (!$this->isRangeAvailable($resource, $start, $end, $participantsCount)) {
                    throw new \DomainException('Range not available');
                }

                $isGroup = (bool)$resource->resource_config->max_participants;
                $status = $resource->resource_config->require_confirmation ? 'pending_confirmation' : 'confirmed';
                $booking = Booking::create([
                    'company_id' => $resource->company_id,
                    'resource_id' => $resource->id,
                    'timetable_id' => $resource->timetable?->id,
                    'is_group_booking' => $isGroup,
                    'start' => $start->format('Y-m-d H:i:s'),
                    'end' => $end->format('Y-m-d H:i:s'),
                    'status' => $status,
                    'meta' => $meta,
                    'participants_count' => $participantsCount,
                ]);

                Bookingable::create([
                    'booking_id' => $booking->id,
                    'bookingable_type' => get_class($participant),
                    'bookingable_id' => $participant->id,
                ]);

                event(new BookingCreated($booking));
                if ($status === 'pending_confirmation') {
                    event(new BookingPendingConfirmation($booking));
                } else {
                    event(new BookingConfirmed($booking));
                }

                Log::info('booking.created', ['booking_id'=>$booking->id, 'resource'=>$resource->id]);

                return $booking;
            });
        } catch (Throwable $e) {
            Log::error('booking.create_error', ['error'=>$e->getMessage()]);
            throw $e;
        } finally {
            try { $lock->release(); } catch (\Throwable $ignore) {}
        }
    }

    public function confirmBooking(Booking $booking): Booking {
        if ($booking->status !== 'pending_confirmation') {
            throw new \DomainException('Booking is not pending confirmation');
        }
        $booking->status = 'confirmed';
        $booking->save();
        event(new BookingConfirmed($booking));
        return $booking;
    }

    public function rejectBooking(Booking $booking, ?string $reason = null): Booking {
        if (!in_array($booking->status, ['pending_confirmation','created','creating'])) {
            throw new \DomainException('Booking cannot be rejected in current status');
        }
        $booking->status = 'rejected';
        $booking->reason = $reason;
        $booking->save();
        event(new BookingRejected($booking));
        return $booking;
    }

    public function cancelBooking(Booking $booking, string $cancelledBy = 'client', ?string $reason = null): Booking {
        if (\Str::startsWith($cancelledBy,'client')) {
            $cfg = $booking->resource->resource_config;
            if (!is_null($cfg->cancel_before_minutes)) {
                $limit = (new DateTime($booking->start))->sub(new DateInterval("PT{$cfg->cancel_before_minutes}M"));
                if ((new DateTime()) > $limit) {
                    throw new \DomainException('Too late to cancel by client');
                }
            }
            $booking->status = 'cancelled_by_client';
        } else {
            $booking->status = 'cancelled_by_admin';
        }
        $booking->reason = $reason;
        $booking->save();
        event(new BookingCancelled($booking));
        return $booking;
    }

    public function rescheduleBooking(Booking $booking, DateTime $newStart, DateTime $newEnd, string $requestedBy = 'client'): Booking {
        if (in_array($booking->status, ['cancelled_by_client','cancelled_by_admin','rejected'])) {
            throw new \DomainException('Cannot reschedule cancelled or rejected booking');
        }
        if ($requestedBy === 'client') {
            $cfg = $booking->resource->resource_config;
            if (!is_null($cfg->reschedule_before_minutes)) {
                $limit = (new DateTime($booking->start))->sub(new DateInterval("PT{$cfg->reschedule_before_minutes}M"));
                if ((new DateTime()) > $limit) {
                    throw new \DomainException('Too late to reschedule by client');
                }
            }
        }

        $overlapExists = Booking::where('resource_id', $booking->resource_id)
            ->where('id','<>',$booking->id)
            ->where('start','<',$newEnd->format('Y-m-d H:i:s'))
            ->where('end','>',$newStart->format('Y-m-d H:i:s'))
            ->whereIn('status',['confirmed','pending_confirmation','awaiting_payment','created'])
            ->exists();

        if ($overlapExists) {
            throw new \DomainException('Target range not available');
        }

        $old = ['start'=>$booking->start, 'end'=>$booking->end];
        $booking->start = $newStart->format('Y-m-d H:i:s');
        $booking->end = $newEnd->format('Y-m-d H:i:s');
        $booking->save();
        event(new BookingRescheduled($booking, $old));
        return $booking;
    }
}
PHP

# Events
cat > app/Events/BookingCreated.php <<'PHP'
<?php

namespace App\Events;

use Illuminate\Queue\SerializesModels;
use App\Models\Booking;

class BookingCreated {
    use SerializesModels;
    public function __construct(public Booking $booking) {}
}
PHP

cat > app/Events/BookingPendingConfirmation.php <<'PHP'
<?php

namespace App\Events;

use Illuminate\Queue\SerializesModels;
use App\Models\Booking;

class BookingPendingConfirmation {
    use SerializesModels;
    public function __construct(public Booking $booking) {}
}
PHP

cat > app/Events/BookingConfirmed.php <<'PHP'
<?php

namespace App\Events;

use Illuminate\Queue\SerializesModels;
use App\Models\Booking;

class BookingConfirmed {
    use SerializesModels;
    public function __construct(public Booking $booking) {}
}
PHP

cat > app/Events/BookingRejected.php <<'PHP'
<?php

namespace App\Events;

use Illuminate\Queue\SerializesModels;
use App\Models\Booking;

class BookingRejected {
    use SerializesModels;
    public function __construct(public Booking $booking) {}
}
PHP

cat > app/Events/BookingCancelled.php <<'PHP'
<?php

namespace App\Events;

use Illuminate\Queue\SerializesModels;
use App\Models\Booking;

class BookingCancelled {
    use SerializesModels;
    public function __construct(public Booking $booking) {}
}
PHP

cat > app/Events/BookingRescheduled.php <<'PHP'
<?php

namespace App\Events;

use Illuminate\Queue\SerializesModels;
use App\Models\Booking;

class BookingRescheduled {
    use SerializesModels;
    public function __construct(public Booking $booking, public array $old) {}
}
PHP

cat > app/Events/BookingReminder.php <<'PHP'
<?php

namespace App\Events;

use Illuminate\Queue\SerializesModels;
use App\Models\Booking;

class BookingReminder {
    use SerializesModels;
    public function __construct(public Booking $booking) {}
}
PHP

# Console command
cat > app/Console/Commands/SendBookingRemindersCommand.php <<'PHP'
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Booking;
use App\Events\BookingReminder;
use DateTime;

class SendBookingRemindersCommand extends Command {
    protected $signature = 'booking:send-reminders {--minutes=1 : window minutes to check}';
    protected $description = 'Send booking reminders according to resource config';

    public function handle() {
        $window = (int)$this->option('minutes');
        $now = new DateTime();
        $until = (new DateTime())->add(new \DateInterval("PT{$window}M"));

        $bookings = Booking::where('status','confirmed')
            ->get();

        foreach ($bookings as $b) {
            $cfg = $b->resource->resource_config;
            if (!$cfg->remind_before_minutes) continue;
            $triggerAt = (new DateTime($b->start))->sub(new \DateInterval("PT{$cfg->remind_before_minutes}M"));
            if ($triggerAt >= $now && $triggerAt <= $until) {
                event(new BookingReminder($b));
            }
        }
        $this->info('Reminders scanned');
    }
}
PHP

# Controller
cat > app/Http/Controllers/BookingController.php <<'PHP'
<?php

namespace App\Http\Controllers;

use App\Models\Resource;
use App\Models\Booking;
use App\Services\BookingService;
use Illuminate\Http\Request;
use DateTime;

class BookingController extends Controller
{
    public function store(Request $request, Resource $resource, BookingService $service)
    {
        $data = $request->validate([
            'start' => 'required|date',
            'end'   => 'required|date|after:start',
            'participants_count' => 'nullable|integer|min:1'
        ]);

        // no auth: use a placeholder participant model if none provided (you can adjust)
        $participant = (object)['id' => 0, 'email' => 'guest@example.com'];

        $booking = $service->createBooking(
            $resource,
            new DateTime($data['start']),
            new DateTime($data['end']),
            $participant,
            $data['participants_count'] ?? 1
        );

        return response()->json($booking);
    }

    public function confirm(Booking $booking, BookingService $service)
    {
        $service->confirmBooking($booking);
        return response()->json($booking);
    }

    public function cancel(Booking $booking, Request $request, BookingService $service)
    {
        $service->cancelBooking($booking, 'client', $request->input('reason'));
        return response()->json($booking);
    }

    public function reschedule(Booking $booking, Request $request, BookingService $service)
    {
        $data = $request->validate([
            'new_start' => 'required|date',
            'new_end'   => 'required|date|after:new_start',
        ]);

        $service->rescheduleBooking(
            $booking,
            new DateTime($data['new_start']),
            new DateTime($data['new_end']),
            'client'
        );

        return response()->json($booking);
    }
}
PHP

# Provider
cat > app/Providers/BookingServiceProvider.php <<'PHP'
<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Services\BookingService;
use App\Console\Commands\SendBookingRemindersCommand;

class BookingServiceProvider extends ServiceProvider
{
    public function register()
    {
        $this->app->singleton(BookingService::class, function ($app) {
            return new BookingService($app['db'], $app['cache.store']);
        });
    }

    public function boot()
    {
        if ($this->app->runningInConsole()) {
            $this->commands([
                SendBookingRemindersCommand::class,
            ]);
        }
    }
}
PHP

# Migrations
cat > database/migrations/2025_01_01_000001_create_resource_types_table.php <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateResourceTypesTable extends Migration {
    public function up() {
        Schema::create('resource_types', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('company_id')->index();
            $table->string('type', 63);
            $table->string('name', 127);
            $table->string('description', 255)->nullable();
            $table->json('options')->nullable();
            $table->json('resource_config')->nullable();
            $table->timestamps();
            $table->unique(['company_id','type']);
        });
    }
    public function down() { Schema::dropIfExists('resource_types'); }
}
PHP

cat > database/migrations/2025_01_01_000002_create_resources_table.php <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateResourcesTable extends Migration {
    public function up() {
        Schema::create('resources', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('company_id')->index();
            $table->unsignedBigInteger('resource_type_id')->index();
            $table->json('options')->nullable();
            $table->json('payload')->nullable();
            $table->json('resource_config')->nullable();
            $table->timestamps();

            $table->foreign('resource_type_id')->references('id')->on('resource_types')->onDelete('cascade');
        });
    }
    public function down() { Schema::dropIfExists('resources'); }
}
PHP

cat > database/migrations/2025_01_01_000003_create_timetables_table.php <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTimetablesTable extends Migration {
    public function up() {
        Schema::create('timetables', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('company_id')->index();
            $table->unsignedBigInteger('resource_id')->nullable()->index();
            $table->string('name')->nullable();
            $table->enum('type', ['static','dynamic'])->default('static');
            $table->json('payload')->nullable();
            $table->timestamps();
        });
    }
    public function down() { Schema::dropIfExists('timetables'); }
}
PHP

cat > database/migrations/2025_01_01_000004_create_timetable_dates_table.php <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateTimetableDatesTable extends Migration {
    public function up() {
        Schema::create('timetable_dates', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('timetable_id')->index();
            $table->date('date');
            $table->time('start')->nullable();
            $table->time('end')->nullable();
            $table->json('breaks')->nullable();
            $table->timestamps();
            $table->unique(['timetable_id','date']);
            $table->foreign('timetable_id')->references('id')->on('timetables')->onDelete('cascade');
        });
    }
    public function down() { Schema::dropIfExists('timetable_dates'); }
}
PHP

cat > database/migrations/2025_01_01_000005_create_bookings_table.php <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateBookingsTable extends Migration {
    public function up() {
        Schema::create('bookings', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('company_id')->index();
            $table->unsignedBigInteger('resource_id')->index();
            $table->unsignedBigInteger('timetable_id')->nullable();
            $table->boolean('is_group_booking')->default(false);
            $table->dateTime('start')->index();
            $table->dateTime('end')->index();
            $table->enum('status', [
                'creating','created','pending_confirmation','awaiting_payment',
                'confirmed','cancelled_by_client','cancelled_by_admin','rejected'
            ])->default('creating');
            $table->string('reason',255)->nullable();
            $table->json('meta')->nullable();
            $table->unsignedInteger('participants_count')->default(0);
            $table->timestamps();

            $table->index(['resource_id','start','end']);
        });
    }
    public function down() { Schema::dropIfExists('bookings'); }
}
PHP

cat > database/migrations/2025_01_01_000006_create_bookingables_table.php <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateBookingablesTable extends Migration {
    public function up() {
        Schema::create('bookingables', function (Blueprint $table) {
            $table->bigIncrements('id');
            $table->unsignedBigInteger('booking_id')->index();
            $table->morphs('bookingable');
            $table->timestamps();
            $table->foreign('booking_id')->references('id')->on('bookings')->onDelete('cascade');
        });
    }
    public function down() { Schema::dropIfExists('bookingables'); }
}
PHP

# Routes
cat > routes/api.php <<'PHP'
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\BookingController;

Route::post('/resources/{resource}/bookings', [BookingController::class, 'store']);
Route::post('/bookings/{booking}/confirm', [BookingController::class, 'confirm']);
Route::post('/bookings/{booking}/cancel', [BookingController::class, 'cancel']);
Route::post('/bookings/{booking}/reschedule', [BookingController::class, 'reschedule']);
PHP

# Test skeleton
cat > tests/Feature/BookingServiceTest.php <<'PHP'
<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\Resource;
use App\Models\ResourceType;
use App\Services\BookingService;
use App\ValueObjects\ResourceConfig;
use DateTime;

class BookingServiceTest extends TestCase
{
    use RefreshDatabase;

    public function test_create_booking_requires_confirmation()
    {
        $type = ResourceType::factory()->create(['company_id'=>1,'type'=>'staff','name'=>'Staff']);
        $resource = Resource::create([
            'company_id' => 1,
            'resource_type_id' => $type->id,
            'resource_config' => ResourceConfig::fromArray([
                'require_confirmation' => true,
                'slot_duration_minutes' => 60
            ])
        ]);

        $participant = (object)['id' => 0];

        $service = app(BookingService::class);

        $start = (new DateTime())->add(new \DateInterval('P1D'));
        $end   = (clone $start)->add(new \DateInterval('PT1H'));

        $booking = $service->createBooking($resource, $start, $end, $participant);
        $this->assertEquals('pending_confirmation', $booking->status);
    }
}
PHP

# Final steps
echo ""
echo "Booking module files created."
echo ""
echo "NEXT STEPS:"
echo "1) Add App\\Providers\\BookingServiceProvider::class to config/app.php -> 'providers' array."
echo "2) Run: composer dump-autoload"
echo "3) Configure DB in .env (DB_CONNECTION, DB_DATABASE, DB_HOST, ...)."
echo "4) Run migrations: php artisan migrate"
echo "5) Optionally run tests: php artisan test"
echo ""
echo "If you want, I can also print the exact lines to add to config/app.php automatically."
