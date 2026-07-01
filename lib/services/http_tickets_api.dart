import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/event.dart';
import 'tickets_api.dart';

/// Реализация [TicketsApi] поверх C# / .NET backend (PostgreSQL).
///
/// Чтобы переключить приложение с моков на реальный бэкенд,
/// в main.dart (или где удобно) задай:
///
///   Api.instance = HttpTicketsApi(baseUrl: 'http://localhost:5000');
///
/// Для Android-эмулятора используй http://10.0.2.2:5000.
class HttpTicketsApi implements TicketsApi {
  final String baseUrl;
  final http.Client _client;

  /// Телефон текущего пользователя — для «Мои билеты» и checkout.
  /// Заполняется из сессии (вход по телефону) через [setIdentity];
  /// для гостя остаётся дефолтным, а контакт приходит из формы checkout.
  String buyerPhone;
  String buyerName;

  /// Токен сессии вошедшего пользователя (Bearer). null у гостя.
  String? authToken;

  HttpTicketsApi({
    required this.baseUrl,
    this.buyerPhone = '+37400000000',
    this.buyerName = 'Гость',
    this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Обновляет личность покупателя из сессии. Вызывается после входа
  /// и после выхода, чтобы билеты/заказы привязывались к нужному userId.
  void setIdentity({String? phone, String? name, String? token}) {
    if (phone != null && phone.isNotEmpty) buyerPhone = phone;
    if (name != null && name.isNotEmpty) buyerName = name;
    authToken = token;
  }

  Map<String, String> _headers([Map<String, String>? extra]) {
    final h = <String, String>{...?extra};
    if (authToken != null) h['Authorization'] = 'Bearer $authToken';
    return h;
  }

  Uri _u(String path, [Map<String, String>? q]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: q);

  // ─── СОБЫТИЯ ────────────────────────────────────────────────────────
  @override
  Future<List<Event>> fetchEvents({
    String category = 'all',
    String query = '',
  }) async {
    final params = <String, String>{};
    if (category != 'all') params['category'] = _toApiCategory(category);
    if (query.trim().isNotEmpty) params['q'] = query.trim();

    final res = await _client.get(_u('/api/events', params));
    _ensureOk(res);
    final data = jsonDecode(res.body) as List<dynamic>;
    return data.map((e) => _eventFromJson(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Event> fetchEvent(String id) async {
    final res = await _client.get(_u('/api/events/$id'));
    _ensureOk(res);
    return _eventFromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ─── МОИ БИЛЕТЫ ─────────────────────────────────────────────────────
  @override
  Future<List<OwnedTicket>> fetchMyTickets() async {
    final res = await _client.get(_u('/api/users/$buyerPhone/tickets'), headers: _headers());
    _ensureOk(res);
    final data = jsonDecode(res.body) as List<dynamic>;
    return data
        .map((t) => _ticketFromJson(t as Map<String, dynamic>))
        .toList();
  }

  // ─── ПОКУПКА (mock-оплата на сервере) ───────────────────────────────
  @override
  Future<List<OwnedTicket>> checkout({
    required String eventId,
    required Map<String, int> quantities,
    required PaymentMethod method,
    String? promoCode,
    String? email,
    String? phone,
  }) async {
    // Нужны id типов билетов; запрос события заполняет _ticketTypeIds.
    await fetchEvent(eventId);
    final items = <Map<String, dynamic>>[];
    quantities.forEach((typeName, qty) {
      if (qty <= 0) return;
      final id = _ticketTypeIds[typeName];
      if (id != null) items.add({'ticketTypeId': id, 'quantity': qty});
    });

    final body = jsonEncode({
      'buyerName': buyerName,
      // Guest Checkout: контакт из формы имеет приоритет над дефолтным.
      'buyerPhone': phone ?? buyerPhone,
      'buyerEmail': email,
      'paymentMethod': method.name,
      'promoCode': promoCode,
      'items': items,
    });

    final res = await _client.post(
      _u('/api/checkout'),
      headers: _headers({'Content-Type': 'application/json'}),
      body: body,
    );
    _ensureOk(res);
    final result = jsonDecode(res.body) as Map<String, dynamic>;
    final tickets = (result['tickets'] as List<dynamic>);
    return tickets
        .map((t) => _ticketFromJson(t as Map<String, dynamic>))
        .toList();
  }

  // ─── ПЕРЕДАЧА БИЛЕТА ────────────────────────────────────────────────
  @override
  Future<OwnedTicket> transferTicket({
    required String ticketId,
    required String toContact,
  }) async {
    final res = await _client.post(
      _u('/api/tickets/$ticketId/transfer'),
      headers: _headers({'Content-Type': 'application/json'}),
      body: jsonEncode({'toContact': toContact}),
    );
    _ensureOk(res);
    return _ticketFromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ─── ПОИСК ПОЛУЧАТЕЛЯ ────────────────────────────────────────
  @override
  Future<RecipientLookup> lookupRecipient(String contact) async {
    final res = await _client.get(
      _u('/api/users/lookup', {'contact': contact.trim()}),
      headers: _headers(),
    );
    // 404 — валидный ответ «пользователь не найден», не ошибка.
    if (res.statusCode == 404) {
      return RecipientLookup(found: false, contact: contact.trim());
    }
    _ensureOk(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return RecipientLookup(
      found: j['found'] as bool? ?? false,
      displayName: j['displayName'] as String?,
      contact: j['contact'] as String? ?? contact.trim(),
    );
  }

  // ─── ОТМЕНА / ПЕРЕНОС: реакция покупателя (Задача 4)
  @override
  Future<OwnedTicket> confirmReschedule(String ticketId) async {
    final res = await _client.post(
      _u('/api/tickets/$ticketId/confirm-reschedule'),
      headers: _headers({'Content-Type': 'application/json'}),
    );
    _ensureOk(res);
    return _ticketFromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  @override
  Future<OwnedTicket> requestRefund(String ticketId) async {
    final res = await _client.post(
      _u('/api/tickets/$ticketId/request-refund'),
      headers: _headers({'Content-Type': 'application/json'}),
    );
    _ensureOk(res);
    return _ticketFromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  // ─── Маппинг JSON → модели ──────────────────────────────────────────

  /// id типов билетов из последнего загруженного события (typeName -> guid).
  final Map<String, String> _ticketTypeIds = {};

  Event _eventFromJson(Map<String, dynamic> j) {
    final venue = j['venue'] as Map<String, dynamic>;
    final types = (j['ticketTypes'] as List<dynamic>);
    _ticketTypeIds.clear();
    for (final t in types) {
      _ticketTypeIds[t['name'] as String] = t['id'] as String;
    }
    return Event(
      id: j['id'] as String,
      title: j['title'] as String,
      titleAm: j['titleAm'] as String? ?? j['title'] as String,
      venue: venue['name'] as String,
      venueAm: venue['nameAm'] as String? ?? venue['name'] as String,
      city: venue['city'] as String,
      lat: (venue['latitude'] as num).toDouble(),
      lng: (venue['longitude'] as num).toDouble(),
      date: DateTime.parse(j['startsAt'] as String).toLocal(),
      category: _fromApiCategory(j['category'] as String),
      priceFrom: (j['minPrice'] as num).round(),
      cover: _hexToColor(j['coverColorHex'] as String? ?? '#361268'),
      description: j['description'] as String? ?? '',
      descriptionAm: j['descriptionAm'] as String? ?? j['description'] as String? ?? '',
      featured: j['isFeatured'] as bool? ?? false,
      refundGuarantee: j['refundGuarantee'] as bool? ?? false,
      refundUntilHours: (j['refundUntilHours'] as num?)?.toInt() ?? 24,
      status: _eventStatusFromApi(j['status'] as String?),
      newDate: j['newStartsAt'] != null
          ? DateTime.parse(j['newStartsAt'] as String).toLocal()
          : null,
      decisionDeadline: j['decisionDeadline'] != null
          ? DateTime.parse(j['decisionDeadline'] as String).toLocal()
          : null,
      ticketTypes: types
          .map((t) => TicketType(
                name: t['name'] as String,
                nameAm: t['nameAm'] as String? ?? t['name'] as String,
                price: (t['price'] as num).round(),
                note: 'Осталось: ${t['available']}',
              ))
          .toList(),
    );
  }

  OwnedTicket _ticketFromJson(Map<String, dynamic> j) {
    final stub = Event(
      id: j['eventId'] as String,
      title: j['eventTitle'] as String,
      titleAm: j['eventTitleAm'] as String? ?? j['eventTitle'] as String, // Fallback to Russian
      venue: j['venueName'] as String,
      venueAm: j['venueNameAm'] as String? ?? j['venueName'] as String, // Fallback to Russian
      city: 'Yerevan',
      date: DateTime.parse(j['startsAt'] as String).toLocal(),
      category: EventCategory.concert,
      priceFrom: (j['price'] as num).round(),
      cover: const Color(0xFF361268),
      description: '',
      descriptionAm: '',
      // Возврат разрешён — наследуется от события (приходит в TicketDto).
      refundGuarantee: j['refundGuarantee'] as bool? ?? false,
      refundUntilHours: (j['refundUntilHours'] as num?)?.toInt() ?? 24,
      ticketTypes: const [],
    );
    return OwnedTicket(
      id: j['id'] as String,
      event: stub,
      ticketTypeName: j['ticketTypeName'] as String,
      qrToken: j['qrToken'] as String,
      status: _statusFromApi(j['status'] as String?),
      transferredTo: j['transferredTo'] as String?,
    );
  }

  static TicketStatus _statusFromApi(String? s) {
    switch (s?.toLowerCase()) {
      case 'used':
        return TicketStatus.used;
      case 'transferred':
        return TicketStatus.transferred;
      case 'refunded':
        return TicketStatus.refunded;
      case 'cancelled':
        return TicketStatus.cancelled;
      case 'eventcancelled':
        return TicketStatus.eventCancelled;
      case 'rescheduledpending':
        return TicketStatus.rescheduledPending;
      case 'rescheduledconfirmed':
        return TicketStatus.rescheduledConfirmed;
      default:
        return TicketStatus.paid;
    }
  }

  static EventStatus _eventStatusFromApi(String? s) {
    switch (s?.toLowerCase()) {
      case 'cancelled':
        return EventStatus.cancelled;
      case 'rescheduled':
        return EventStatus.rescheduled;
      default:
        return EventStatus.active;
    }
  }

  // ─── Утилиты ────────────────────────────────────────────────────────
  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('API ${res.statusCode}: ${res.body}');
    }
  }

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    final v = int.parse(h.length == 6 ? 'FF$h' : h, radix: 16);
    return Color(v);
  }

  // Клиентские ключи категорий <-> enum бэкенда
  static String _toApiCategory(String key) {
    switch (key) {
      case 'concert':
        return 'Concert';
      case 'theatre':
        return 'Theatre';
      case 'festival':
        return 'Festival';
      case 'conference':
        return 'Conference';
      case 'exhibition':
        return 'Exhibition';
      default:
        return key;
    }
  }

  static EventCategory _fromApiCategory(String api) {
    switch (api.toLowerCase()) {
      case 'concert':
        return EventCategory.concert;
      case 'theatre':
        return EventCategory.theatre;
      case 'festival':
        return EventCategory.festival;
      case 'conference':
        return EventCategory.conference;
      case 'exhibition':
        return EventCategory.exhibition;
      default:
        return EventCategory.concert;
    }
  }
}
