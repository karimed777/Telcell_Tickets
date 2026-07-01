import 'dart:async';

import '../models/event.dart';

/// Контракт билетного API. Реализуется двумя способами:
///  - [MockTicketsApi] — локальные демо-данные (сейчас).
///  - HttpTicketsApi — обращение к C#/.NET backend (когда появится).
///
/// Экраны зависят ТОЛЬКО от этого интерфейса, поэтому переключение
/// на реальный бэкенд не потребует переписывать UI.
abstract class TicketsApi {
  /// Каталог событий. [category] — ключ категории ('all' = без фильтра),
  /// [query] — поисковая строка.
  Future<List<Event>> fetchEvents({String category = 'all', String query = ''});

  /// Одно событие по id.
  Future<Event> fetchEvent(String id);

  /// Билеты текущего пользователя.
  Future<List<OwnedTicket>> fetchMyTickets();

  /// Оформление заказа. Возвращает созданные билеты.
  /// На реальном бэке здесь будет POST /orders.
  ///
  /// [email] и [phone] — контакт покупателя. Для Guest Checkout (PRD §11.2)
  /// это единственные обязательные поля; для Telcell Wallet приходят из
  /// авторизации.
  Future<List<OwnedTicket>> checkout({
    required String eventId,
    required Map<String, int> quantities,
    required PaymentMethod method,
    String? promoCode,
    String? email,
    String? phone,
  });

  /// Передача билета другому пользователю (PRD §5.5, US-03).
  /// QR оригинального владельца аннулируется, билет получает статус
  /// [TicketStatus.transferred]. Возвращает обновлённый билет.
  Future<OwnedTicket> transferTicket({
    required String ticketId,
    required String toContact,
  });

  /// Моментальный поиск получателя перед передачей билета.
  /// По контакту ([contact] — телефон или email) возвращает
  /// имя получателя, если такой пользователь есть, либо
  /// [RecipientLookup] с found=false. Используется для показа имени
  /// и подтверждения до фактической передачи.
  Future<RecipientLookup> lookupRecipient(String contact);

  /// Реакция покупателя на перенос события (Задача 4): подтвердить
  /// участие на новую дату. Билет переходит в [TicketStatus.rescheduledConfirmed].
  Future<OwnedTicket> confirmReschedule(String ticketId);

  /// Реакция покупателя на отмену/перенос (Задача 4): запросить
  /// возврат. Билет переходит в [TicketStatus.refunded].
  Future<OwnedTicket> requestRefund(String ticketId);
}

enum PaymentMethod { wallet, card }

/// Результат поиска получателя перед передачей билета.
/// [found] — есть ли такой пользователь; [displayName] — его имя
/// (не null при found==true); [contact] — нормализованный контакт.
class RecipientLookup {
  final bool found;
  final String? displayName;
  final String contact;
  const RecipientLookup({
    required this.found,
    required this.contact,
    this.displayName,
  });
}

/// Жизненный цикл билета (PRD §5.5):
/// оплачен → использован / передан / возвращён / аннулирован.
///
/// Сценарии отмены/переноса события (Задача 4):
///  - [eventCancelled] — событие отменено, оформляется авто-возврат;
///  - [rescheduledPending] — событие перенесено, покупатель ещё не решил;
///  - [rescheduledConfirmed] — покупатель подтвердил участие на новую дату.
enum TicketStatus {
  paid,
  used,
  transferred,
  refunded,
  cancelled,
  eventCancelled,
  rescheduledPending,
  rescheduledConfirmed,
}

extension TicketStatusX on TicketStatus {
  /// QR действителен для прохода, пока билет активен. При переносе
  /// (pending/confirmed) билет остаётся действительным на новую дату
  /// (opt-out: даже без ответа). Недействителен при отмене/возврате.
  bool get qrValid =>
      this == TicketStatus.paid ||
      this == TicketStatus.rescheduledPending ||
      this == TicketStatus.rescheduledConfirmed;

  /// Билет требует внимания пользователя (перенос ждёт решения).
  bool get needsDecision => this == TicketStatus.rescheduledPending;
}

/// Сервисный сбор покупателя (booking fee, PRD §9.1) и расчёт стоимости.
/// На моках ставка фиксирована; на реальном бэке приходит с сервера
/// (настраивается Investor на уровне платформы/события).
class Fees {
  const Fees._();

  /// Ставка booking fee (2% от стоимости билетов).
  static const double bookingRate = 0.02;

  /// Сервисный сбор от суммы билетов.
  static int bookingFee(int subtotal) => (subtotal * bookingRate).round();

