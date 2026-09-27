import 'package:shared_preferences/shared_preferences.dart';

/// Persists user-marked rest days on-device as `yyyy-MM-dd` strings.
class RestDayStore {
  static const _key = 'rest_days';

  static String keyFor(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<Set<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? const []).toSet();
  }

  /// Toggles [day] and returns the updated set.
  Future<Set<String>> toggle(DateTime day) async {
    final prefs = await SharedPreferences.getInstance();
    final set = (prefs.getStringList(_key) ?? const []).toSet();
    final k = keyFor(day);
    if (!set.add(k)) set.remove(k);
    await prefs.setStringList(_key, set.toList());
    return set;
  }
}
