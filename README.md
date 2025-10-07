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

