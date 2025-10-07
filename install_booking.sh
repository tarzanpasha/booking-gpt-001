#!/usr/bin/env bash
set -e

echo "=== Установка Booking Module (Часть 1: структура, модели, конфигурации) ==="

mk() { mkdir -p "$1"; }

# === Создаём структуру директорий ===
mk app/Models
mk app/ValueObjects
mk app/Casts
mk app/Providers
mk app/Services
mk app/Interfaces
mk app/Events
mk app/Listeners
mk app/Http/Controllers
mk app/Timetables
mk app/Slots/Strategies
mk database/migrations
mk routes
mk app/Console/Commands

# === Модель ResourceType ===
cat > app/Models/ResourceType.php <<'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ResourceType extends Model
{
    protected $fillable = [
        'company_id',
        'type',
        'name',
        'description',
        'options',
        'resource_config'
    ];

    protected $casts = [
        'options' => 'array',
        'resource_config' => \App\Casts\ResourceConfigCast::class,
    ];

    public function resources()
    {
        return $this->hasMany(Resource::class);
    }
}
PHP

# === Модель Resource ===
cat > app/Models/Resource.php <<'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Resource extends Model
{
    protected $fillable = [
        'company_id',
        'resource_type_id',
        'options',
        'payload',
        'resource_config',
    ];

    protected $casts = [
        'options' => 'array',
        'payload' => 'array',
        'resource_config' => \App\Casts\ResourceConfigCast::class,
    ];

    public function type()
    {
        return $this->belongsTo(ResourceType::class, 'resource_type_id');
    }

    public function bookings()
    {
        return $this->hasMany(Booking::class);
    }
}
PHP

# === Модель Booking ===
cat > app/Models/Booking.php <<'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Booking extends Model
{
    protected $fillable = [
        'company_id',
        'resource_id',
        'timetable_id',
        'is_group_booking',
        'start',
        'end',
        'status',
        'reason',
    ];

    protected $casts = [
        'start' => 'datetime',
        'end' => 'datetime',
        'is_group_booking' => 'boolean',
    ];

    public function resource()
    {
        return $this->belongsTo(Resource::class);
    }
}
PHP

# === ValueObject: ResourceConfig ===
cat > app/ValueObjects/ResourceConfig.php <<'PHP'
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
PHP

# === Cast: ResourceConfigCast ===
cat > app/Casts/ResourceConfigCast.php <<'PHP'
<?php

namespace App\Casts;

use Illuminate\Contracts\Database\Eloquent\CastsAttributes;
use App\ValueObjects\ResourceConfig;

class ResourceConfigCast implements CastsAttributes
{
    public function get($model, string $key, $value, array $attributes)
    {
        return new ResourceConfig(json_decode($value ?? '{}', true));
    }

    public function set($model, string $key, $value, array $attributes)
    {
        if ($value instanceof ResourceConfig) {
            return [$key => json_encode($value->toArray())];
        }
        return [$key => json_encode($value)];
    }
}
PHP

echo "✅ Часть 1 завершена: базовые модели и конфигурации созданы."
#!/usr/bin/env bash
set -e

echo "=== Установка Booking Module (Часть 2: интерфейсы, расписания, стратегии, сервисы) ==="

mk() { mkdir -p "$1"; }

mk app/Interfaces
mk app/Timetables
mk app/Slots/Strategies
mk app/Services

# === Интерфейс TimetableInterface ===
cat > app/Interfaces/TimetableInterface.php <<'PHP'
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
PHP

# === Интерфейс SlotGenerationStrategyInterface ===
cat > app/Interfaces/SlotGenerationStrategyInterface.php <<'PHP'
<?php

namespace App\Interfaces;

use Carbon\Carbon;
use App\Models\Resource;
use Illuminate\Support\Collection;

interface SlotGenerationStrategyInterface
{
    public function generateSlots(Resource $resource, Carbon $date): Collection;
}
PHP

# === StaticTimetable ===
cat > app/Timetables/StaticTimetable.php <<'PHP'
<?php

namespace App\Timetables;

use App\Interfaces\TimetableInterface;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class StaticTimetable implements TimetableInterface
{
    protected array $config;

    public function __construct(array $config)
    {
        $this->config = $config;
    }

    public function getWorkingHoursForDate(Carbon $date): ?array
    {
        $weekday = strtolower($date->format('l'));
        $exceptions = $this->config['exceptions'][$weekday] ?? null;
        $default = $this->config['schedule']['default']['working_hours'] ?? null;

        if (in_array($date->format('m-d'), $this->config['holidays'] ?? [])) {
            return null;
        }

        if ($exceptions && isset($exceptions['working_hours'])) {
            return $exceptions['working_hours'];
        }

        return $default;
    }

    public function getBreaksForDate(Carbon $date): Collection
    {
        $weekday = strtolower($date->format('l'));
        $exceptions = $this->config['exceptions'][$weekday]['breaks'] ?? [];
        $default = $this->config['schedule']['default']['breaks'] ?? [];
        return collect($exceptions ?: $default);
    }

    public function getNextAvailableSlots(Carbon $from, int $count = 10, bool $onlyToday = true): array
    {
        $date = $from->copy();
        $slots = [];
        $collected = 0;

        while ($collected < $count) {
            $hours = $this->getWorkingHoursForDate($date);
            if (!$hours) {
                if ($onlyToday) break;
                $date->addDay();
                continue;
            }

            $start = Carbon::parse($hours['start'], $date->timezone)->setDateFrom($date);
            $end = Carbon::parse($hours['end'], $date->timezone)->setDateFrom($date);

            $slotLength = 60;
            while ($start->lt($end) && $collected < $count) {
                $slotEnd = $start->copy()->addMinutes($slotLength);
                if ($slotEnd->gt($end)) break;
                $slots[] = ['start' => $start->toDateTimeString(), 'end' => $slotEnd->toDateTimeString()];
                $start->addMinutes($slotLength);
                $collected++;
            }

            if ($onlyToday) break;
            $date->addDay();
        }

        return $slots;
    }
}
PHP

