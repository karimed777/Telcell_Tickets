namespace TelcellTickets.Api.Models;

// ════════════════════════════════════════════════════════════════════════
//  СХЕМЫ ЗАЛОВ (Seating Plan)
//  Часть 1 — доменные сущности. Делятся на две ветки:
//   1) Шаблоны залов (VenueLayout → VenueFloor → SeatBlock → Seat, + Stage)
//      — редактируются в веб-админке, переиспользуются между событиями.
//   2) Схема конкретного мероприятия (EventLayout → EventFloor →
//      EventSeatBlock → EventSeat, + EventStage) — ПОЛНАЯ КОПИЯ шаблона,
//      снятая в момент привязки к событию. Копия, а не ссылка: правка
//      шаблона не ломает уже созданные события. EventSeat дополнительно
//      несёт реалтайм-статус (Available/Reserved/Sold).
//  SeatReservation — лог активных резерваций для WebSocket (Часть 2).
// ════════════════════════════════════════════════════════════════════════

/// <summary>Тип кресла. Общий для шаблона и события.</summary>
public enum SeatType
{
    Standard,
    VIP,
    Sofa,
    Standing,
    Disabled
}

/// <summary>Реалтайм-статус места в схеме конкретного мероприятия.</summary>
public enum SeatStatus
{
    Available,
    Reserved,
    Sold
}

// ─────────────────────────────────────────────────────────────────────────
//  ВЕТКА 1 — ШАБЛОНЫ ЗАЛОВ
// ─────────────────────────────────────────────────────────────────────────

/// <summary>Шаблон зала, привязанный к площадке (Venue). Переиспользуется.</summary>
public class VenueLayout
{
    public Guid Id { get; set; }

    public Guid VenueId { get; set; }
    public Venue? Venue { get; set; }

    /// <summary>Название шаблона для поиска ("Большой зал", "Летняя сцена").</summary>
    public string Name { get; set; } = "";

    public DateTimeOffset CreatedAt { get; set; } = DateTimeOffset.UtcNow;

    public ICollection<VenueFloor> Floors { get; set; } = new List<VenueFloor>();
}

/// <summary>Этаж/уровень внутри шаблона зала.</summary>
public class VenueFloor
{
    public Guid Id { get; set; }

    public Guid VenueLayoutId { get; set; }
    public VenueLayout? VenueLayout { get; set; }

    /// <summary>Название этажа ("Партер", "Балкон", "Этаж 1").</summary>
    public string Name { get; set; } = "";

    /// <summary>Порядок отображения вкладок этажей.</summary>
    public int Order { get; set; }

    public ICollection<SeatBlock> SeatBlocks { get; set; } = new List<SeatBlock>();

    /// <summary>Обязательная сцена этажа (один Stage на этаж).</summary>
    public Stage? Stage { get; set; }
}

/// <summary>Прямоугольный блок кресел на холсте (шаблон).</summary>
public class SeatBlock
{
    public Guid Id { get; set; }

    public Guid VenueFloorId { get; set; }
    public VenueFloor? VenueFloor { get; set; }

    public SeatType SeatType { get; set; } = SeatType.Standard;
    public decimal DefaultPrice { get; set; }
    public string? DefaultDescription { get; set; }
    public string DefaultColor { get; set; } = "#6C63FF";

    /// <summary>Позиция центра блока на холсте.</summary>
    public double CanvasX { get; set; }
    public double CanvasY { get; set; }

    /// <summary>Произвольный угол поворота блока, градусы.</summary>
    public double RotationDeg { get; set; }

    public int Rows { get; set; }
    public int SeatsPerRow { get; set; }

    public ICollection<Seat> Seats { get; set; } = new List<Seat>();
}

/// <summary>Отдельное кресло шаблона.</summary>
public class Seat
{
    public Guid Id { get; set; }

    public Guid SeatBlockId { get; set; }
    public SeatBlock? SeatBlock { get; set; }

    /// <summary>Сквозная нумерация по всему залу (считается автоматически).</summary>
    public int Row { get; set; }
    public int Number { get; set; }

    /// <summary>Может отличаться от блока, если переопределено вручную.</summary>
    public SeatType SeatType { get; set; } = SeatType.Standard;
    public decimal Price { get; set; }
    public string? Description { get; set; }
    public string Color { get; set; } = "#6C63FF";

    /// <summary>Абсолютная позиция на холсте (пересчитывается при move/rotate).</summary>
    public double CanvasX { get; set; }
    public double CanvasY { get; set; }

    /// <summary>false = кресло удалено, но запись сохранена.</summary>
    public bool IsActive { get; set; } = true;
}

/// <summary>Обязательная сцена на этаже (один Stage на VenueFloor).</summary>
public class Stage
{
    public Guid Id { get; set; }

    public Guid VenueFloorId { get; set; }
    public VenueFloor? VenueFloor { get; set; }

