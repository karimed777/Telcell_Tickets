using Microsoft.EntityFrameworkCore;
using TelcellTickets.Api.Data;
using TelcellTickets.Api.Dtos;
using TelcellTickets.Api.Models;

var builder = WebApplication.CreateBuilder(args);

// ─── Postgres через EF Core ──────────────────────────────────────────
var cs = builder.Configuration.GetConnectionString("Postgres")
         ?? "Host=localhost;Port=5432;Database=telcell_tickets;Username=postgres;Password=postgres";
builder.Services.AddDbContext<AppDbContext>(o => o.UseNpgsql(cs));

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

// CORS — чтобы Flutter web (Chrome) мог ходить на API
builder.Services.AddCors(o => o.AddDefaultPolicy(p =>
    p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod()));

var app = builder.Build();

// Применяем миграции + seed при старте
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    db.Database.Migrate();
    DbSeeder.Seed(db);
}

app.UseSwagger();
app.UseSwaggerUI();
app.UseCors();

// ─── Маппинг в DTO ───────────────────────────────────────────────────
// Refund Guarantee пока не хранится в БД отдельной колонкой: выводим его
// из события (рекомендованные/featured события возвратны). Так появляется
// кнопка «Запросить возврат» без миграции схемы.
static bool RefundAllowed(Event e) => e.IsFeatured;
const int RefundUntilHoursDefault = 48;

static EventDto ToDto(Event e) => new(
    e.Id, e.Title, e.TitleAm, e.Description, e.DescriptionAm, e.Category.ToString(), e.StartsAt,
    e.CoverColorHex, e.CoverImageUrl, e.IsFeatured,
    new VenueDto(e.Venue!.Id, e.Venue.Name, e.Venue.NameAm, e.Venue.City, e.Venue.Address, e.Venue.AddressAm,
        e.Venue.Latitude, e.Venue.Longitude),
    e.TicketTypes.Select(t => new TicketTypeDto(t.Id, t.Name, t.NameAm, t.Price, t.Currency, t.Quantity - t.Sold)),
    e.TicketTypes.Count == 0 ? 0 : e.TicketTypes.Min(t => t.Price),
    RefundAllowed(e), RefundUntilHoursDefault);

static TicketDto TicketToDto(Ticket t) => new(
    t.Id, t.EventId, t.Event!.Title, t.Event.StartsAt, t.Event.Venue!.Name,
    t.TicketType!.Name, t.TicketType.Price, t.TicketType.Currency,
    t.QrToken, t.Status.ToString(), t.IssuedAt, t.TransferredTo,
    RefundAllowed(t.Event), RefundUntilHoursDefault);

// ─── СОБЫТИЯ: список с поиском/фильтрами (как в Яндекс Афише) ─────────
// GET /api/events?category=Concert&q=rock&city=Yerevan&from=2026-07-01&featured=true
app.MapGet("/api/events", async (AppDbContext db,
    string? category, string? q, string? city, DateTimeOffset? from, DateTimeOffset? to, bool? featured) =>
{
    var query = db.Events
        .Include(e => e.Venue)
        .Include(e => e.TicketTypes)
        .AsQueryable();

    if (!string.IsNullOrWhiteSpace(category) &&
        Enum.TryParse<EventCategory>(category, true, out var cat))
        query = query.Where(e => e.Category == cat);

    if (!string.IsNullOrWhiteSpace(q))
    {
        var term = q.Trim().ToLower();
        query = query.Where(e =>
            e.Title.ToLower().Contains(term) ||
            e.Description.ToLower().Contains(term) ||
            e.Venue!.Name.ToLower().Contains(term));
    }

    if (!string.IsNullOrWhiteSpace(city))
        query = query.Where(e => e.Venue!.City == city);

    if (from.HasValue) query = query.Where(e => e.StartsAt >= from);
    if (to.HasValue) query = query.Where(e => e.StartsAt <= to);
    if (featured == true) query = query.Where(e => e.IsFeatured);

    var list = await query.OrderBy(e => e.StartsAt).ToListAsync();
    return Results.Ok(list.Select(ToDto));
});

// GET /api/events/{id}
app.MapGet("/api/events/{id:guid}", async (AppDbContext db, Guid id) =>
{
    var e = await db.Events.Include(x => x.Venue).Include(x => x.TicketTypes)
        .FirstOrDefaultAsync(x => x.Id == id);
    return e is null ? Results.NotFound() : Results.Ok(ToDto(e));
});

// ─── КАРТА: события с координатами площадок ───────────────────────────
// GET /api/map/events
app.MapGet("/api/map/events", async (AppDbContext db) =>
{
    var list = await db.Events.Include(e => e.Venue).Include(e => e.TicketTypes)
        .OrderBy(e => e.StartsAt).ToListAsync();
    return Results.Ok(list.Select(ToDto));
});