# === DynamicTimetable ===
cat > app/Timetables/DynamicTimetable.php <<'PHP'
<?php

namespace App\Timetables;

use App\Interfaces\TimetableInterface;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class DynamicTimetable implements TimetableInterface
{
    protected array $dates;

    public function __construct(array $dates)
    {
        $this->dates = $dates;
    }

    public function getWorkingHoursForDate(Carbon $date): ?array
    {
        $key = $date->format('Y-m-d');
        return $this->dates[$key]['working_hours'] ?? null;
    }

    public function getBreaksForDate(Carbon $date): Collection
    {
        $key = $date->format('Y-m-d');
        return collect($this->dates[$key]['breaks'] ?? []);
    }

    public function getNextAvailableSlots(Carbon $from, int $count = 10, bool $onlyToday = true): array
    {
        $date = $from->copy();
        $slots = [];

        while (count($slots) < $count) {
            $hours = $this->getWorkingHoursForDate($date);
            if (!$hours) {
                if ($onlyToday) break;
                $date->addDay();
                continue;
            }

            $start = Carbon::parse($hours['start'], $date->timezone)->setDateFrom($date);
            $end = Carbon::parse($hours['end'], $date->timezone)->setDateFrom($date);
            $duration = 60;

            while ($start->lt($end) && count($slots) < $count) {
                $slotEnd = $start->copy()->addMinutes($duration);
                if ($slotEnd->gt($end)) break;
                $slots[] = ['start' => $start->toDateTimeString(), 'end' => $slotEnd->toDateTimeString()];
                $start->addMinutes($duration);
            }

            if ($onlyToday) break;
            $date->addDay();
        }

        return $slots;
    }
}
PHP

# === FixedStrategy ===
cat > app/Slots/Strategies/FixedStrategy.php <<'PHP'
<?php

namespace App\Slots\Strategies;

use App\Interfaces\SlotGenerationStrategyInterface;
use App\Models\Resource;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class FixedStrategy implements SlotGenerationStrategyInterface
{
    public function generateSlots(Resource $resource, Carbon $date): Collection
    {
        $timetable = $resource->timetable;
        $hours = $timetable->getWorkingHoursForDate($date);

        if (!$hours) return collect();

        $start = Carbon::parse($hours['start'], $date->timezone)->setDateFrom($date);
        $end = Carbon::parse($hours['end'], $date->timezone)->setDateFrom($date);

        $duration = $resource->resource_config->slot_duration_minutes ?? 60;
        $slots = collect();

        while ($start->lt($end)) {
            $slotEnd = $start->copy()->addMinutes($duration);
            if ($slotEnd->gt($end)) break;
            $slots->push(['start' => $start->toDateTimeString(), 'end' => $slotEnd->toDateTimeString()]);
            $start->addMinutes($duration);
        }

        return $slots;
    }
}
PHP

# === DynamicStrategy ===
cat > app/Slots/Strategies/DynamicStrategy.php <<'PHP'
<?php

namespace App\Slots\Strategies;

use App\Interfaces\SlotGenerationStrategyInterface;
use App\Models\Resource;
use Carbon\Carbon;
use Illuminate\Support\Collection;

class DynamicStrategy implements SlotGenerationStrategyInterface
{
    public function generateSlots(Resource $resource, Carbon $date): Collection
    {
        $timetable = $resource->timetable;
        $hours = $timetable->getWorkingHoursForDate($date);

        if (!$hours) return collect();

        $start = Carbon::parse($hours['start'], $date->timezone)->setDateFrom($date);
        $end = Carbon::parse($hours['end'], $date->timezone)->setDateFrom($date);

        $duration = $resource->resource_config->slot_duration_minutes ?? 60;
        $slots = collect();

        while ($start->lt($end)) {
            $slotEnd = $start->copy()->addMinutes($duration);
            if ($slotEnd->gt($end)) break;
            $slots->push(['start' => $start->toDateTimeString(), 'end' => $slotEnd->toDateTimeString()]);
            $start->addMinutes($duration);
        }

        return $slots;
    }
}
PHP

echo "✅ Часть 2 завершена: интерфейсы, расписания и стратегии добавлены."
#!/usr/bin/env bash
set -e

echo "=== Установка Booking Module (Часть 3: контроллер, события, маршруты, провайдеры) ==="

mk() { mkdir -p "$1"; }

mk app/Http/Controllers
mk app/Providers
mk routes
mk app/Events

# === BookingController ===
cat > app/Http/Controllers/BookingController.php <<'PHP'
<?php

namespace App\Http\Controllers;

use App\Models\Resource;
use App\Models\Booking;
use App\Services\BookingService;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;
use Carbon\Carbon;
use Exception;

class BookingController extends Controller
{
    protected BookingService $service;

    public function __construct(BookingService $service)
    {
        $this->service = $service;
    }

    public function store(Request $request, $resourceId): JsonResponse
    {
        try {
            $resource = Resource::findOrFail($resourceId);
            $start = Carbon::parse($request->input('start'));
            $end = Carbon::parse($request->input('end'));

            $booking = $this->service->createBooking(
                $resource,
                $start,
                $end,
                $request->boolean('is_group_booking', false)
            );

            return response()->json($booking, 201);
        } catch (Exception $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }
    }

    public function confirm($id): JsonResponse
    {
        try {
            $booking = Booking::findOrFail($id);
            $confirmed = $this->service->confirmBooking($booking);
            return response()->json($confirmed);
        } catch (Exception $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }
    }

