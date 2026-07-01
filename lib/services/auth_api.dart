import 'dart:convert';
import 'package:http/http.dart' as http;

/// Профиль пользователя, возвращаемый авторизацией.
class AuthUser {
  final String id;
  final String name;
  final String phone;

  /// Признак администратора. true только для скрытого admin-входа
  /// (на backend — флаг AppUser.IsAdmin). Открывает админ-панель.
  final bool isAdmin;

  const AuthUser({
    required this.id,
    required this.name,
    required this.phone,
    this.isAdmin = false,
  });
}

/// Результат успешного входа: токен сессии + профиль.
class AuthResult {
  final String token;
  final AuthUser user;
  const AuthResult({required this.token, required this.user});
}

/// Контракт авторизации по телефону + OTP (имитация SMS).
///
/// Реализуется так же, как [TicketsApi]:
///  • [MockAuthApi] — без бэкенда (код «0000»);
///  • [HttpAuthApi] — реальный backend (/api/auth/*).
abstract class AuthApi {
  /// Запрашивает код входа на [phone]. Возвращает dev-код, если бэкенд
  /// его отдаёт (в проде вернётся null — код придёт по SMS).
  Future<String?> requestOtp({required String phone, String? name});

  /// Проверяет [code] для [phone] и выдаёт сессию.
  Future<AuthResult> verifyOtp({required String phone, required String code});
}

/// Демо-реализация: код всегда «0000», пользователь создаётся на лету.
///
/// Скрытый вход администратора: номер [adminPhone] с кодом
/// [adminCode] выдаёт admin-токен и AuthUser.isAdmin=true (открывает
/// админ-панель). Для обычных номеров код — «0000».
class MockAuthApi implements AuthApi {
  static const _delay = Duration(milliseconds: 300);
  static const devCode = '0000';

  /// Скрытый вход в админку (q_admin_secret).
  static const adminPhone = '+37400000000';
  static const adminCode = '9999';

  final Map<String, String> _pending = {}; // phone -> name

  @override
  Future<String?> requestOtp({required String phone, String? name}) async {
    await Future<void>.delayed(_delay);
    _pending[_norm(phone)] = (name ?? '').trim().isEmpty ? 'Гость' : name!.trim();
    // Для admin-номера код фиксированный (9999), не подсказываем его в UI.
    if (_norm(phone) == adminPhone) return null;
    return devCode;
  }

  @override
  Future<AuthResult> verifyOtp({
    required String phone,
    required String code,
  }) async {
    await Future<void>.delayed(_delay);
    final p = _norm(phone);

    // Скрытый admin-вход: спец-номер + спец-код → admin-токен.
    if (p == adminPhone) {
      if (code.trim() != adminCode) {
        throw StateError('{"error": "Неверный код."}');
      }
      return AuthResult(
        token: 'admin-${DateTime.now().microsecondsSinceEpoch}',
        user: AuthUser(
          id: 'admin-$p',
          name: 'Администратор',
          phone: p,
          isAdmin: true,
        ),
      );
    }

    if (code.trim() != devCode) {
      throw StateError('{"error": "Неверный код."}');
    }
    final name = _pending[p] ?? 'Гость';
    return AuthResult(
      token: 'mock-${DateTime.now().microsecondsSinceEpoch}',
      user: AuthUser(id: 'mock-$p', name: name, phone: p),
    );
  }

  static String _norm(String phone) => phone.trim().replaceAll(' ', '');
}

/// Реализация поверх C# backend (/api/auth/request-otp, /verify-otp).
class HttpAuthApi implements AuthApi {
  final String baseUrl;
  final http.Client _client;

  HttpAuthApi({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  @override
  Future<String?> requestOtp({required String phone, String? name}) async {
    final res = await _client.post(
      _u('/api/auth/request-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'displayName': name}),
    );
    _ensureOk(res);
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    return j['devCode'] as String?;
  }

  @override
  Future<AuthResult> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final res = await _client.post(
      _u('/api/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'code': code}),
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
