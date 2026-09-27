import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Thin wrapper around local notifications for gym density alerts.
/// (True closed-app push would need FCM — a Phase-5 item; these fire while the
/// app is alive and observing the gym's occupancy.)
class GymNotifications {
  GymNotifications._();
  static final GymNotifications instance = GymNotifications._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings: settings);
    _ready = true;
  }

  /// Ask for the Android 13+ notification permission (no-op on older APIs).
  Future<void> requestPermission() async {
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  /// Generic notification (used to surface FCM foreground messages).
  Future<void> showMessage(String title, String body) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'fityaar_push',
        'FitYaar',
        channelDescription: 'Announcements and alerts',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      id: title.hashCode & 0x7fffffff,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> showDensity(int gymId, String gymName, int pct) async {
    await init();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'gym_density',
        'Gym crowd alerts',
        channelDescription: 'Alerts when your gym is quieter than your threshold',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
    await _plugin.show(
      id: 9000 + gymId, // stable per-gym id so it replaces, not stacks
      title: '$gymName is quiet right now',
      body: 'Crowd is at $pct% of capacity — good time to head over.',
      notificationDetails: details,
    );
  }
}
