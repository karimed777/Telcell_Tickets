import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Локальные push-уведомления приложения (без сервера и FCM).
///
/// Покрывает минимальный набор PRD:
///  - успешная покупка билетов;
///  - отмена события организатором;
///  - перенос даты события.
///
/// Плагин может быть недоступен на некоторых платформах (например, в
/// unit-тестах или на desktop без поддержки) — в этом случае сервис
/// тихо деградирует: уведомление не показывается, но приложение не падает.
class AppNotifications {
  AppNotifications._();
  static final AppNotifications instance = AppNotifications._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _ready = false;
  int _idSeq = 1000;

  /// Каналы Android (на iOS игнорируются).
  static const _channelPurchase = AndroidNotificationDetails(
    'purchase',
    'Покупки',
    channelDescription: 'Подтверждения покупки билетов',
    importance: Importance.high,
    priority: Priority.high,
  );
  static const _channelEvent = AndroidNotificationDetails(
    'event_updates',
    'Изменения событий',
    channelDescription: 'Отмена и перенос мероприятий',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Инициализация — вызывать один раз при старте приложения.
  /// Безопасна к повторным вызовам и к отсутствию плагина.
  Future<void> init() async {
    if (_ready) return;
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings =
          InitializationSettings(android: android, iOS: ios);
      await _plugin.initialize(settings);

      // Запрос разрешений (Android 13+ / iOS).
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      await iosImpl?.requestPermissions(alert: true, badge: true, sound: true);

      _ready = true;
    } catch (e) {
      // Плагин недоступен (тесты/desktop) — деградируем без падения.
      debugPrint('AppNotifications.init skipped: $e');
      _ready = false;
    }
  }

  Future<void> _show(
    String title,
    String body,
    AndroidNotificationDetails android,
  ) async {
    if (!_ready) {
      // Не инициализировано — попробуем лениво.
      await init();
      if (!_ready) {
        debugPrint('Notification (suppressed): $title — $body');
        return;
      }
    }
    try {
      await _plugin.show(
        _idSeq++,
        title,
        body,
        NotificationDetails(
          android: android,
          iOS: const DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('Notification show failed: $e');
    }
  }

  /// Уведомление об успешной покупке.
  Future<void> purchaseSuccess({
    required String eventTitle,
    required int ticketCount,
    required String title,
    required String Function(String eventTitle, int count) bodyBuilder,
  }) {
    return _show(title, bodyBuilder(eventTitle, ticketCount), _channelPurchase);
  }

  /// Уведомление об отмене события организатором.
  Future<void> eventCancelled({
    required String title,
    required String body,
  }) {
    return _show(title, body, _channelEvent);
  }

  /// Уведомление о переносе даты события.
  Future<void> eventRescheduled({
    required String title,
    required String body,
  }) {
    return _show(title, body, _channelEvent);
  }
}