    public function cancel(Request $request, $id): JsonResponse
    {
        try {
            $booking = Booking::findOrFail($id);
            $cancelled = $this->service->cancelBooking(
                $booking,
                $request->input('cancelled_by', 'client'),
                $request->input('reason')
            );
            return response()->json($cancelled);
        } catch (Exception $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }
    }

    public function reschedule(Request $request, $id): JsonResponse
    {
        try {
            $booking = Booking::findOrFail($id);
            $newStart = Carbon::parse($request->input('new_start'));
            $newEnd = Carbon::parse($request->input('new_end'));

            $rescheduled = $this->service->rescheduleBooking(
                $booking,
                $newStart,
                $newEnd,
                $request->input('requested_by', 'client')
            );

            return response()->json($rescheduled);
        } catch (Exception $e) {
            return response()->json(['error' => $e->getMessage()], 422);
        }
    }
}
PHP

# === События Booking ===
for EVENT in Created PendingConfirmation Confirmed Rejected Cancelled Rescheduled Reminder; do
cat > app/Events/Booking${EVENT}.php <<PHP
<?php

namespace App\Events;

use App\Models\Booking;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class Booking${EVENT}
{
    use Dispatchable, SerializesModels;

    public Booking \$booking;

    public function __construct(Booking \$booking)
    {
        \$this->booking = \$booking;
    }
}
PHP
done

# === BookingServiceProvider ===
cat > app/Providers/BookingServiceProvider.php <<'PHP'
<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use Illuminate\Support\Facades\Route;

class BookingServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        // Здесь можно регистрировать сервисы
    }

    public function boot(): void
    {
        Route::middleware('api')
            ->prefix('api')
            ->group(base_path('routes/booking.php'));
    }
}
PHP

# === Маршруты (routes/booking.php) ===
cat > routes/booking.php <<'PHP'
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\BookingController;

Route::prefix('resources/{resourceId}/bookings')->group(function () {
    Route::post('/', [BookingController::class, 'store']);
});

Route::prefix('bookings')->group(function () {
    Route::post('{id}/confirm', [BookingController::class, 'confirm']);
    Route::post('{id}/cancel', [BookingController::class, 'cancel']);
    Route::post('{id}/reschedule', [BookingController::class, 'reschedule']);
});
PHP

echo "✅ Часть 3 завершена: контроллер, события и маршруты добавлены."
#!/usr/bin/env bash
set -e

echo "=== Установка Booking Module (Часть 4: миграции базы данных) ==="

mk() { mkdir -p "$1"; }

mk database/migrations

# === Migration: create_resource_types_table ===
cat > database/migrations/2025_01_01_000000_create_resource_types_table.php <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('resource_types', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('company_id');
            $table->string('type', 63);
            $table->string('name', 127);
            $table->string('description', 255)->nullable();
            $table->json('options')->nullable();
            $table->json('resource_config')->nullable();
            $table->timestamps();

            $table->unique(['company_id', 'type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('resource_types');
    }
};
PHP

# === Migration: create_resources_table ===
cat > database/migrations/2025_01_01_000100_create_resources_table.php <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('resources', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('company_id');
            $table->unsignedBigInteger('resource_type_id');
            $table->json('options')->nullable();
            $table->json('payload')->nullable();
            $table->json('resource_config')->nullable();
            $table->timestamps();

            $table->foreign('resource_type_id')->references('id')->on('resource_types')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('resources');
    }
};
PHP

# === Migration: create_timetables_table ===
cat > database/migrations/2025_01_01_000200_create_timetables_table.php <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('timetables', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('resource_id');
            $table->string('type')->default('static');
            $table->json('config');
            $table->timestamps();

            $table->foreign('resource_id')->references('id')->on('resources')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('timetables');
    }
};
PHP

# === Migration: create_timetable_dates_table ===
cat > database/migrations/2025_01_01_000300_create_timetable_dates_table.php <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('timetable_dates', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('timetable_id');
            $table->date('date');
            $table->time('start');
            $table->time('end');
            $table->json('breaks')->nullable();
            $table->timestamps();

            $table->foreign('timetable_id')->references('id')->on('timetables')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('timetable_dates');
    }
};
PHP

# === Migration: create_bookings_table ===
cat > database/migrations/2025_01_01_000400_create_bookings_table.php <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('company_id');
            $table->unsignedBigInteger('resource_id');
            $table->unsignedBigInteger('timetable_id')->nullable();
            $table->boolean('is_group_booking')->default(false);
            $table->dateTime('start');
            $table->dateTime('end');
            $table->enum('status', [
                'pending_confirmation',
                'confirmed',
                'cancelled_by_client',
                'cancelled_by_admin',
                'rejected',
                'rescheduled'
            ])->default('pending_confirmation');
            $table->string('reason')->nullable();
            $table->timestamps();

            $table->foreign('resource_id')->references('id')->on('resources')->cascadeOnDelete();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};
PHP

# === Migration: create_bookingables_table ===
cat > database/migrations/2025_01_01_000500_create_bookingables_table.php <<'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('bookingables', function (Blueprint $table) {
            $table->unsignedBigInteger('booking_id');
            $table->morphs('bookingable'); // создаст bookingable_id и bookingable_type
            $table->primary(['booking_id', 'bookingable_id', 'bookingable_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookingables');
    }
};
PHP

echo "✅ Часть 4 завершена: миграции для всех таблиц созданы."
#!/usr/bin/env bash
set -e

echo "=== Установка Booking Module (Часть 5: artisan-команды и тестовые данные) ==="

mk() { mkdir -p "$1"; }

mk app/Console/Commands
mk storage/app/exports

# === 1. SeedBookingDemoCommand ===
cat > app/Console/Commands/SeedBookingDemoCommand.php <<'PHP'
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\{ResourceType, Resource, Booking};
use Illuminate\Support\Facades\DB;
use Carbon\Carbon;