  /// Полная стоимость к оплате (PRD §9.3 — покупатель видит её до оплаты).
  static int grandTotal(int subtotal) => subtotal + bookingFee(subtotal);
}

/// Купленный билет (привязка события + типа + динамического QR-токена).
class OwnedTicket {
  final String id;
  final Event event;
  final String ticketTypeName;

  /// Серверный токен для динамического QR (PRD §5.5 Digital Ticket).
  final String qrToken;

  /// Текущий статус билета в его жизненном цикле.
  final TicketStatus status;

  /// Кому передан билет (email/телефон), если [status] == transferred.
  final String? transferredTo;

  const OwnedTicket({
    required this.id,
    required this.event,
    required this.ticketTypeName,
    required this.qrToken,
    this.status = TicketStatus.paid,
    this.transferredTo,
  });

  OwnedTicket copyWith({TicketStatus? status, String? transferredTo, Event? event}) {
    return OwnedTicket(
      id: id,
      event: event ?? this.event,
      ticketTypeName: ticketTypeName,
      qrToken: qrToken,
      status: status ?? this.status,
      transferredTo: transferredTo ?? this.transferredTo,
    );
  }
}

/// Демо-реализация на моках. Имитирует сетевую задержку,
/// чтобы UI сразу был готов к асинхронности.
///
/// Купленные билеты хранятся в памяти ([_owned]) и поэтому остаются
/// в разделе «Мои билеты» после покупки (в рамках сессии приложения).
class MockTicketsApi implements TicketsApi {
  static const _delay = Duration(milliseconds: 350);

  /// Билеты, купленные пользователем в этой сессии (новейшие — в конце).
  final List<OwnedTicket> _owned = [];

  @override
  Future<List<Event>> fetchEvents({
    String category = 'all',
    String query = '',
  }) async {
    await Future<void>.delayed(_delay);
    final q = query.trim().toLowerCase();
    return MockData.events.where((e) {
      final byCat = category == 'all' || e.category.key == category;
      // Поиск только по названию события (RU + AM), не по площадке.
      final byText = q.isEmpty ||
          e.title.toLowerCase().contains(q) ||
          e.titleAm.toLowerCase().contains(q);
      return byCat && byText;
    }).toList();
  }

  @override
  Future<Event> fetchEvent(String id) async {
    await Future<void>.delayed(_delay);
    return MockData.events.firstWhere((e) => e.id == id);
  }

  @override
  Future<List<OwnedTicket>> fetchMyTickets() async {
    await Future<void>.delayed(_delay);
    // Новейшие билеты — сверху списка.
    return _owned.reversed.toList();
  }

  @override
  Future<List<OwnedTicket>> checkout({
    required String eventId,
    required Map<String, int> quantities,
    required PaymentMethod method,
    String? promoCode,
    String? email,
    String? phone,
  }) async {
    await Future<void>.delayed(_delay);
    final event = MockData.events.firstWhere((e) => e.id == eventId);
    final result = <OwnedTicket>[];
    quantities.forEach((typeName, qty) {
      for (var i = 0; i < qty; i++) {
        final stamp = DateTime.now().microsecondsSinceEpoch;
        result.add(OwnedTicket(
          id: 'TT-${stamp.toString().substring(6)}',
          event: event,
          ticketTypeName: typeName,
          qrToken: 'demo-$eventId-$typeName-$i-$stamp',
        ));
      }
    });
    // Сохраняем покупку, чтобы билеты остались в «Мои билеты».
    _owned.addAll(result);
    return result;
  }

  @override
  Future<OwnedTicket> transferTicket({
    required String ticketId,
    required String toContact,
  }) async {
    await Future<void>.delayed(_delay);
    final i = _owned.indexWhere((t) => t.id == ticketId);
    if (i == -1) {
      throw StateError('{"error": "Билет не найден."}');
    }
    final current = _owned[i];
    // Зеркалим проверки backend: передавать можно только активный билет.
    if (current.status == TicketStatus.used) {
      throw StateError('{"error": "Билет уже использован — передача невозможна."}');
    }
    if (current.status == TicketStatus.transferred) {
      throw StateError('{"error": "Билет уже передан другому пользователю."}');
    }
    if (current.status != TicketStatus.paid) {
      throw StateError('{"error": "Билет недействителен."}');
    }
    // QR оригинального владельца аннулируется (US-03): билет переходит
    // в статус transferred и больше не действителен для прохода.
    final updated = current.copyWith(
      status: TicketStatus.transferred,
      transferredTo: toContact,
    );
    _owned[i] = updated;
    return updated;
  }

