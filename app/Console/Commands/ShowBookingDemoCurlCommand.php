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
