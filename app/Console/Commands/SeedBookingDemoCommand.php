<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\ResourceType;
use App\Models\Resource;
use App\Models\Timetable;
use App\Models\TimetableDate;
use Illuminate\Support\Facades\DB;

class SeedBookingDemoCommand extends Command
{
    protected $signature = 'booking:seed-demo {--fresh : Migrate fresh before seeding}';
    protected $description = 'Seed demo data for booking system (resources, timetables, etc.)';

    public function handle()
    {
        if ($this->option('fresh')) {
            $this->warn('Running migrate:fresh ...');
            $this->call('migrate:fresh');
        }

        DB::transaction(function () {
            ResourceType::query()->delete();

            // Тип: сотрудники
            $staffType = ResourceType::create([
                'company_id' => 1,
                'type' => 'staff',
                'name' => 'Сотрудник',
                'description' => 'Персонал компании',
                'resource_config' => [
                    'slot_duration_minutes' => 60,
                    'slot_strategy' => 'fixed'
                ]
            ]);

            $ivan = Resource::create([
                'company_id' => 1,
                'resource_type_id' => $staffType->id,
                'payload' => ['name' => 'Иван Тренер'],
                'resource_config' => [
                    'require_confirmation' => true,
                    'slot_duration_minutes' => 60,
                    'slot_strategy' => 'fixed',
                ]
            ]);

            Timetable::create([
                'company_id' => 1,
                'resource_id' => $ivan->id,
                'name' => 'Иван график',
                'type' => 'static',
                'payload' => [
                    'schedule' => [
                        'default' => [
                            'working_hours' => ['start' => '09:00', 'end' => '18:00'],
                            'breaks' => [['start' => '13:00', 'end' => '14:00']]
                        ],
                        'exceptions' => [
                            'sunday' => ['working_hours' => null, 'breaks' => []]
                        ],
                        'holidays' => ['01-01','05-01','12-25']
                    ]
                ]
            ]);

            $maria = Resource::create([
                'company_id' => 1,
                'resource_type_id' => $staffType->id,
                'payload' => ['name' => 'Мария Парикмахер'],
                'resource_config' => [
                    'require_confirmation' => false,
                    'slot_duration_minutes' => 30,
                    'slot_strategy' => 'dynamic',
                ]
            ]);

            $timetableMaria = Timetable::create([
                'company_id' => 1,
                'resource_id' => $maria->id,
                'name' => 'Мария график',
                'type' => 'dynamic',
            ]);

            for ($i=0; $i<30; $i++) {
                $date = now()->addDays($i);
                if (in_array($date->dayOfWeek, [0])) continue; // воскресенье
                TimetableDate::create([
                    'timetable_id' => $timetableMaria->id,
                    'date' => $date->toDateString(),
                    'start' => '10:00',
                    'end' => '17:00',
                    'breaks' => [['start'=>'12:00','end'=>'12:30']]
                ]);
            }

            // Тип: комнаты
            $roomType = ResourceType::create([
                'company_id' => 1,
                'type' => 'room',
                'name' => 'Комната',
                'description' => 'Помещения компании',
                'resource_config' => [
                    'slot_duration_minutes' => 120,
                    'slot_strategy' => 'fixed',
                    'max_participants' => 5
                ]
            ]);

            $room200 = Resource::create([
                'company_id' => 1,
                'resource_type_id' => $roomType->id,
                'payload' => ['name' => 'Номер 200'],
                'resource_config' => [
                    'slot_duration_minutes' => 120,
                    'slot_strategy' => 'fixed',
                    'max_participants' => 5
                ]
            ]);

            Timetable::create([
                'company_id' => 1,
                'resource_id' => $room200->id,
                'name' => 'Номер 200 график',
                'type' => 'static',
                'payload' => [
                    'schedule' => [
                        'default' => [
                            'working_hours' => ['start' => '08:00', 'end' => '20:00'],
                            'breaks' => [['start'=>'12:00','end'=>'13:00']]
                        ],
                        'exceptions' => ['sunday'=>['working_hours'=>null,'breaks'=>[]]],
                        'holidays' => []
                    ]
                ]
            ]);

            $room404 = Resource::create([
                'company_id' => 1,
                'resource_type_id' => $roomType->id,
                'payload' => ['name' => 'Номер 404'],
                'resource_config' => [
                    'slot_duration_minutes' => 90,
                    'slot_strategy' => 'dynamic',
                ]
            ]);

            $timetableRoom404 = Timetable::create([
                'company_id' => 1,
                'resource_id' => $room404->id,
                'name' => 'Номер 404 график',
                'type' => 'dynamic',
            ]);

            for ($i=0; $i<30; $i++) {
                $date = now()->addDays($i);
                if (in_array($date->dayOfWeek, [0])) continue;
                TimetableDate::create([
                    'timetable_id' => $timetableRoom404->id,
                    'date' => $date->toDateString(),
                    'start' => '09:00',
                    'end' => '18:00',
                    'breaks' => [['start'=>'15:00','end'=>'15:30']]
                ]);
            }

            $this->info('✅ Demo data seeded (Иван, Мария, Номер 200, Номер 404, на месяц вперед)');
        });
    }
}
