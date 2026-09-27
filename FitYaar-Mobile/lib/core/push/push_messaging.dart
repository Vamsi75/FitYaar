import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../../features/gym/gym_notifications.dart';
import '../network/api_client.dart';

/// FCM wrapper — fully guarded. If Firebase isn't configured yet (no
/// `google-services.json` + `google-services` Gradle plugin), [init] fails
/// softly and every method no-ops, so the app builds and runs normally. It
/// activates automatically once the Firebase config is added — see
/// `docs/fcm-setup.md`.
class PushMessaging {
  PushMessaging._();
  static final PushMessaging instance = PushMessaging._();

  bool _ready = false;
  bool get isReady => _ready;

  Future<void> init() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
      FirebaseMessaging.onMessage.listen((m) {
        final n = m.notification;
        if (n != null) {
          GymNotifications.instance.showMessage(n.title ?? 'FitYaar', n.body ?? '');
        }
      });
      _ready = true;
    } catch (_) {
      // Firebase not configured on this build — FCM stays inactive (no crash).
      _ready = false;
    }
  }

  /// Register this device's FCM token with the backend (after login).
  Future<void> syncToken(ApiClient api) async {
    if (!_ready) return;
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await api.post('/devices/token', body: {'token': token, 'platform': 'android'});
      }
      FirebaseMessaging.instance.onTokenRefresh.listen((t) {
        api.post('/devices/token', body: {'token': t, 'platform': 'android'})
            .catchError((_) => null);
      });
    } catch (_) {}
  }

  /// Unregister this device's token (on logout).
  Future<void> removeToken(ApiClient api) async {
    if (!_ready) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await api.delete('/devices/token', body: {'token': token});
      }
    } catch (_) {}
  }
}

/// Top-level background handler (required by firebase_messaging). The system
/// tray renders background/terminated notifications automatically.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {}
