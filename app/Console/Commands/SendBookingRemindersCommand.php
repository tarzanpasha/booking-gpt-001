<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use App\Models\Booking;
use App\Events\BookingReminder;
use Carbon\Carbon;

class SendBookingRemindersCommand extends Command
{
    protected $signature = 'booking:send-reminders {--minutes=60 : За сколько минут до начала напоминать}';
    protected $description = 'Отправляет напоминания о предстоящих бронированиях (генерирует события BookingReminder)';

    public function handle()
    {
        $minutes = (int)$this->option('minutes');
        $from = Carbon::now();
        $to = $from->copy()->addMinutes($minutes);

        $this->info("🔔 Поиск броней, начинающихся с {$from} по {$to}...");

        $bookings = Booking::where('status', 'confirmed')
            ->whereBetween('start', [$from, $to])
            ->get();

        if ($bookings->isEmpty()) {
            $this->info("Нет броней для напоминания.");
            return Command::SUCCESS;
        }

        foreach ($bookings as $booking) {
            event(new BookingReminder($booking));
            $this->info("📨 Напоминание отправлено для брони #{$booking->id} ({$booking->start} - {$booking->end})");
        }

        $this->info("✅ Завершено: отправлено напоминаний — {$bookings->count()}.");
        return Command::SUCCESS;
    }
}
