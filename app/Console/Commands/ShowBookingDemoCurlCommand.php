<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class ShowBookingDemoCurlCommand extends Command
{
    protected $signature = 'booking:demo-curl';
    protected $description = 'Show example curl commands for demo bookings';

    public function handle()
    {
        $this->info("=== Иван (fixed, confirm required) ===");
        $this->line("curl -X POST http://127.0.0.1:8000/api/resources/1/bookings -H 'Content-Type: application/json' -d '{\"start\":\"2025-10-01 10:00:00\",\"end\":\"2025-10-01 11:00:00\"}'");
        $this->line("curl -X POST http://127.0.0.1:8000/api/bookings/1/confirm");
        $this->newLine();

        $this->info("=== Мария (dynamic, auto confirm) ===");
        $this->line("curl -X POST http://127.0.0.1:8000/api/resources/2/bookings -H 'Content-Type: application/json' -d '{\"start\":\"2025-10-01 10:30:00\",\"end\":\"2025-10-01 11:00:00\"}'");
        $this->newLine();

        $this->info("=== Номер 200 (fixed, group booking) ===");
        $this->line("curl -X POST http://127.0.0.1:8000/api/resources/3/bookings -H 'Content-Type: application/json' -d '{\"start\":\"2025-10-01 08:00:00\",\"end\":\"2025-10-01 10:00:00\",\"participants_count\":3}'");
        $this->line("curl -X POST http://127.0.0.1:8000/api/resources/3/bookings -H 'Content-Type: application/json' -d '{\"start\":\"2025-10-01 08:00:00\",\"end\":\"2025-10-01 10:00:00\",\"participants_count\":2}'");
        $this->newLine();

        $this->info("=== Номер 404 (dynamic) ===");
        $this->line("curl -X POST http://127.0.0.1:8000/api/resources/4/bookings -H 'Content-Type: application/json' -d '{\"start\":\"2025-10-01 09:00:00\",\"end\":\"2025-10-01 10:30:00\"}'");
    }
}
