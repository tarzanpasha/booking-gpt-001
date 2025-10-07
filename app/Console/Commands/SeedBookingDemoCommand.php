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
