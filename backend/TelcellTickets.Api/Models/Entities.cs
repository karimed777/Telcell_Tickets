namespace TelcellTickets.Api.Models;

/// <summary>
/// Категория события (Concerts, Theatre, Festivals, …).
/// Соответствует EventCategory во Flutter-клиенте.
/// </summary>
public enum EventCategory
{
    Concert,
    Theatre,
    Festival,
    Conference,
    Exhibition,
    Sport,
    Other
}

/// <summary>Площадка проведения — нужна для экрана карты.</summary>
public class Venue
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string NameAm { get; set; } = "";  // Армянское название
    public string City { get; set; } = "";
    public string Address { get; set; } = "";
    public string AddressAm { get; set; } = "";  // Армянский адрес

    // Координаты для flutter_map (OSM)
    public double Latitude { get; set; }
    public double Longitude { get; set; }

    public ICollection<Event> Events { get; set; } = new List<Event>();
}

/// <summary>Событие афиши.</summary>
public class Event
{
    public Guid Id { get; set; }
    public string Title { get; set; } = "";
    public string TitleAm { get; set; } = "";  // Армянское название
    public string Description { get; set; } = "";
    public string DescriptionAm { get; set; } = "";  // Армянское описание
    public EventCategory Category { get; set; }

    public DateTimeOffset StartsAt { get; set; }

    // Обложка: цвет (HEX) для градиента-заглушки + опциональный URL картинки
    public string CoverColorHex { get; set; } = "#361268";
    public string? CoverImageUrl { get; set; }

    public Guid VenueId { get; set; }
    public Venue? Venue { get; set; }

    public ICollection<TicketType> TicketTypes { get; set; } = new List<TicketType>();

    public bool IsFeatured { get; set; }
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
}

/// <summary>Тип билета события (Standard / VIP / …) c ценой и остатком.</summary>
public class TicketType
{
    public Guid Id { get; set; }
    public string Name { get; set; } = "";
    public string NameAm { get; set; } = "";  // Армянское название
    public decimal Price { get; set; }          // в AMD
    public string Currency { get; set; } = "AMD";
    public int Quantity { get; set; }           // всего мест
    public int Sold { get; set; }               // продано

    public int Available => Quantity - Sold;

    public Guid EventId { get; set; }
    public Event? Event { get; set; }
}

/// <summary>Покупатель / зарегистрированный пользователь.</summary>
public class AppUser
{
    public Guid Id { get; set; }
    public string DisplayName { get; set; } = "";
    public string Phone { get; set; } = "";
    public string? Email { get; set; }
    public string City { get; set; } = "Yerevan";
    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    // Роль администратора — даёт доступ к admin-эндпоинтам (создание
    // мероприятий, модерация). Выдаётся через скрытый вход.
    public bool IsAdmin { get; set; }

    // ── Авторизация по телефону + mock-OTP (имитация SMS) ──────────────
    // Код последнего запрошенного входа и срок его действия. В реальном
    // проекте сюда подключается SMS-провайдер; здесь код фиксированный
    // (см. Program.cs) и возвращается в ответе для удобства разработки.
    public string? OtpCode { get; set; }
    public DateTimeOffset? OtpExpiresAt { get; set; }

    // Опаковый токен сессии — выдаётся после успешной проверки OTP и
    // используется клиентом в заголовке Authorization для всех запросов.
    public string? SessionToken { get; set; }

    public ICollection<Ticket> Tickets { get; set; } = new List<Ticket>();
}

public enum TicketStatus
{
    Issued,      // оплачен, действителен
    CheckedIn,   // прошёл вход (скан QR)
    Transferred, // передан другому пользователю — QR оригинала аннулирован
    Refunded,
    Cancelled
}

/// <summary>Купленный билет с QR-токеном.</summary>
public class Ticket
{
    public Guid Id { get; set; }

    public Guid OrderId { get; set; }
    public Order? Order { get; set; }

    public Guid TicketTypeId { get; set; }
    public TicketType? TicketType { get; set; }

    public Guid EventId { get; set; }
    public Event? Event { get; set; }

    // QR-токен — то, что кодируется в QR и сканируется на входе (метрика «1 сек на скан»)
    public string QrToken { get; set; } = Guid.NewGuid().ToString("N");

    public TicketStatus Status { get; set; } = TicketStatus.Issued;
    public DateTimeOffset IssuedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? CheckedInAt { get; set; }

    // Кому передан билет (email/телефон получателя), если Status == Transferred.
    public string? TransferredTo { get; set; }
    public DateTimeOffset? TransferredAt { get; set; }
}

public enum OrderStatus
{
    Pending,
    Paid,       // mock-оплата прошла
    Failed,
    Refunded
}

/// <summary>Заказ — корзина покупки (метрика «90 сек на покупку»).</summary>
public class Order
{
    public Guid Id { get; set; }

    public Guid UserId { get; set; }
    public AppUser? User { get; set; }

    public decimal Total { get; set; }
    public string Currency { get; set; } = "AMD";
    public OrderStatus Status { get; set; } = OrderStatus.Pending;

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;
    public DateTimeOffset? PaidAt { get; set; }

    public ICollection<Ticket> Tickets { get; set; } = new List<Ticket>();
}
