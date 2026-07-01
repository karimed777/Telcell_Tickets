using TelcellTickets.Api.Models;

namespace TelcellTickets.Api.Dtos;

// ─── Ответы ───────────────────────────────────────────────────────────

public record VenueDto(Guid Id, string Name, string NameAm, string City, string Address, string AddressAm, double Latitude, double Longitude);

public record TicketTypeDto(Guid Id, string Name, string NameAm, decimal Price, string Currency, int Available);

public record EventDto(
    Guid Id,
    string Title,
    string TitleAm,
    string Description,
    string DescriptionAm,
    string Category,
    DateTimeOffset StartsAt,
    string CoverColorHex,
    string? CoverImageUrl,
    bool IsFeatured,
    VenueDto Venue,
    IEnumerable<TicketTypeDto> TicketTypes,
    decimal MinPrice,
    // Refund Guarantee (PRD §8, Сценарий В): можно ли вернуть билет.
    bool RefundGuarantee = false,
    int RefundUntilHours = 24);

public record TicketDto(
    Guid Id,
    Guid EventId,
    string EventTitle,
    DateTimeOffset StartsAt,
    string VenueName,
    string TicketTypeName,
    decimal Price,
    string Currency,
    string QrToken,
    string Status,
    DateTimeOffset IssuedAt,
    string? TransferredTo = null,
    // Возврат разрешён для этого билета (наследуется от события).
    bool RefundGuarantee = false,
    int RefundUntilHours = 24);

public record OrderResultDto(Guid OrderId, string Status, decimal Total, string Currency, IEnumerable<TicketDto> Tickets);

// ─── Запросы ──────────────────────────────────────────────────────────

/// <summary>Покупка: список (тип билета + количество) + покупатель.</summary>
public record CheckoutItemDto(Guid TicketTypeId, int Quantity);

public record CheckoutRequestDto(
    string BuyerName,
    string BuyerPhone,
    IEnumerable<CheckoutItemDto> Items);

public record CheckInRequestDto(string QrToken);

/// <summary>Передача билета другому пользователю (PRD §5.5, US-03).</summary>
public record TransferRequestDto(string ToContact);

/// <summary>Результат поиска получателя по контакту (телефон или email)
/// для передачи билета. Found=false означает, что такого
/// пользователя нет — передача невозможна (q_recipient_lookup:
/// показываем «пользователь не найден»).</summary>
public record RecipientLookupDto(bool Found, string? DisplayName, string Contact);

// ─── Авторизация (телефон + mock-OTP) ─────────────────────────────────

/// <summary>Запрос на отправку кода входа на телефон.</summary>
public record RequestOtpDto(string Phone, string? DisplayName = null);

/// <summary>Ответ на запрос кода. В dev-режиме код возвращается в devCode,
/// чтобы войти без реального SMS.</summary>
public record RequestOtpResultDto(bool Sent, string? DevCode = null);

/// <summary>Проверка кода и выдача сессии.</summary>
public record VerifyOtpDto(string Phone, string Code);

/// <summary>Профиль пользователя для клиента. IsAdmin=true только
/// для скрытого admin-входа — открывает админ-панель на клиенте.</summary>
public record UserDto(Guid Id, string DisplayName, string Phone, bool IsAdmin = false);

/// <summary>Результат входа: токен сессии + профиль.</summary>
public record AuthResultDto(string Token, UserDto User);
