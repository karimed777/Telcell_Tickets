# Telcell Tickets — Flutter (мобильное приложение)

Мобильное приложение для поиска и покупки билетов на мероприятия в Армении.
Дизайн построен на фирменных цветах **Telcell Wallet**.

## Фирменная палитра (из брендбука Telcell)

| Цвет | HEX | Роль |
|---|---|---|
| Оранжевый (абрикос) | `#FF5B2E` | Главный CTA, активные чипы |
| Индиго | `#361268` | Тёмные секции, бренд, билет |
| Циан | `#73DFFF` | Второй акцент, иконки |
| Серый | `#585A60` | Вторичный текст |
| Белый | `#FFFFFF` | Карточки, фон |
| Шрифт | Manrope | бесплатный аналог Graphik Armenian |

## Что внутри (5 экранов)

1. **Онбординг / Вход** — `screens/onboarding_screen.dart` (индиго-фон, 2 CTA: Telcell Wallet + гость)
2. **Каталог / Главная** — `screens/catalog_screen.dart` (поиск, чипы категорий, герой-карточка, список)
3. **Карточка события** — `screens/event_details_screen.dart` (обложка, описание, типы билетов, sticky «Купить»)
4. **Оформление + оплата** — `screens/checkout_screen.dart` (степперы, промокод, Telcell Wallet / карта, итог)
5. **Мои билеты + QR** — `screens/my_tickets_screen.dart` (фирменный перфорированный билет + полноэкранный QR)

Фишка дизайна — **перфорированный билет** (`widgets/ticket_card.dart`) с индиго-корешком и зубчатым краем.

## Как запустить

```bash
# 1. Распакуй архив, зайди в папку
cd telcell_tickets

# 2. Подтяни зависимости
flutter pub get

# 3. Запусти
flutter run
```

## Шрифт Manrope

Два варианта (выбери один в `pubspec.yaml`):
- **Просто:** раскомментируй `google_fonts: ^6.1.0` — шрифт скачается сам.
- **Локально:** скачай Manrope с Google Fonts, положи `.ttf` в `assets/fonts/` и раскомментируй блок `fonts:` в `pubspec.yaml`.

Если ничего не делать — приложение запустится на системном шрифте, дизайн не сломается.

## Что дальше (под бэкенд на C# / .NET)

Сейчас данные — моки в `models/event.dart` (`MockData`). Для интеграции с твоим API:
- замени `MockData.events` на запрос к REST API (`http` / `dio`);
- замени декоративный `QrPainter` на пакет `qr_flutter` с **динамическим** QR, который генерит/проверяет бэкенд (так задумано в PRD — серверная проверка билета);
- добавь модель ответа сервера и слой репозитория.

## Структура

```
lib/
  main.dart
  theme/app_theme.dart        # цвета, шрифт, стили (фирменная тема Telcell)
  models/event.dart           # модели Event / TicketType + моки
  screens/
    onboarding_screen.dart
    home_shell.dart           # нижняя навигация
    catalog_screen.dart
    event_details_screen.dart
    checkout_screen.dart
    my_tickets_screen.dart
  widgets/
    event_card.dart           # карточка события + герой-карточка
    ticket_card.dart          # СИГНАТУРНЫЙ перфорированный билет + QR
    brand_shapes.dart         # фоновые фирменные 3D-фигуры
```
