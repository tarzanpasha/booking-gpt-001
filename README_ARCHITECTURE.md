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
