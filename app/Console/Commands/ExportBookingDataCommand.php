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