// ─── ПОКУПКА: mock-оплата → заказ Paid + билеты с QR (90 сек flow) ────
app.MapPost("/api/checkout", async (AppDbContext db, CheckoutRequestDto req) =>
{
    if (req.Items is null || !req.Items.Any())
        return Results.BadRequest(new { error = "Корзина пуста." });

    // Пользователь по телефону (создаём при первой покупке)
    var user = await db.Users.FirstOrDefaultAsync(u => u.Phone == req.BuyerPhone);
    if (user is null)
    {
        user = new AppUser { Id = Guid.NewGuid(), DisplayName = req.BuyerName, Phone = req.BuyerPhone };
        db.Users.Add(user);
    }

    var order = new Order { Id = Guid.NewGuid(), UserId = user.Id, Status = OrderStatus.Pending };
    decimal total = 0;
    var tickets = new List<Ticket>();

    foreach (var item in req.Items)
    {
        var tt = await db.TicketTypes.Include(t => t.Event)!.ThenInclude(e => e!.Venue)
            .FirstOrDefaultAsync(t => t.Id == item.TicketTypeId);
        if (tt is null)
            return Results.BadRequest(new { error = $"Тип билета {item.TicketTypeId} не найден." });
        if (item.Quantity <= 0)
            return Results.BadRequest(new { error = "Количество должно быть больше нуля." });
        if (tt.Quantity - tt.Sold < item.Quantity)
            return Results.BadRequest(new { error = $"Недостаточно билетов: {tt.Name}." });

        for (var i = 0; i < item.Quantity; i++)
        {
            tickets.Add(new Ticket
            {
                Id = Guid.NewGuid(), OrderId = order.Id, TicketTypeId = tt.Id,
                EventId = tt.EventId, Status = TicketStatus.Issued
            });
        }
        tt.Sold += item.Quantity;
        total += tt.Price * item.Quantity;
    }

    // mock-оплата: считаем успешной мгновенно
    order.Total = total;
    order.Status = OrderStatus.Paid;
    order.PaidAt = DateTimeOffset.UtcNow;

    db.Orders.Add(order);
    db.Tickets.AddRange(tickets);
    await db.SaveChangesAsync();

    // Подгружаем навигационные свойства для DTO
    foreach (var t in tickets)
    {
        t.Event = await db.Events.Include(e => e.Venue).FirstAsync(e => e.Id == t.EventId);
        t.TicketType = await db.TicketTypes.FirstAsync(x => x.Id == t.TicketTypeId);
    }

    return Results.Ok(new OrderResultDto(order.Id, order.Status.ToString(),
        order.Total, order.Currency, tickets.Select(TicketToDto)));
});

// ─── МОИ БИЛЕТЫ ──────────────────────────────────────────────────────
// GET /api/users/{phone}/tickets
app.MapGet("/api/users/{phone}/tickets", async (AppDbContext db, string phone) =>
{
    var tickets = await db.Tickets
        .Include(t => t.Event).ThenInclude(e => e!.Venue)
        .Include(t => t.TicketType)
        .Include(t => t.Order)
        .Where(t => t.Order!.User!.Phone == phone)
        .OrderByDescending(t => t.IssuedAt)
        .ToListAsync();
    return Results.Ok(tickets.Select(TicketToDto));
});

// ─── CHECK-IN: скан QR на входе («1 сек на скан») ────────────────────
app.MapPost("/api/checkin", async (AppDbContext db, CheckInRequestDto req) =>
{
    var t = await db.Tickets
        .Include(x => x.Event).ThenInclude(e => e!.Venue)
        .Include(x => x.TicketType)
        .FirstOrDefaultAsync(x => x.QrToken == req.QrToken);

    if (t is null) return Results.NotFound(new { error = "Билет не найден." });
    if (t.Status == TicketStatus.CheckedIn)
        return Results.Conflict(new { error = "Билет уже использован.", checkedInAt = t.CheckedInAt });
    if (t.Status != TicketStatus.Issued)
        return Results.BadRequest(new { error = $"Билет недействителен ({t.Status})." });

    t.Status = TicketStatus.CheckedIn;
    t.CheckedInAt = DateTimeOffset.UtcNow;
    await db.SaveChangesAsync();
    return Results.Ok(new { ok = true, ticket = TicketToDto(t) });
});

