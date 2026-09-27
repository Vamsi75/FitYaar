import 'package:shared_preferences/shared_preferences.dart';

import 'gym_notifications.dart';

/// Per-gym "notify me when the crowd is under X%" preference + the debounced
/// evaluation that fires a local notification on a downward crossing.
class GymAlertPrefs {
  static String _enKey(int gymId) => 'gym_${gymId}_alert_enabled';
  static String _thKey(int gymId) => 'gym_${gymId}_alert_threshold';
  static String _firedKey(int gymId) => 'gym_${gymId}_alert_fired';

  static Future<({bool enabled, int thresholdPct})> load(int gymId) async {
    final p = await SharedPreferences.getInstance();
    return (
      enabled: p.getBool(_enKey(gymId)) ?? false,
      thresholdPct: p.getInt(_thKey(gymId)) ?? 50,
    );
  }

  static Future<void> save(int gymId,
      {required bool enabled, required int thresholdPct}) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_enKey(gymId), enabled);
    await p.setInt(_thKey(gymId), thresholdPct);
  }

  /// Evaluate current occupancy against the saved threshold and fire a one-shot
  /// notification the first time it drops under it; reset once it fills back up.
  static Future<void> evaluate(
      int gymId, String gymName, int liveCount, int? capacity) async {
    if (capacity == null || capacity <= 0) return;
    final prefs = await load(gymId);
    if (!prefs.enabled) return;
    final pct = (liveCount / capacity * 100).round();
    final sp = await SharedPreferences.getInstance();
    final fired = sp.getBool(_firedKey(gymId)) ?? false;
    if (pct < prefs.thresholdPct) {
      if (!fired) {
        await GymNotifications.instance.showDensity(gymId, gymName, pct);
        await sp.setBool(_firedKey(gymId), true);
      }
    } else if (fired) {
      await sp.setBool(_firedKey(gymId), false);
    }
  }
}