  /// Демо-реестр «известных» пользователей для поиска получателя.
  /// На реальном бэкенде это таблица AppUser; здесь — фиксированный
  /// набор, чтобы UI поиска работал и без сервера. Ключ —
  /// нормализованный контакт (телефон без пробелов / email в lower).
  static final Map<String, String> _knownUsers = {
    '+37491234567': 'Арам Петросян',
    '+37498765432': 'Лилит Аветисян',
    '+37477111222': 'Давид Саргсян',
    'aram@telcell.am': 'Арам Петросян',
    'lilit@telcell.am': 'Лилит Аветисян',
  };

  static String _normContact(String c) => c.trim().contains('@')
      ? c.trim().toLowerCase()
      : c.trim().replaceAll(' ', '');

  /// Регистрирует вошедшего пользователя в справочнике получателей,
  /// чтобы ему можно было передать билет (mock-режим). Вызывается при
  /// успешном входе. На реальном бэкенде поиск идёт через /api/users/lookup.
  static void registerKnownUser(String contact, String name) {
    final key = _normContact(contact);
    if (key.isEmpty) return;
    _knownUsers[key] = name.trim().isEmpty ? 'Пользователь' : name.trim();
  }

  @override
  Future<RecipientLookup> lookupRecipient(String contact) async {
    await Future<void>.delayed(_delay);
    final key = _normContact(contact);
    final name = _knownUsers[key];
    return RecipientLookup(
      found: name != null,
      displayName: name,
      contact: key,
    );
  }

  @override
  Future<OwnedTicket> confirmReschedule(String ticketId) async {
    await Future<void>.delayed(_delay);
    final i = _owned.indexWhere((t) => t.id == ticketId);
    if (i == -1) {
      throw StateError('{"error": "Билет не найден."}');
    }
    final current = _owned[i];
    if (current.status != TicketStatus.rescheduledPending) {
      throw StateError(
          '{"error": "Подтвердить участие можно только для перенесённого события."}');
    }
    final updated = current.copyWith(status: TicketStatus.rescheduledConfirmed);
    _owned[i] = updated;
    return updated;
  }

  @override
  Future<OwnedTicket> requestRefund(String ticketId) async {
    await Future<void>.delayed(_delay);
    final i = _owned.indexWhere((t) => t.id == ticketId);
    if (i == -1) {
      throw StateError('{"error": "Билет не найден."}');
    }
    final current = _owned[i];
    // Возврат доступен при переносе/отмене события, а также для обычного
    // оплаченного билета, если организатор включил Refund Guarantee (PRD §8).
    final ok = current.status == TicketStatus.rescheduledPending ||
        current.status == TicketStatus.eventCancelled ||
        (current.status == TicketStatus.paid &&
            current.event.refundGuarantee);
    if (!ok) {
      throw StateError(
          '{"error": "Возврат недоступен для этого билета."}');
    }
    final updated = current.copyWith(status: TicketStatus.refunded);
    _owned[i] = updated;
    return updated;
  }

  // ─── Демо-хуки: отмена/перенос события (Задача 4 ↔ админка) ────────
  // Позволяют в mock-режиме проиграть отмену/перенос и увидеть
  // реакцию на экране «Мои билеты» без backend.

  /// Отменить событие: все активные билеты → eventCancelled.
  void debugCancelEvent(String eventId) {
    for (var i = 0; i < _owned.length; i++) {
      final t = _owned[i];
      if (t.event.id == eventId && t.status == TicketStatus.paid) {
        _owned[i] = t.copyWith(
          status: TicketStatus.eventCancelled,
          event: t.event.copyWith(status: EventStatus.cancelled),
        );
      }
    }
  }

  /// Перенести событие: активные билеты → rescheduledPending (72ч).
  void debugRescheduleEvent(String eventId, DateTime newDate) {
    final deadline = DateTime.now().add(const Duration(hours: 72));
    for (var i = 0; i < _owned.length; i++) {
      final t = _owned[i];
      if (t.event.id == eventId && t.status == TicketStatus.paid) {
        _owned[i] = t.copyWith(
          status: TicketStatus.rescheduledPending,
          event: t.event.copyWith(
            status: EventStatus.rescheduled,
            newDate: newDate,
            decisionDeadline: deadline,
          ),
        );
      }
    }
  }
}

/// Единая точка доступа к API.
///
/// По умолчанию — [MockTicketsApi] (работает без бэкенда).
/// Чтобы переключиться на реальный C# backend, в main.dart (или где
/// удобно) присвой:
///
///   Api.instance = HttpTicketsApi(baseUrl: 'http://localhost:5000');
///
/// Вся логика обязана работать одинаково в обоих режимах.
class Api {
  Api._();
  static TicketsApi instance = MockTicketsApi();
}
