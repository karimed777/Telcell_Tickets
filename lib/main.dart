import 'package:flutter/material.dart';
import 'l10n/app_strings.dart';
import 'theme/app_theme.dart';
import 'services/session.dart';
import 'services/http_tickets_api.dart';
import 'services/tickets_api.dart';
import 'services/auth_api.dart';
import 'services/notifications.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_shell.dart';

/// Источник данных приложения.
///   true  — реальный backend (C# / .NET 8 + PostgreSQL) на [kApiBaseUrl];
///   false — локальные моки в памяти (работает без сервера).
const bool kUseBackend = true;

/// Базовый URL backend. Для web (Chrome) и desktop — localhost.
/// Для Android-эмулятора замени на http://10.0.2.2:5000.
const String kApiBaseUrl = 'http://localhost:5000';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Переключение на реальный backend (события, аккаунты и билеты —
  // в PostgreSQL). Без этого блока работают локальные моки.
  if (kUseBackend) {
    Api.instance = HttpTicketsApi(baseUrl: kApiBaseUrl);
    Auth.instance = HttpAuthApi(baseUrl: kApiBaseUrl);
  }

  // Восстанавливаем сессию (токен/телефон/имя или гостевой режим).
  await AppSession.instance.load();

  // Локальные push-уведомления (покупка/отмена/перенос).
  await AppNotifications.instance.init();

  // Если вошли раньше и работаем через реальный backend — привязываем
  // запросы к вошедшему пользователю.
  final api = Api.instance;
  if (api is HttpTicketsApi && AppSession.instance.isLoggedIn) {
    api.setIdentity(
      phone: AppSession.instance.phone,
      name: AppSession.instance.name,
      token: AppSession.instance.token,
    );
  }

  runApp(const TelcellTicketsApp());
}

class TelcellTicketsApp extends StatefulWidget {
  const TelcellTicketsApp({super.key});

  @override
  State<TelcellTicketsApp> createState() => _TelcellTicketsAppState();
}

class _TelcellTicketsAppState extends State<TelcellTicketsApp> {
  // По умолчанию RU; пользователь переключает на армянский (AM)
  // тумблером на онбординге.
  AppLanguage _lang = AppLanguage.ru;

  void _toggle() {
    setState(() {
      _lang = _lang == AppLanguage.ru ? AppLanguage.am : AppLanguage.ru;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Если уже вошли или выбрали гостевой режим — сразу каталог,
    // иначе показываем онбординг с выбором «Войти / Гость».
    final Widget start = AppSession.instance.isAuthenticated
        ? const HomeShell()
        : const OnboardingScreen();

    return AppLocale(
      language: _lang,
      toggle: _toggle,
      child: MaterialApp(
        title: 'Telcell Tickets',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: start,
      ),
    );
  }
}