class SeedBookingDemoCommand extends Command
{
    protected $signature = 'booking:seed-demo {--fresh}';
    protected $description = 'Создаёт тестовые ресурсы, типы и бронирования';

    public function handle(): int
    {
        if ($this->option('fresh')) {
            DB::table('bookings')->truncate();
            DB::table('resources')->truncate();
            DB::table('resource_types')->truncate();
            $this->info('Таблицы очищены.');
        }

        $this->info('Создание типов ресурсов...');

        $type1 = ResourceType::create([
            'company_id' => 1,
            'type' => 'employee',
            'name' => 'Сотрудник',
            'description' => 'Персональные услуги сотрудников',
            'resource_config' => [
                'slot_duration_minutes' => 60,
                'slot_strategy' => 'fixed',
                'require_confirmation' => true
            ]
        ]);

        $type2 = ResourceType::create([
            'company_id' => 1,
            'type' => 'room',
            'name' => 'Комната',
            'description' => 'Помещения для аренды',
            'resource_config' => [
                'slot_duration_minutes' => 120,
                'slot_strategy' => 'dynamic',
                'require_confirmation' => false
            ]
        ]);

        $this->info('Создание ресурсов...');

        $res1 = Resource::create([
            'company_id' => 1,
            'resource_type_id' => $type1->id,
            'payload' => ['name' => 'Иван Парикмахер'],
            'resource_config' => $type1->resource_config->toArray()
        ]);

        $res2 = Resource::create([
            'company_id' => 1,
            'resource_type_id' => $type2->id,
            'payload' => ['name' => 'Комната №404'],
            'resource_config' => $type2->resource_config->toArray()
        ]);

        $this->info('Создание тестовых броней...');

        $now = Carbon::now();
        foreach (range(1, 5) as $i) {
            Booking::create([
                'company_id' => 1,
                'resource_id' => $res1->id,
                'timetable_id' => null,
                'is_group_booking' => false,
                'start' => $now->copy()->addDays($i)->setTime(10, 0),
                'end' => $now->copy()->addDays($i)->setTime(11, 0),
                'status' => 'pending_confirmation',
            ]);
        }

        foreach (range(1, 3) as $i) {
            Booking::create([
                'company_id' => 1,
                'resource_id' => $res2->id,
                'timetable_id' => null,
                'is_group_booking' => false,
                'start' => $now->copy()->addDays($i)->setTime(9, 0),
                'end' => $now->copy()->addDays($i)->setTime(12, 0),
                'status' => 'confirmed',
            ]);
        }

        $this->info('✅ Демоданные созданы.');
        return Command::SUCCESS;
    }
}
PHP

# === 2. RunBookingDemoActionsCommand ===
cat > app/Console/Commands/RunBookingDemoActionsCommand.php <<'PHP'
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Booking;
use App\Services\BookingService;
use Carbon\Carbon;

class RunBookingDemoActionsCommand extends Command
{
    protected $signature = 'booking:run-demo-actions';
    protected $description = 'Имитация сценария: создание, подтверждение, перенос, отмена брони';

    public function handle(BookingService $service): int
    {
        $this->info('🔹 Запуск демонстрации бронирования...');

        $booking = Booking::first();
        if (!$booking) {
            $this->error('Нет броней. Сначала выполните php artisan booking:seed-demo');
            return Command::FAILURE;
        }

        if ($booking->status === 'pending_confirmation') {
            $this->info('✅ Подтверждение брони...');
            $service->confirmBooking($booking);
        }

        $this->info('🔄 Перенос брони...');
        $service->rescheduleBooking(
            $booking,
            Carbon::parse($booking->start)->addDay(),
            Carbon::parse($booking->end)->addDay(),
            'admin'
        );

        $this->info('❌ Отмена брони...');
        $service->cancelBooking($booking, 'client', 'Клиент передумал');

        $this->info('🎯 Демонстрация завершена. Проверяйте storage/logs/booking.log');
        return Command::SUCCESS;
    }
}
PHP

# === 3. ShowBookingDemoCurlCommand ===
cat > app/Console/Commands/ShowBookingDemoCurlCommand.php <<'PHP'
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class ShowBookingDemoCurlCommand extends Command
{
    protected $signature = 'booking:show-demo-curl';
    protected $description = 'Показывает примеры curl-запросов для тестирования API бронирования';

    public function handle(): int
    {
        $this->info("📘 Примеры API-запросов:");

        $this->line("Создать бронь:");
        $this->line("curl -X POST http://localhost/api/resources/1/bookings -d 'start=2025-10-08 10:00&end=2025-10-08 11:00'");

        $this->line("\nПодтвердить бронь:");
        $this->line("curl -X POST http://localhost/api/bookings/1/confirm");

        $this->line("\nОтменить бронь:");
        $this->line("curl -X POST http://localhost/api/bookings/1/cancel -d 'cancelled_by=client&reason=Неудобное время'");

        $this->line("\nПеренести бронь:");
        $this->line("curl -X POST http://localhost/api/bookings/1/reschedule -d 'new_start=2025-10-09 11:00&new_end=2025-10-09 12:00'");

        return Command::SUCCESS;
    }
}
PHP

# === 4. ExportBookingDataCommand ===
cat > app/Console/Commands/ExportBookingDataCommand.php <<'PHP'
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Facades\Storage;
use App\Models\{ResourceType, Resource, Booking};

class ExportBookingDataCommand extends Command
{
    protected $signature = 'booking:export-json';
    protected $description = 'Экспортирует все ресурсы, типы, расписания и брони в JSON-файлы';