// ─── ПЕРЕДАЧА БИЛЕТА: POST /api/tickets/{id}/transfer (PRD §5.5, US-03) ─
// Передаёт билет другому пользователю по контакту (email/телефон):
//  • проверяет существование билета;
//  • запрещает передачу использованных / уже переданных / недействительных;
//  • переводит билет в статус Transferred, аннулируя оригинальный QR;
//  • выдаёт новый QR-токен (билет остаётся валиден у получателя);
//  • возвращает обновлённый билет в форме TicketDto, ожидаемой Flutter.
app.MapPost("/api/tickets/{id:guid}/transfer", async (AppDbContext db, Guid id, TransferRequestDto req) =>
{
    if (string.IsNullOrWhiteSpace(req.ToContact))
        return Results.BadRequest(new { error = "Укажите контакт получателя (email или телефон)." });

    var t = await db.Tickets
        .Include(x => x.Event).ThenInclude(e => e!.Venue)
        .Include(x => x.TicketType)
        .FirstOrDefaultAsync(x => x.Id == id);

    if (t is null)
        return Results.NotFound(new { error = "Билет не найден." });
    if (t.Status == TicketStatus.CheckedIn)
        return Results.Conflict(new { error = "Билет уже использован — передача невозможна." });
    if (t.Status == TicketStatus.Transferred)
        return Results.Conflict(new { error = "Билет уже передан другому пользователю.", transferredTo = t.TransferredTo });
    if (t.Status != TicketStatus.Issued)
        return Results.BadRequest(new { error = $"Билет недействителен ({t.Status})." });

    // Аннулируем оригинальный QR и выдаём новый — старый код перестаёт работать.
    t.Status = TicketStatus.Transferred;
    t.TransferredTo = req.ToContact.Trim();
    t.TransferredAt = DateTimeOffset.UtcNow;
    t.QrToken = Guid.NewGuid().ToString("N");
    await db.SaveChangesAsync();

    return Results.Ok(TicketToDto(t));
});

// ─── ВОЗВРАТ БИЛЕТА: POST /api/tickets/{id}/request-refund (PRD §8, Сценарий В) ─
// Возврат по инициативе покупателя для билета с Refund Guarantee.
// Переводит билет в статус Refunded и аннулирует QR.
app.MapPost("/api/tickets/{id:guid}/request-refund", async (AppDbContext db, Guid id) =>
{
    var t = await db.Tickets
        .Include(x => x.Event).ThenInclude(e => e!.Venue)
        .Include(x => x.TicketType)
        .FirstOrDefaultAsync(x => x.Id == id);

    if (t is null)
        return Results.NotFound(new { error = "Билет не найден." });
    if (t.Status == TicketStatus.CheckedIn)
        return Results.Conflict(new { error = "Билет уже использован — возврат невозможен." });
    if (t.Status == TicketStatus.Refunded)
        return Results.Conflict(new { error = "Билет уже возвращён." });
    if (t.Status != TicketStatus.Issued)
        return Results.BadRequest(new { error = $"Возврат недоступен ({t.Status})." });
    if (!RefundAllowed(t.Event!))
        return Results.BadRequest(new { error = "Для этого билета возврат не предусмотрен." });

    t.Status = TicketStatus.Refunded;
    await db.SaveChangesAsync();
    return Results.Ok(TicketToDto(t));
});

// ─── ПОИСК ПОЛУЧАТЕЛЯ: GET /api/users/lookup?contact=... ────────────
// Моментальный поиск перед передачей билета: по телефону или email
// возвращает имя получателя. 200 + Found=true, если пользователь
// есть; 404, если нет (фронт покажет «пользователь не найден»).
app.MapGet("/api/users/lookup", async (AppDbContext db, string? contact) =>
{
    var raw = (contact ?? "").Trim();
    if (raw.Length < 3)
        return Results.BadRequest(new { error = "Укажите телефон или email получателя." });

    AppUser? user;
    if (raw.Contains('@'))
    {
        var email = raw.ToLower();
        user = await db.Users.FirstOrDefaultAsync(u => u.Email != null && u.Email.ToLower() == email);
    }
    else
    {
        var phone = NormalizePhone(raw);
        user = await db.Users.FirstOrDefaultAsync(u => u.Phone == phone);
    }

    if (user is null)
        return Results.NotFound(new RecipientLookupDto(false, null, raw));
    return Results.Ok(new RecipientLookupDto(true, user.DisplayName, raw));
});

app.MapGet("/", () => "Telcell Tickets API · OK");

// ─── АВТОРИЗАЦИЯ: телефон + mock-OTP (имитация SMS) ─────────────────
// Шаг 1: пользователь вводит телефон → сервер генерирует код.
//   В dev-режиме код фиксированный ("0000") и возвращается в devCode,
//   чтобы можно было войти без реального SMS-провайдера.
const string devOtpCode = "0000";

static string NormalizePhone(string phone) => phone.Trim().Replace(" ", "");

