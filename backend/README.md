# Telcell Tickets — Backend (C# / .NET 8 + PostgreSQL)

REST API для приложения афиши: события, поиск/фильтры (как в Яндекс Афише),
карта, покупка билетов (mock-оплата) с выдачей QR, «Мои билеты», check-in по QR.

## Стек
- ASP.NET Core 8 Minimal API
- Entity Framework Core + Npgsql (PostgreSQL)
- Swagger (документация + ручное тестирование)

## Запуск

1. Установи PostgreSQL и создай пустую БД (например `telcell_tickets`).
   Строка подключения — в `appsettings.json` → `ConnectionStrings:Postgres`.

2. Установи EF-инструменты (один раз):
   ```bash
   dotnet tool install --global dotnet-ef
   ```

3. Создай первую миграцию и применённую схему:
   ```bash
   cd backend/TelcellTickets.Api
   dotnet ef migrations add InitialCreate
   ```
   Миграция применяется автоматически при старте (`db.Database.Migrate()`),
   а демо-события засеиваются (`DbSeeder`).

4. Запуск:
   ```bash
   dotnet run
   ```
   API поднимется на `http://localhost:5000` (или порт из консоли).
   Swagger UI: `http://localhost:5000/swagger`.

## Эндпоинты

| Метод | Путь | Назначение |
| --- | --- | --- |
| GET  | `/api/events` | Список событий. Фильтры: `category, q, city, from, to, featured` |
| GET  | `/api/events/{id}` | Карточка события |
| GET  | `/api/map/events` | События с координатами площадок (для карты) |
| POST | `/api/checkout` | Покупка (mock-оплата) → заказ Paid + билеты с QR |
| GET  | `/api/users/{phone}/tickets` | Билеты покупателя |
| POST | `/api/checkin` | Скан QR на входе |

### Пример покупки
```http
POST /api/checkout
{
  "buyerName": "Ани",
  "buyerPhone": "+37411223344",
  "items": [{ "ticketTypeId": "<guid>", "quantity": 2 }]
}
```

## Схема БД
`Venue` (1—N) `Event` (1—N) `TicketType`
`AppUser` (1—N) `Order` (1—N) `Ticket` (N—1 `TicketType`, N—1 `Event`)

QR-токен билета уникален (индекс), сканируется один раз → статус `CheckedIn`.

## Подключение Flutter
В клиенте задай базовый URL API (см. `lib/services/http_tickets_api.dart`)
на адрес запущенного бэкенда, напр. `http://localhost:5000`.