    public function handle(): int
    {
        $dir = 'exports';
        Storage::makeDirectory($dir);

        $this->info('📤 Экспорт ResourceTypes...');
        $types = ResourceType::with('resources')->get()->map(function ($t) {
            return [
                'id' => $t->id,
                'company_id' => $t->company_id,
                'company_name' => 'Demo Company',
                'type' => $t->type,
                'name' => $t->name,
                'description' => $t->description,
                'options' => $t->options,
                'resource_count' => $t->resources()->count(),
            ];
        });
        Storage::put("$dir/resource_types.json", json_encode($types, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

        $this->info('📤 Экспорт Resources...');
        $resources = Resource::with('type')->get()->map(function ($r) {
            return [
                'id' => $r->id,
                'company_id' => $r->company_id,
                'company_name' => 'Demo Company',
                'type' => $r->type->name,
                'resource_name' => $r->payload['name'] ?? 'Без имени',
                'strategy' => $r->resource_config->slot_strategy,
                'duration' => $r->resource_config->slot_duration_minutes,
            ];
        });
        Storage::put("$dir/resources.json", json_encode($resources, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

        $this->info('📤 Экспорт Bookings...');
        $bookings = Booking::with('resource.type')->get()->map(function ($b) {
            return [
                'id' => $b->id,
                'company_id' => $b->company_id,
                'company_name' => 'Demo Company',
                'resource' => $b->resource->payload['name'] ?? 'Неизвестно',
                'resource_type' => $b->resource->type->name ?? 'Неизвестно',
                'start' => $b->start->toDateTimeString(),
                'end' => $b->end->toDateTimeString(),
                'status' => $b->status,
                'is_group_booking' => $b->is_group_booking,
                'reason' => $b->reason,
            ];
        });
        Storage::put("$dir/bookings.json", json_encode($bookings, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));

        $this->info("✅ Экспорт завершён. Файлы сохранены в storage/app/exports/");
        return Command::SUCCESS;
    }
}
PHP

# === 5. ImportTimetableFromJsonCommand ===
cat > app/Console/Commands/ImportTimetableFromJsonCommand.php <<'PHP'
<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Illuminate\Support\Str;
use Carbon\Carbon;
use App\Models\{ResourceType, Resource, Timetable, TimetableDate};
use Illuminate\Support\Facades\DB;

class ImportTimetableFromJsonCommand extends Command
{
    protected $signature = 'booking:import-timetable
                            {file : Путь до JSON файла (локальный путь или storage/app/...) }
                            {--company-id=1}
                            {--company-name=Demo Company}
                            {--generate-resources=0 : Если в JSON нет resources, сгенерировать N фейковых ресурсов}
                            {--days=30 : Количество дней для генерации (если генерируем динамические даты)}';

    protected $description = 'Импортирует расписание из JSON и создаёт ResourceType/Resource/Timetable/TimetableDate.';

    public function handle()
    {
        $file = $this->argument('file');
        if (!file_exists($file)) {
            $storagePath = storage_path('app/' . ltrim($file, '/'));
            if (file_exists($storagePath)) $file = $storagePath;
            else {
                $this->error("Файл не найден: {$file}");
                return 1;
            }
        }

        $data = json_decode(file_get_contents($file), true);
        if (!$data) {
            $this->error("Ошибка парсинга JSON (проверь формат).");
            return 1;
        }

        $companyId = (int)$this->option('company-id');
        $companyName = $this->option('company-name');

        DB::beginTransaction();
        try {
            $rt = $data['resource_type'] ?? [
                'type' => $data['section'] ?? 'default',
                'name' => $data['section_name'] ?? 'Section',
                'description' => $data['description'] ?? null,
                'resource_config' => $data['resource_config'] ?? []
            ];

            $resourceType = ResourceType::firstOrCreate(
                ['company_id' => $companyId, 'type' => $rt['type']],
                [
                    'name' => $rt['name'] ?? ucfirst($rt['type']),
                    'description' => $rt['description'],
                    'resource_config' => $rt['resource_config'] ?? []
                ]
            );
            $this->info("Создан/найден тип ресурса: {$resourceType->name}");

            $resources = $data['resources'] ?? [];
            $generateCount = max(0, (int)$this->option('generate-resources'));
            if (empty($resources) && $generateCount > 0) {
                for ($i = 1; $i <= $generateCount; $i++) {
                    $resources[] = [
                        'name' => "Тренер {$i}",
                        'resource_config' => $rt['resource_config'],
                        'timetable' => $data['default_timetable'] ?? null
                    ];
                }
            }

            foreach ($resources as $r) {
                $resource = Resource::create([
                    'company_id' => $companyId,
                    'resource_type_id' => $resourceType->id,
                    'payload' => ['name' => $r['name'] ?? ('Trainer ' . Str::random(4))],
                    'resource_config' => $r['resource_config'] ?? $rt['resource_config']
                ]);

                $tt = $r['timetable'] ?? ($data['default_timetable'] ?? null);
                $ttType = $tt['type'] ?? 'static';
                $ttPayload = $tt['config'] ?? $tt['payload'] ?? $tt;

                $timetable = Timetable::create([
                    'resource_id' => $resource->id,
                    'type' => $ttType,
                    'config' => $ttPayload,
                ]);

                if ($ttType === 'dynamic') {
                    $dates = $tt['dates'] ?? [];
                    if (empty($dates)) {
                        $start = Carbon::today();
                        $days = (int)$this->option('days');
                        for ($i = 0; $i < $days; $i++) {
                            $date = $start->copy()->addDays($i);
                            if ($date->isSunday()) continue;
                            TimetableDate::create([
                                'timetable_id' => $timetable->id,
                                'date' => $date->toDateString(),
                                'start' => '10:00',
                                'end' => '18:00',
                                'breaks' => [['start' => '13:00','end'=>'13:30']]
                            ]);
                        }
                    } else {
                        foreach ($dates as $d => $v) {
                            TimetableDate::create([
                                'timetable_id' => $timetable->id,
                                'date' => $d,
                                'start' => $v['working_hours']['start'],
                                'end' => $v['working_hours']['end'],
                                'breaks' => $v['breaks'] ?? []
                            ]);
                        }
                    }
                }
            }

            DB::commit();
            $this->info("✅ Импорт расписания завершён.");
            return 0;
        } catch (\Throwable $e) {
            DB::rollBack();
            $this->error("Ошибка импорта: " . $e->getMessage());
            return 1;
        }
    }
}
PHP

echo "✅ Часть 5 завершена: добавлены artisan-команды и импорт расписаний из JSON."
#!/usr/bin/env bash
set -e

echo "=== Установка Booking Module (Часть 6: создание README.md с инструкциями) ==="

cat > README.md <<'MD'
# 🧾 Laravel Booking Module — Модуль бронирования ресурсов

## 📘 Описание

Модуль позволяет бронировать ресурсы (сотрудников, комнаты, оборудование)
в рамках одной компании.
Он реализован как часть монолитного приложения Laravel 10 и полностью автономен.

---

## ⚙️ Требования

- PHP 8.2+
- Laravel 10.x
- MySQL 5.7+
- Composer
- Redis (опционально — пока не используется)

---

## 🚀 Установка

1. Склонируй чистый Laravel-проект и установи зависимости:
   ```bash
   composer install
2. Скопируй и выполни все установочные части:
cat install_booking_part_*.sh > install_booking.sh
chmod +x install_booking.sh
./install_booking.sh

3. Прогони миграции:
php artisan migrate


4. Добавь в config/app.php провайдер:
Добавь в config/app.php провайдер:

App\Providers\BookingServiceProvider::class,

5. Проверь, что появился лог-канал booking в config/logging.php

Основные Artisan-команды
| Команда                                 | Описание                           |
| --------------------------------------- | ---------------------------------- |
| `php artisan booking:seed-demo --fresh` | Создать тестовые ресурсы и брони   |
| `php artisan booking:run-demo-actions`  | Имитация сценария бронирования     |
| `php artisan booking:show-demo-curl`    | Примеры API-запросов               |
| `php artisan booking:export-json`       | Экспорт расписаний и броней в JSON |

API эндпоинты
| Метод  | URL                             | Описание          |
| ------ | ------------------------------- | ----------------- |
| `POST` | `/api/resources/{id}/bookings`  | Создать бронь     |
| `POST` | `/api/bookings/{id}/confirm`    | Подтвердить бронь |
| `POST` | `/api/bookings/{id}/cancel`     | Отменить бронь    |
| `POST` | `/api/bookings/{id}/reschedule` | Перенести бронь   |

Примеры можно получить командой:

php artisan booking:show-demo-curl

Пример запуска и тестирования

Создай тестовые данные:

php artisan booking:seed-demo --fresh


Запусти демонстрацию сценария:

php artisan booking:run-demo-actions


Проверь логи:

tail -n 30 storage/logs/booking.log


Экспортируй JSON-файлы:

php artisan booking:export-json


Результат появится в storage/app/exports/:

resource_types.json
resources.json
bookings.json


Логика модуля
Слоты

Слоты создаются стратегиями:

FixedStrategy — равные интервалы

DynamicStrategy — свободные интервалы между бронями

Бронирование

Проверка доступности слота (start < :end && end > :start)

Создание брони

Подтверждение админом (если требуется)

Возможность отмены или переноса

События

BookingCreated

BookingConfirmed

BookingCancelled

BookingRescheduled

BookingReminder

Каждое событие логируется в storage/logs/booking.log.

🧱 Структура каталогов
app/
 ├── Console/Commands/     # Artisan-команды
 ├── Events/               # События системы бронирования
 ├── Http/Controllers/     # API контроллеры
 ├── Interfaces/           # Контракты Timetable и Strategy
 ├── Listeners/            # Слушатели событий (логирование, уведомления)
 ├── Models/               # Модели базы данных
 ├── Providers/            # ServiceProvider и EventServiceProvider
 ├── Services/             # Основная бизнес-логика
 ├── Slots/Strategies/     # Стратегии генерации слотов
 ├── Timetables/           # Расписания (Static/Dynamic)
 └── ValueObjects/         # Конфигурации ресурсов

🧾 Пример логов
[2025-10-07 10:00:00] local.INFO: 🔹 createBooking() вызван {resource_id:1}
[2025-10-07 10:00:01] local.INFO: ✅ Бронирование создано {booking_id:1,status:"pending_confirmation"}
[2025-10-07 10:00:02] local.INFO: [NotifyAdmin] BookingCreated: Booking #1 (2025-10-08 10:00-11:00)
[2025-10-07 10:05:00] local.INFO: ✅ Бронирование подтверждено {booking_id:1}
[2025-10-07 10:06:00] local.INFO: ✅ Бронирование перенесено {booking_id:1,new_start:"2025-10-09 11:00"}
[2025-10-07 10:10:00] local.INFO: ❌ Бронирование отменено {booking_id:1,reason:"Клиент передумал"}

💡 Идеи для расширения

Добавить Redis для кэширования расписаний

Интегрировать Email/SMS уведомления

Подключить оплату перед подтверждением

Добавить веб-интерфейс календаря (Vue/React)

MD

echo "✅ Часть 6 завершена: README.md с инструкцией создан."
#!/usr/bin/env bash
set -e

echo "=== Установка Booking Module (Часть 7: события, слушатели, логирование, уведомления) ==="

mk() { mkdir -p "$1"; }

mk app/Listeners
mk app/Providers

# === LogBookingActivityListener ===
cat > app/Listeners/LogBookingActivityListener.php <<'PHP'
<?php

namespace App\Listeners;

use Illuminate\Support\Facades\Log;

class LogBookingActivityListener
{
    public function handle($event): void
    {
        $eventClass = class_basename($event);
        $bookingId = $event->booking->id ?? null;
        $status = $event->booking->status ?? 'unknown';

        $message = sprintf('[BookingEvent] %s: Booking #%s (status: %s)', $eventClass, $bookingId, $status);

        Log::channel('booking')->info($message, [
            'event' => $eventClass,
            'booking_id' => $bookingId,
            'status' => $status,
            'timestamp' => now()->toDateTimeString(),
        ]);
    }
}
PHP

# === SendBookingReminderListener ===
cat > app/Listeners/SendBookingReminderListener.php <<'PHP'
<?php

namespace App\Listeners;

use Illuminate\Support\Facades\Log;

class SendBookingReminderListener
{
    public function handle($event): void
    {
        $booking = $event->booking;

        $message = sprintf(
            '[BookingReminder] Reminder sent for Booking #%s (%s - %s)',
            $booking->id,
            $booking->start,
            $booking->end
        );

        Log::channel('booking')->info($message, [
            'booking_id' => $booking->id,
            'start' => $booking->start,
            'end' => $booking->end,
            'timestamp' => now()->toDateTimeString(),
        ]);
    }
}
PHP

# === NotifyAdminOfBookingListener ===
cat > app/Listeners/NotifyAdminOfBookingListener.php <<'PHP'
<?php

namespace App\Listeners;

use Illuminate\Support\Facades\Log;

class NotifyAdminOfBookingListener
{
    public function handle($event): void
    {
        $booking = $event->booking;
        $eventClass = class_basename($event);

        $adminMessage = sprintf(
            '[NotifyAdmin] %s: Booking #%s (%s - %s, status: %s)',
            $eventClass,
            $booking->id,
            $booking->start,
            $booking->end,
            $booking->status
        );

        Log::channel('booking')->info($adminMessage, [
            'event' => $eventClass,
            'booking_id' => $booking->id,
            'status' => $booking->status,
            'start' => $booking->start,
            'end' => $booking->end,
            'timestamp' => now()->toDateTimeString(),
            'notified_admin' => true,
        ]);
    }
}
PHP

# === EventServiceProvider ===
cat > app/Providers/EventServiceProvider.php <<'PHP'
<?php

namespace App\Providers;

use Illuminate\Foundation\Support\Providers\EventServiceProvider as ServiceProvider;
use App\Events\{
    BookingCreated,
    BookingPendingConfirmation,
    BookingConfirmed,
    BookingRejected,
    BookingCancelled,
    BookingRescheduled,
    BookingReminder
};
use App\Listeners\{
    LogBookingActivityListener,
    SendBookingReminderListener,
    NotifyAdminOfBookingListener
};

class EventServiceProvider extends ServiceProvider
{
    protected $listen = [
        BookingCreated::class => [
            LogBookingActivityListener::class,
            NotifyAdminOfBookingListener::class,
        ],
        BookingPendingConfirmation::class => [
            LogBookingActivityListener::class,
            NotifyAdminOfBookingListener::class,
        ],
        BookingConfirmed::class => [
            LogBookingActivityListener::class,
            NotifyAdminOfBookingListener::class,
        ],
        BookingRejected::class => [
            LogBookingActivityListener::class,
            NotifyAdminOfBookingListener::class,
        ],
        BookingCancelled::class => [
            LogBookingActivityListener::class,
            NotifyAdminOfBookingListener::class,
        ],
        BookingRescheduled::class => [
            LogBookingActivityListener::class,
            NotifyAdminOfBookingListener::class,
        ],
        BookingReminder::class => [
            LogBookingActivityListener::class,
            SendBookingReminderListener::class,
            NotifyAdminOfBookingListener::class,
        ],
    ];

    public function boot(): void
    {
        parent::boot();
    }
}
PHP

# === Добавляем лог-канал booking в config/logging.php ===
if grep -q "'channels' =>" config/logging.php; then
  echo "🔧 Добавляем лог-канал 'booking' в config/logging.php ..."
  sed -i "/'channels' => \[/a \ \ \ \ 'booking' => [\
            'driver' => 'single',\
            'path' => storage_path('logs/booking.log'),\
            'level' => 'info',\
        ]," config/logging.php
else
  echo "⚠️ Не найден 'channels' в config/logging.php — добавь канал вручную"
fi

# === Обновляем BookingServiceProvider, чтобы зарегистрировать EventServiceProvider ===
if ! grep -q "EventServiceProvider" app/Providers/BookingServiceProvider.php 2>/dev/null; then
cat >> app/Providers/BookingServiceProvider.php <<'PHP'

        // Регистрируем слушатели событий бронирования
        $this->app->register(\App\Providers\EventServiceProvider::class);
PHP
fi

echo "✅ Часть 7 завершена: добавлены события, слушатели и логирование."
echo "🎯 Логи событий будут писаться в storage/logs/booking.log"
#!/usr/bin/env bash
set -e

echo "=== Установка Booking Module (Часть 8: BookingService с логированием + README_ARCHITECTURE.md) ==="

mk() { mkdir -p "$1"; }

mk app/Services

# === BookingService ===
cat > app/Services/BookingService.php <<'PHP'
<?php

namespace App\Services;

use App\Models\{Booking, Resource};
use App\Events\{
    BookingCreated,
    BookingPendingConfirmation,
    BookingConfirmed,
    BookingCancelled,
    BookingRescheduled
};
use Carbon\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Exception;

class BookingService
{
    protected function log(string $message, array $context = []): void
    {
        Log::channel('booking')->info($message, array_merge([
            'timestamp' => now()->toDateTimeString(),
        ], $context));
    }

    public function createBooking(Resource $resource, Carbon $start, Carbon $end, bool $isGroup = false): Booking
    {
        $this->log('🔹 createBooking() вызван', [
            'resource_id' => $resource->id,
            'start' => $start,
            'end' => $end,
            'is_group_booking' => $isGroup,
        ]);

        return DB::transaction(function () use ($resource, $start, $end, $isGroup) {
            $key = "booking_lock_{$resource->id}";

            return Cache::lock($key, 5)->block(3, function () use ($resource, $start, $end, $isGroup) {

                $this->log('Проверяем пересечение броней...', [
                    'resource_id' => $resource->id,
                    'start' => $start,
                    'end' => $end,
                ]);

                $overlap = Booking::where('resource_id', $resource->id)
                    ->where('start', '<', $end)
                    ->where('end', '>', $start)
                    ->exists();

                if ($overlap) {
                    $this->log('❌ Слот занят', ['resource_id' => $resource->id]);
                    throw new Exception("Slot not available");
                }

                $status = $resource->resource_config->require_confirmation
                    ? 'pending_confirmation'
                    : 'confirmed';

                $booking = Booking::create([
                    'company_id' => $resource->company_id,
                    'resource_id' => $resource->id,
                    'is_group_booking' => $isGroup,
                    'start' => $start,
                    'end' => $end,
                    'status' => $status,
                ]);

                $this->log('✅ Бронирование создано', [
                    'booking_id' => $booking->id,
                    'status' => $booking->status,
                ]);

                event(new BookingCreated($booking));

                if ($booking->status === 'pending_confirmation') {
                    event(new BookingPendingConfirmation($booking));
                } else {
                    event(new BookingConfirmed($booking));
                }

                return $booking;
            });
        });
    }

    public function confirmBooking(Booking $booking): Booking
    {
        $this->log('🔹 confirmBooking() вызван', ['booking_id' => $booking->id]);

        if ($booking->status !== 'pending_confirmation') {
            throw new Exception("Booking is not pending confirmation");
        }

        $booking->update(['status' => 'confirmed']);
        $this->log('✅ Бронирование подтверждено', ['booking_id' => $booking->id]);
        event(new BookingConfirmed($booking));

        return $booking;
    }

    public function cancelBooking(Booking $booking, string $by = 'client', ?string $reason = null): Booking
    {
        $this->log('🔹 cancelBooking() вызван', [
            'booking_id' => $booking->id,
            'cancelled_by' => $by,
            'reason' => $reason,
        ]);

        if (!in_array($booking->status, ['pending_confirmation', 'confirmed'])) {
            throw new Exception("Booking cannot be cancelled");
        }

        $status = $by === 'admin' ? 'cancelled_by_admin' : 'cancelled_by_client';
        $booking->update(['status' => $status, 'reason' => $reason]);

        $this->log('❌ Бронирование отменено', [
            'booking_id' => $booking->id,
            'status' => $status,
            'reason' => $reason,
        ]);

        event(new BookingCancelled($booking));
        return $booking;
    }

    public function rescheduleBooking(Booking $booking, Carbon $newStart, Carbon $newEnd, string $by = 'client'): Booking
    {
        $this->log('🔹 rescheduleBooking() вызван', [
            'booking_id' => $booking->id,
            'new_start' => $newStart,
            'new_end' => $newEnd,
            'requested_by' => $by,
        ]);

        if ($booking->status !== 'confirmed') {
            throw new Exception("Only confirmed bookings can be rescheduled");
        }

        if ($by === 'client' && $booking->is_group_booking) {
            throw new Exception("Clients cannot reschedule group bookings");
        }

        $overlap = Booking::where('resource_id', $booking->resource_id)
            ->where('id', '<>', $booking->id)
            ->where('start', '<', $newEnd)
            ->where('end', '>', $newStart)
            ->exists();

        if ($overlap) {
            throw new Exception("New time not available");
        }

        $booking->update(['start' => $newStart, 'end' => $newEnd]);
        $this->log('✅ Бронирование перенесено', [
            'booking_id' => $booking->id,
            'new_start' => $newStart,
            'new_end' => $newEnd,
        ]);

        event(new BookingRescheduled($booking));
        return $booking;
    }
}
PHP

# === README_ARCHITECTURE.md ===
cat > README_ARCHITECTURE.md <<'MD'
# 🧭 Архитектура и логика работы системы бронирования

## 📘 Описание проекта
Модуль **Booking System** — часть Laravel-приложения, отвечающая за бронирование ресурсов (сотрудников, комнат, оборудования).
Работает автономно, использует Laravel Events, транзакции и логирование.

## 🧱 Структура
- **Models** — данные
- **Services** — бизнес-логика
- **Events/Listeners** — события и обработка
- **Console/Commands** — сценарии и демо
- **Logs** — все действия в `storage/logs/booking.log`

## ⚙️ Алгоритмы

### 🟩 Создание брони
1. Проверка пересечения времён
2. Создание записи в `bookings`
3. Определение статуса (`pending_confirmation` или `confirmed`)
4. Генерация событий
5. Запись в лог

### 🟥 Отмена
1. Проверка статуса
2. Обновление в БД
3. Событие `BookingCancelled`
4. Лог: ❌ отменено

### 🔄 Перенос
1. Проверка статуса = confirmed
2. Проверка пересечений
3. Обновление времени
4. Событие `BookingRescheduled`

## 🧩 События и слушатели
| Событие | Слушатели |
|----------|------------|
| BookingCreated | LogBookingActivity, NotifyAdmin |
| BookingConfirmed | LogBookingActivity, NotifyAdmin |
| BookingCancelled | LogBookingActivity, NotifyAdmin |
| BookingRescheduled | LogBookingActivity, NotifyAdmin |
| BookingReminder | SendReminder, LogBookingActivity |

## 📊 Преимущества
- Чистая архитектура (SOLID)
- Транзакции и блокировки
- Расширяемость (email, SMS, оплатa)
- Прозрачное логирование

## 🚀 Демонстрация
```bash
php artisan booking:seed-demo --fresh
php artisan booking:run-demo-actions
php artisan booking:export-json
tail -n 20 storage/logs/booking.log

MD
