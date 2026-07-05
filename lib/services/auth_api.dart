import 'dart:convert';
import 'package:http/http.dart' as http;

/// Профиль пользователя, возвращаемый авторизацией.
class AuthUser {
  final String id;
  final String name;
  final String phone;

  /// Email, привязанный к аккаунту (может быть пустым для старых аккаунтов).
  final String email;

  /// Признак администратора. true только для скрытого admin-входа
  /// (на backend — флаг AppUser.IsAdmin). Открывает админ-панель.
  final bool isAdmin;

  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.isAdmin = false,
  });
}

/// Результат успешного входа: токен сессии + профиль.
class AuthResult {
  final String token;
  final AuthUser user;
  const AuthResult({required this.token, required this.user});
}

/// Контракт авторизации по одноразовому коду (OTP).
///
/// Два сценария:
///  • регистрация — имя + телефон + email, один код уходит на оба канала;
///  • вход — код на телефон ИЛИ email (на выбор пользователя).
///
/// Реализуется так же, как [TicketsApi]:
///  • [MockAuthApi] — без бэкенда (код «0000»);
///  • [HttpAuthApi] — реальный backend (/api/auth/*).
abstract class AuthApi {
  /// Регистрация нового аккаунта: отправляет один код входа сразу на
  /// [phone] и [email]. Возвращает dev-код, если бэкенд его отдаёт
  /// (в проде вернётся null — код придёт по SMS и на почту).
  Future<String?> requestRegisterOtp({
    required String name,
    required String phone,
    required String email,
  });

  /// Вход в существующий аккаунт: отправляет код на [contact]
  /// (телефон или email). Возвращает dev-код, если бэкенд его отдаёт.
  Future<String?> requestLoginOtp({required String contact});

  /// Проверяет [code] для [contact] (телефон или email) и выдаёт сессию.
  Future<AuthResult> verifyOtp({required String contact, required String code});
}

/// Демо-реализация: код всегда «0000», пользователь создаётся на лету.
///
/// Скрытый вход администратора: номер [adminPhone] с кодом
/// [adminCode] выдаёт admin-токен и AuthUser.isAdmin=true (открывает
/// админ-панель). Для обычных пользователей код — «0000».
class MockAuthApi implements AuthApi {
  static const _delay = Duration(milliseconds: 300);
  static const devCode = '0000';

  /// Скрытый вход в админку (q_admin_secret).
  static const adminPhone = '+37400000000';
  static const adminCode = '9999';

  /// «База» зарегистрированных аккаунтов: contact (телефон и email) →
  /// профиль. Один аккаунт доступен по обоим ключам.
  final Map<String, _MockAccount> _accounts = {};

  /// Ожидающие подтверждения регистрации: contact → профиль.
  final Map<String, _MockAccount> _pendingRegister = {};

  @override
  Future<String?> requestRegisterOtp({
    required String name,
    required String phone,
    required String email,
  }) async {
    await Future<void>.delayed(_delay);
    final acc = _MockAccount(
      name: name.trim().isEmpty ? 'Гость' : name.trim(),
      phone: _norm(phone),
      email: _normEmail(email),
    );
    // Один код «уходит» и на телефон, и на email.
    _pendingRegister[acc.phone] = acc;
    _pendingRegister[acc.email] = acc;
    return devCode;
  }

  @override
  Future<String?> requestLoginOtp({required String contact}) async {
    await Future<void>.delayed(_delay);
    final c = _normContact(contact);
    // Для admin-номера код фиксированный (9999), не подсказываем его в UI.
    if (c == adminPhone) return null;
    return devCode;
  }

  @override
  Future<AuthResult> verifyOtp({
    required String contact,
    required String code,
  }) async {
    await Future<void>.delayed(_delay);
    final c = _normContact(contact);

    // Скрытый admin-вход: спец-номер + спец-код → admin-токен.
    if (c == adminPhone) {
      if (code.trim() != adminCode) {
        throw StateError('{"error": "Неверный код."}');
      }
      return AuthResult(
        token: 'admin-${DateTime.now().microsecondsSinceEpoch}',
        user: AuthUser(
          id: 'admin-$c',
          name: 'Администратор',
          phone: c,
          isAdmin: true,
        ),
      );
    }

    if (code.trim() != devCode) {
      throw StateError('{"error": "Неверный код."}');
    }

    // Завершение регистрации: переносим pending-профиль в «базу».
    final pending = _pendingRegister.remove(c);
    if (pending != null) {
      _pendingRegister.remove(pending.phone);
      _pendingRegister.remove(pending.email);
      _accounts[pending.phone] = pending;
      if (pending.email.isNotEmpty) _accounts[pending.email] = pending;
    }

    final acc = pending ??
        _accounts[c] ??
        // Демо-послабление: неизвестный контакт входит как гость,
        // чтобы поток можно было проверить без предварительной регистрации.
        _MockAccount(
          name: 'Гость',
          phone: c.contains('@') ? '' : c,
          email: c.contains('@') ? c : '',
        );

    return AuthResult(
      token: 'mock-${DateTime.now().microsecondsSinceEpoch}',
      user: AuthUser(
        id: 'mock-${acc.phone.isNotEmpty ? acc.phone : acc.email}',
        name: acc.name,
        phone: acc.phone,
        email: acc.email,
      ),
    );
  }

  static String _norm(String phone) => phone.trim().replaceAll(' ', '');
  static String _normEmail(String email) => email.trim().toLowerCase();
  static String _normContact(String c) =>
      c.contains('@') ? _normEmail(c) : _norm(c);
}

class _MockAccount {
  final String name;
  final String phone;
  final String email;
  const _MockAccount({
    required this.name,
    required this.phone,
    required this.email,
  });
}

/// Реализация поверх C# backend (/api/auth/request-otp, /verify-otp).
///
/// Backend пока принимает контакт в поле `phone` (email передаётся
/// дополнительными полями и будет использован после доработки API).
class HttpAuthApi implements AuthApi {
  final String baseUrl;
  final http.Client _client;

  HttpAuthApi({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  @override
  Future<String?> requestRegisterOtp({
    required String name,
    required String phone,
    required String email,
  }) async {
    final res = await _client.post(
      _u('/api/auth/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'phone': phone,
        'displayName': name,
        'email': email,
      }),
    );
    _ensureOk(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return j['devCode'] as String?;
  }

  @override
  Future<String?> requestLoginOtp({required String contact}) async {
    final res = await _client.post(
      _u('/api/auth/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': contact}),
    );
    _ensureOk(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return j['devCode'] as String?;
  }

  @override
  Future<AuthResult> verifyOtp({
    required String contact,
    required String code,
  }) async {
    final res = await _client.post(
      _u('/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': contact, 'code': code}),
    );
    _ensureOk(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final u = j['user'] as Map<String, dynamic>;
    return AuthResult(
      token: j['token'] as String,
      user: AuthUser(
        id: u['id'] as String,
        name: u['displayName'] as String,
        phone: u['phone'] as String,
        email: u['email'] as String? ?? '',
        isAdmin: u['isAdmin'] as bool? ?? false,
      ),
    );
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      // Пробрасываем тело {"error": "..."} — UI покажет понятную причину.
      throw StateError(res.body);
    }
  }
}

/// Единая точка доступа к авторизации (как [Api] для билетов).
class Auth {
  Auth._();
  static AuthApi instance = MockAuthApi();
}
