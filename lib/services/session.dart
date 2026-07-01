import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Сессия пользователя приложения.
///
/// Хранит, кто сейчас работает с приложением:
///  • вошедший пользователь — есть [token], [phone], [name];
///  • гость — [isGuest] == true (билеты привязываются к контакту из формы);
///  • никто (нужен экран входа) — ни токена, ни гостевого флага.
///
/// Состояние переживает перезапуск: токен/телефон/имя сохраняются в
/// shared_preferences и восстанавливаются при старте через [load].
class AppSession extends ChangeNotifier {
  AppSession._();

  /// Единый экземпляр на всё приложение.
  static final AppSession instance = AppSession._();

  static const _kToken = 'session_token';
  static const _kPhone = 'session_phone';
  static const _kName = 'session_name';
  static const _kGuest = 'session_guest';
  static const _kAdmin = 'session_admin';

  String? _token;
  String? _phone;
  String? _name;
  bool _isGuest = false;
  bool _isAdmin = false;

  /// Токен сессии (Bearer) вошедшего пользователя. null у гостя.
  String? get token => _token;

  /// Телефон пользователя — логин и ключ привязки билетов на бэкенде.
  String? get phone => _phone;

  /// Отображаемое имя пользователя.
  String? get name => _name;

  /// true, если выбран режим «Продолжить как гость».
  bool get isGuest => _isGuest;

  /// true, если вошёл администратор (скрытый вход). Даёт
  /// доступ к админ-панели и admin-эндпоинтам.
  bool get isAdmin => _isAdmin;

  /// Пользователь вошёл по телефону (есть токен сессии).
  bool get isLoggedIn => _token != null;

  /// Можно входить в приложение: либо вошёл, либо выбрал гостевой режим.
  bool get isAuthenticated => isLoggedIn || _isGuest;

  /// Восстанавливает сессию из локального хранилища при запуске.
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _token = p.getString(_kToken);
    _phone = p.getString(_kPhone);
    _name = p.getString(_kName);
    _isGuest = p.getBool(_kGuest) ?? false;
    _isAdmin = p.getBool(_kAdmin) ?? false;
    notifyListeners();
  }

  /// Сохраняет успешный вход по телефону.
  Future<void> signIn({
    required String token,
    required String phone,
    required String name,
    bool isAdmin = false,
  }) async {
    _token = token;
    _phone = phone;
    _name = name;
    _isGuest = false;
    _isAdmin = isAdmin;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kToken, token);
    await p.setString(_kPhone, phone);
    await p.setString(_kName, name);
    await p.setBool(_kGuest, false);
    await p.setBool(_kAdmin, isAdmin);
    notifyListeners();
  }

  /// Переходит в гостевой режим (без аккаунта).
  Future<void> continueAsGuest() async {
    _token = null;
    _phone = null;
    _name = null;
    _isGuest = true;
    _isAdmin = false;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kPhone);
    await p.remove(_kName);
    await p.setBool(_kGuest, true);
    await p.setBool(_kAdmin, false);
    notifyListeners();
  }

  /// Полный выход: очищает сессию (возврат к экрану входа).
  Future<void> signOut() async {
    _token = null;
    _phone = null;
    _name = null;
    _isGuest = false;
    _isAdmin = false;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kToken);
    await p.remove(_kPhone);
    await p.remove(_kName);
    await p.remove(_kGuest);
    await p.remove(_kAdmin);
    notifyListeners();
  }
}