    public double CanvasX { get; set; }
    public double CanvasY { get; set; }
    public double Width { get; set; }
    public double Height { get; set; }

    public string Label { get; set; } = "СЦЕНА";
}

// ─────────────────────────────────────────────────────────────────────────
//  ВЕТКА 2 — СХЕМА КОНКРЕТНОГО МЕРОПРИЯТИЯ (копия шаблона + реалтайм)
// ─────────────────────────────────────────────────────────────────────────

/// <summary>Связь события со схемой зала. Один EventLayout на Event.</summary>
public class EventLayout
{
    public Guid Id { get; set; }

    public Guid EventId { get; set; }
    public Event? Event { get; set; }

    /// <summary>Шаблон-источник, из которого скопированы данные (может быть null,
    /// если схема создана для события с нуля).</summary>
    public Guid? VenueLayoutId { get; set; }
    public VenueLayout? VenueLayout { get; set; }

    /// <summary>true = схема зала; false = старые «плюсики» (TicketType).</summary>
    public bool HasSeatingPlan { get; set; }

    public ICollection<EventFloor> Floors { get; set; } = new List<EventFloor>();
}

/// <summary>Этаж в схеме события (копия VenueFloor).</summary>
public class EventFloor
{
    public Guid Id { get; set; }

    public Guid EventLayoutId { get; set; }
    public EventLayout? EventLayout { get; set; }

    public string Name { get; set; } = "";
    public int Order { get; set; }

    public ICollection<EventSeatBlock> SeatBlocks { get; set; } = new List<EventSeatBlock>();
    public EventStage? Stage { get; set; }
}

/// <summary>Блок кресел в схеме события (копия SeatBlock).</summary>
public class EventSeatBlock
{
    public Guid Id { get; set; }

    public Guid EventFloorId { get; set; }
    public EventFloor? EventFloor { get; set; }

    public SeatType SeatType { get; set; } = SeatType.Standard;
    public decimal DefaultPrice { get; set; }
    public string? DefaultDescription { get; set; }
    public string DefaultColor { get; set; } = "#6C63FF";

    public double CanvasX { get; set; }
    public double CanvasY { get; set; }
    public double RotationDeg { get; set; }

    public int Rows { get; set; }
    public int SeatsPerRow { get; set; }

    public ICollection<EventSeat> Seats { get; set; } = new List<EventSeat>();
}

/// <summary>Кресло в схеме события (копия Seat + реалтайм-статус).</summary>
public class EventSeat
{
    public Guid Id { get; set; }

    public Guid EventSeatBlockId { get; set; }
    public EventSeatBlock? EventSeatBlock { get; set; }

    public int Row { get; set; }
    public int Number { get; set; }

    public SeatType SeatType { get; set; } = SeatType.Standard;
    public decimal Price { get; set; }
    public string? Description { get; set; }
    public string Color { get; set; } = "#6C63FF";

    public double CanvasX { get; set; }
    public double CanvasY { get; set; }

    public bool IsActive { get; set; } = true;

    // ── Реалтайм (WebSocket, Часть 2) ──────────────────────────────────
    public SeatStatus Status { get; set; } = SeatStatus.Available;

    /// <summary>Кто держит резерв (для авторизованного покупателя).</summary>
    public Guid? ReservedByUserId { get; set; }

    /// <summary>Начало резервации (для истечения через 5 минут).</summary>
    public DateTimeOffset? ReservedAt { get; set; }

    /// <summary>Заказ, к которому место привязано после оплаты.</summary>
    public Guid? OrderId { get; set; }
}

/// <summary>Сцена в схеме события (копия Stage).</summary>
public class EventStage
{
    public Guid Id { get; set; }

    public Guid EventFloorId { get; set; }
    public EventFloor? EventFloor { get; set; }

    public double CanvasX { get; set; }
    public double CanvasY { get; set; }
    public double Width { get; set; }
    public double Height { get; set; }

    public string Label { get; set; } = "СЦЕНА";
}

// ─────────────────────────────────────────────────────────────────────────
//  ЛОГ РЕЗЕРВАЦИЙ (для WebSocket и фонового освобождения)
// ─────────────────────────────────────────────────────────────────────────

/// <summary>Активная резервация места. SessionId — id сессии покупателя
/// (не userId), чтобы механика работала и до полной авторизации.</summary>
public class SeatReservation
{
    public Guid Id { get; set; }

    /// <summary>Уникальный ID сессии покупателя (WebSocket-соединения).</summary>
    public string SessionId { get; set; } = "";

    public Guid EventSeatId { get; set; }
    public EventSeat? EventSeat { get; set; }

    public DateTimeOffset ReservedAt { get; set; } = DateTimeOffset.UtcNow;

    /// <summary>ReservedAt + 5 минут. Фоновый сервис освобождает истёкшие.</summary>
    public DateTimeOffset ExpiresAt { get; set; }
}
