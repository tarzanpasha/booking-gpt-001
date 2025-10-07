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