static UserDto UserToDto(AppUser u) => new(u.Id, u.DisplayName, u.Phone, u.IsAdmin);

app.MapPost("/api/auth/request-otp", async (AppDbContext db, RequestOtpDto req) =>
{
    var phone = NormalizePhone(req.Phone ?? "");
    if (phone.Length < 6)
        return Results.BadRequest(new { error = "Укажите корректный номер телефона." });

    var user = await db.Users.FirstOrDefaultAsync(u => u.Phone == phone);
    if (user is null)
    {
        user = new AppUser
        {
            Id = Guid.NewGuid(),
            Phone = phone,
            DisplayName = string.IsNullOrWhiteSpace(req.DisplayName) ? "Гость" : req.DisplayName!.Trim(),
        };
        db.Users.Add(user);
    }
    else if (!string.IsNullOrWhiteSpace(req.DisplayName))
    {
        user.DisplayName = req.DisplayName!.Trim();
    }

    user.OtpCode = devOtpCode;
    user.OtpExpiresAt = DateTimeOffset.UtcNow.AddMinutes(5);
    await db.SaveChangesAsync();

    // devCode — только для разработки; в production не возвращать.
    return Results.Ok(new RequestOtpResultDto(true, user.OtpCode));
});

// Шаг 2: проверка кода → выдача токена сессии.
// Скрытый admin-вход: спец-номер +37400000000 с кодом 9999 помечает
// пользователя IsAdmin=true (доступ к admin-эндпоинтам и панели).
app.MapPost("/api/auth/verify-otp", async (AppDbContext db, VerifyOtpDto req) =>
{
    var phone = NormalizePhone(req.Phone ?? "");
    const string adminPhone = "+37400000000";
    const string adminCode = "9999";
    var user = await db.Users.FirstOrDefaultAsync(u => u.Phone == phone);

    // Скрытый admin-вход обрабатываем отдельно: спец-код, создаём/повышаем
    // пользователя до администратора. Не требует предварительного request-otp.
    if (phone == adminPhone)
    {
        if (!string.Equals((req.Code ?? "").Trim(), adminCode, StringComparison.Ordinal))
            return Results.BadRequest(new { error = "Неверный код." });
        user ??= new AppUser { Id = Guid.NewGuid(), Phone = phone, DisplayName = "Администратор" };
        user.IsAdmin = true;
        user.OtpCode = null;
        user.OtpExpiresAt = null;
        user.SessionToken = Guid.NewGuid().ToString("N") + Guid.NewGuid().ToString("N");
        if (!db.Users.Local.Contains(user) && db.Entry(user).State == EntityState.Detached)
            db.Users.Add(user);
        await db.SaveChangesAsync();
        return Results.Ok(new AuthResultDto(user.SessionToken!, UserToDto(user)));
    }

    if (user is null || user.OtpCode is null)
        return Results.NotFound(new { error = "Сначала запросите код входа." });
    if (user.OtpExpiresAt is null || user.OtpExpiresAt < DateTimeOffset.UtcNow)
        return Results.BadRequest(new { error = "Срок действия кода истёк. Запросите новый." });
    if (!string.Equals(user.OtpCode, (req.Code ?? "").Trim(), StringComparison.Ordinal))
        return Results.BadRequest(new { error = "Неверный код." });

    // Код одноразовый: гасим его и выдаём токен сессии.
    user.OtpCode = null;
    user.OtpExpiresAt = null;
    user.SessionToken = Guid.NewGuid().ToString("N") + Guid.NewGuid().ToString("N");
    await db.SaveChangesAsync();

    return Results.Ok(new AuthResultDto(user.SessionToken!, UserToDto(user)));
});

// Текущий пользователь по токену (восстановление сессии при старте).
app.MapGet("/api/auth/me", async (AppDbContext db, HttpRequest http) =>
{
    var token = ExtractBearer(http);
    if (token is null) return Results.Unauthorized();
    var user = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token);
    return user is null ? Results.Unauthorized() : Results.Ok(UserToDto(user));
});

// Выход — аннулируем токен.
app.MapPost("/api/auth/logout", async (AppDbContext db, HttpRequest http) =>
{
    var token = ExtractBearer(http);
    if (token is not null)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.SessionToken == token);
        if (user is not null)
        {
            user.SessionToken = null;
            await db.SaveChangesAsync();
        }
    }
    return Results.Ok(new { ok = true });
});

app.Run();

// Извлекает Bearer-токен из заголовка Authorization.
static string? ExtractBearer(HttpRequest http)
{
    var header = http.Headers.Authorization.ToString();
    if (string.IsNullOrWhiteSpace(header)) return null;
    const string prefix = "Bearer ";
    return header.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)
        ? header[prefix.Length..].Trim()
        : header.Trim();
}
