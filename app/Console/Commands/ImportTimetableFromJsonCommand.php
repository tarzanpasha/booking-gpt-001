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
