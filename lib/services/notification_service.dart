import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Wraps flutter_local_notifications so the rest of the app never touches
/// the plugin directly. All calls are defensive: if permission is denied or
/// the platform doesn't support a feature, we simply no-op instead of
/// crashing.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _plugin.initialize(initSettings);
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init failed: $e');
      _initialized = false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      final iosImpl = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      bool granted = true;
      if (androidImpl != null) {
        granted = await androidImpl.requestNotificationsPermission() ?? true;
      }
      if (iosImpl != null) {
        granted = await iosImpl.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            true;
      }
      return granted;
    } catch (e) {
      debugPrint('NotificationService permission request failed: $e');
      return false;
    }
  }

  int _idFor(String seed) => seed.hashCode & 0x7fffffff;

  Future<void> scheduleDaily({
    required String id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (!_initialized) return;
    try {
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = tz.TZDateTime(
          tz.local, now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      await _plugin.zonedSchedule(
        _idFor(id),
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habitflow_daily',
            'Daily Reminders',
            channelDescription: 'Daily habit, task and routine reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('scheduleDaily failed: $e');
    }
  }

  Future<void> scheduleOneOff({
    required String id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    if (!_initialized) return;
    if (dateTime.isBefore(DateTime.now())) return;
    try {
      final scheduled = tz.TZDateTime.from(dateTime, tz.local);
      await _plugin.zonedSchedule(
        _idFor(id),
        title,
        body,
        scheduled,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habitflow_reminders',
            'Reminders',
            channelDescription: 'Task and event reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('scheduleOneOff failed: $e');
    }
  }

  Future<void> cancel(String id) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(_idFor(id));
    } catch (e) {
      debugPrint('cancel notification failed: $e');
    }
  }

  Future<void> showNow({
    required String id,
    required String title,
    required String body,
  }) async {
    if (!_initialized) return;
    try {
      await _plugin.show(
        _idFor(id),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'habitflow_instant',
            'Instant Notifications',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      debugPrint('showNow failed: $e');
    }
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('cancelAll failed: $e');
    }
  }
}
