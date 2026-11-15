import 'dart:io' show Platform;
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/workout/models/workout_models.dart';

/// Whether the phone's health store can be used right now.
enum HealthAvailability {
  /// Ready (Apple Health on iOS, Health Connect installed on Android).
  available,

  /// Android without the Health Connect app (Android 13 and older).
  notInstalled,

  /// Health Connect is installed but needs an update.
  updateRequired,

  /// Web / desktop — no health store.
  unsupported,
}

/// Reads wearable data (heart rate, active calories) for a workout from the phone's
/// health store — **Health Connect** on Android, **Apple Health** on iOS — and writes
/// finished FitYaar workouts back to it.
///
/// Any watch whose companion app syncs into the store works without per-brand code:
/// Fitbit / Pixel Watch / Fitbit Air (via the Google Health app), Galaxy Watch (Samsung
/// Health), Garmin (Garmin Connect), Apple Watch.
///
/// The user's choice to connect is remembered locally; the store itself stays the
/// source of truth for what's actually granted.
class HealthSyncService extends ChangeNotifier {
  static const _prefKey = 'health_connected';

  /// Heart rate + calories (read), the workout itself (write).
  ///
  /// Android also reads TOTAL calories: Fitbit writes only total (active + resting)
  /// calories to Health Connect, never active calories. iOS has no such type.
  static List<HealthDataType> get _readTypes => [
        HealthDataType.HEART_RATE,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        if (!kIsWeb && Platform.isAndroid) HealthDataType.TOTAL_CALORIES_BURNED,
      ];
  static List<HealthDataType> get _types => [..._readTypes, HealthDataType.WORKOUT];
  static List<HealthDataAccess> get _access => [
        for (final _ in _readTypes) HealthDataAccess.READ,
        HealthDataAccess.WRITE,
      ];

  /// Health Connect only lets an app read data from 30 days before it was first
  /// granted access onward (Apple Health has no limit).
  static const androidReadWindow = Duration(days: 30);

  final Health _health = Health();
  bool _configured = false;
  bool _connected = false;
  bool _loaded = false;

  bool get isSupported => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// "Health Connect" or "Apple Health".
  String get storeName => !kIsWeb && Platform.isIOS ? 'Apple Health' : 'Health Connect';

  /// Value sent to the backend's `platform` field.
  String get platformKey => !kIsWeb && Platform.isIOS ? 'APPLE_HEALTH' : 'HEALTH_CONNECT';

  bool get isConnected => _connected;

  /// Whether the store can still hold readable data for a workout that started at
  /// [start] (Health Connect: roughly the last 30 days; Apple Health: always).
  bool canReadFrom(DateTime start) {
    if (!isSupported) return false;
    if (Platform.isIOS) return true;
    return start.isAfter(DateTime.now().subtract(androidReadWindow));
  }

  /// When connected, makes sure every type FitYaar now uses is granted — an app
  /// update can add a type (e.g. total calories) the user never saw. Re-shows the
  /// permission sheet only on Android, where the grant state is known.
  Future<void> ensurePermissions() async {
    if (!isSupported || !_connected || !Platform.isAndroid) return;
    await _ensureConfigured();
    try {
      final has = await _health.hasPermissions(_types, permissions: _access);
      if (has != true) await _health.requestAuthorization(_types, permissions: _access);
    } catch (e) {
      debugPrint('HealthSyncService.ensurePermissions failed: $e');
    }
  }

  Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Loads the remembered "connected" flag (call once; cheap to call again).
  Future<bool> load() async {
    if (_loaded) return _connected;
    final prefs = await SharedPreferences.getInstance();
    _connected = isSupported && (prefs.getBool(_prefKey) ?? false);
    _loaded = true;
    notifyListeners();
    return _connected;
  }

  Future<HealthAvailability> availability() async {
    if (!isSupported) return HealthAvailability.unsupported;
    if (Platform.isIOS) return HealthAvailability.available;
    await _ensureConfigured();
    final status = await _health.getHealthConnectSdkStatus();
    switch (status) {
      case HealthConnectSdkStatus.sdkAvailable:
        return HealthAvailability.available;
      case HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired:
        return HealthAvailability.updateRequired;
      default:
        return HealthAvailability.notInstalled;
    }
  }

  /// Opens the Play Store page for Health Connect (Android only).
  Future<void> installHealthConnect() async {
    if (!isSupported || !Platform.isAndroid) return;
    await _ensureConfigured();
    await _health.installHealthConnect();
  }

  /// Shows the system permission sheet. Returns true if the user granted access.
  /// (On iOS, Apple never reveals whether *read* access was granted — reads simply
  /// come back empty — so true there means "the sheet completed".)
  Future<bool> connect() async {
    if (!isSupported) return false;
    if (await availability() != HealthAvailability.available) return false;
    await _ensureConfigured();
    bool granted;
    try {
      granted = await _health.requestAuthorization(_types, permissions: _access);
    } catch (e) {
      debugPrint('HealthSyncService.connect failed: $e');
      granted = false;
    }
    await _setConnected(granted);
    return granted;
  }

  /// Forgets the connection; on Android also revokes FitYaar's Health Connect grants.
  /// (iOS has no API for that — the user removes access in the Health app.)
  Future<void> disconnect() async {
    if (isSupported && Platform.isAndroid) {
      try {
        await _ensureConfigured();
        await _health.revokePermissions();
      } catch (_) {}
    }
    await _setConnected(false);
  }

  Future<void> _setConnected(bool v) async {
    _connected = v;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, v);
    notifyListeners();
  }

  /// Heart rate + calories recorded between [start] and [end], or null when the store
  /// has nothing for that window yet (watches often sync a few minutes late).
  ///
  /// [age] personalises the zones (HRmax = 208 − 0.7 × age, Tanaka); 190 otherwise.
  Future<HealthMetrics?> readWorkoutMetrics(DateTime start, DateTime end, {int? age}) async {
    if (!isSupported || !_connected) return null;
    if (!end.isAfter(start)) return null;
    await _ensureConfigured();

    final points = await _health.getHealthDataFromTypes(
      types: _readTypes,
      startTime: start,
      endTime: end,
    );
    debugPrint('HealthSyncService.read ${start.toIso8601String()}–${end.toIso8601String()}: '
        '${points.length} points ${_summarise(points)}');

    final hr = points.where((p) => p.type == HealthDataType.HEART_RATE).toList();
    final kcalPoints =
        points.where((p) => p.type == HealthDataType.ACTIVE_ENERGY_BURNED).toList();
    final totalPoints =
        points.where((p) => p.type == HealthDataType.TOTAL_CALORIES_BURNED).toList();

    // Several devices can write heart rate for the same minutes (phone + watch);
    // use the source with the most samples instead of blending them.
    final bySource = <String, List<HealthDataPoint>>{};
    for (final p in hr) {
      bySource.putIfAbsent(_key(p), () => []).add(p);
    }
    String? source;
    var samples = <({DateTime t, double bpm})>[];
    if (bySource.isNotEmpty) {
      final best = bySource.entries.reduce((a, b) => a.value.length >= b.value.length ? a : b);
      source = best.key;
      samples = best.value
          .map((p) => (t: p.dateFrom, bpm: _num(p.value)))
          .where((s) => s.bpm >= 25 && s.bpm <= 250)
          .toList()
        ..sort((a, b) => a.t.compareTo(b.t));
    }

    // Calories: prefer the device that recorded the heart rate. Other writers (the
    // phone's step estimate, the logging app's own guess) would otherwise be mixed in
    // — e.g. a phone's 1 kcal "active" figure beating the watch's real total.
    List<HealthDataPoint> fromHrSource(List<HealthDataPoint> pts) {
      if (source == null) return _bestSource(pts); // no heart rate at all
      return pts.where((p) => _key(p) == source).toList();
    }

    final calories = _overlapSum(fromHrSource(kcalPoints), start, end);
    final total = _overlapSum(fromHrSource(totalPoints), start, end);
    bool has(double? v) => v != null && v > 0;
    if (samples.isEmpty && !has(calories) && !has(total)) return null;
    source ??= kcalPoints.isNotEmpty
        ? _key(_bestSource(kcalPoints).first)
        : (totalPoints.isNotEmpty ? _key(_bestSource(totalPoints).first) : null);

    final maxHr = (age != null && age >= 10 && age <= 100)
        ? (208 - 0.7 * age).round()
        : 190;

    int? avg, mx, mn;
    final zones = List<int>.filled(5, 0);
    if (samples.isNotEmpty) {
      final bpms = samples.map((s) => s.bpm).toList();
      avg = (bpms.reduce((a, b) => a + b) / bpms.length).round();
      mx = bpms.reduce(math.max).round();
      mn = bpms.reduce(math.min).round();
      for (var i = 0; i < samples.length; i++) {
        // Each reading stands for the time until the next one (capped, so a sync gap
        // doesn't count as minutes in one zone).
        final next = i + 1 < samples.length ? samples[i + 1].t : end;
        final secs = next.difference(samples[i].t).inSeconds.clamp(1, 60);
        final pct = samples[i].bpm / maxHr;
        final zone = pct >= 0.9
            ? 4
            : pct >= 0.8
                ? 3
                : pct >= 0.7
                    ? 2
                    : pct >= 0.6
                        ? 1
                        : pct >= 0.5
                            ? 0
                            : -1;
        if (zone >= 0) zones[zone] += secs;
      }
    }

    return HealthMetrics(
      platform: platformKey,
      sourceName: source == null ? null : friendlySourceName(source),
      avgHeartRate: avg,
      maxHeartRate: mx,
      minHeartRate: mn,
      activeCalories: has(calories) ? calories!.round() : null,
      totalCalories: has(total) ? total!.round() : null,
      maxHrUsed: maxHr,
      zoneSeconds: samples.isEmpty ? const [] : zones,
      heartRateSamples: _downsample(samples, start),
    );
  }

  /// Saves a finished FitYaar workout to the health store. Best-effort: returns false
  /// (never throws) when not connected or the store refuses.
  Future<bool> writeWorkout({
    required DateTime start,
    required DateTime end,
    required String title,
  }) async {
    if (!isSupported || !_connected || !end.isAfter(start)) return false;
    try {
      await _ensureConfigured();
      return await _health.writeWorkoutData(
        activityType: Platform.isIOS
            ? HealthWorkoutActivityType.TRADITIONAL_STRENGTH_TRAINING
            : HealthWorkoutActivityType.STRENGTH_TRAINING,
        start: start,
        end: end,
        title: title,
        recordingMethod: RecordingMethod.manual,
      );
    } catch (e) {
      debugPrint('HealthSyncService.writeWorkout failed: $e');
      return false;
    }
  }

  // ---- helpers ----

  static String _key(HealthDataPoint p) => p.sourceName.isEmpty ? p.sourceId : p.sourceName;

  /// The points from whichever source wrote the most of them.
  static List<HealthDataPoint> _bestSource(List<HealthDataPoint> pts) {
    if (pts.isEmpty) return const [];
    final by = <String, List<HealthDataPoint>>{};
    for (final p in pts) {
      by.putIfAbsent(_key(p), () => []).add(p);
    }
    return by.values.reduce((a, b) => a.length >= b.length ? a : b);
  }

  /// Health Connect reports the writing app's package name; show a readable name.
  static String friendlySourceName(String source) {
    const known = {
      'com.fitbit.FitbitMobile': 'Fitbit',
      'com.google.android.apps.fitness': 'Google Fit',
      'com.google.android.apps.healthdata': 'Google Health',
      'com.sec.android.app.shealth': 'Samsung Health',
      'com.garmin.android.apps.connectmobile': 'Garmin Connect',
      'com.ouraring.oura': 'Oura',
      'com.whoop.android': 'WHOOP',
      'com.xiaomi.wearable': 'Mi Fitness',
      'com.huawei.health': 'Huawei Health',
      'com.strava': 'Strava',
      'com.hevy': 'Hevy',
    };
    if (known.containsKey(source)) return known[source]!;
    if (source.startsWith('com.android.healthconnect.phone')) return 'Phone';
    return source;
  }

  /// "HEART_RATE×42 (Fitbit), …" — for debugging what the store returned.
  static String _summarise(List<HealthDataPoint> pts) {
    final counts = <String, int>{};
    for (final p in pts) {
      final k = '${p.type.name} (${p.sourceName.isEmpty ? p.sourceId : p.sourceName})';
      counts[k] = (counts[k] ?? 0) + 1;
    }
    return counts.entries.map((e) => '${e.key}×${e.value}').join(', ');
  }

  static double _num(HealthValue v) =>
      v is NumericHealthValue ? v.numericValue.toDouble() : double.nan;

  /// Sum of energy records, each pro-rated by how much of it falls inside the window
  /// (Health Connect calorie records can span longer than the workout).
  static double? _overlapSum(List<HealthDataPoint> pts, DateTime start, DateTime end) {
    if (pts.isEmpty) return null;
    var total = 0.0;
    for (final p in pts) {
      final v = _num(p.value);
      if (v.isNaN) continue;
      final from = p.dateFrom.isBefore(start) ? start : p.dateFrom;
      final to = p.dateTo.isAfter(end) ? end : p.dateTo;
      final span = p.dateTo.difference(p.dateFrom).inSeconds;
      if (span <= 0) {
        total += v;
        continue;
      }
      final inside = to.difference(from).inSeconds;
      if (inside > 0) total += v * inside / span;
    }
    return total;
  }

  /// ≤ 120 points of [offsetSeconds, bpm] (bucket averages) — enough for a chart.
  static List<List<int>> _downsample(List<({DateTime t, double bpm})> s, DateTime start) {
    if (s.isEmpty) return const [];
    const maxPoints = 120;
    if (s.length <= maxPoints) {
      return [for (final x in s) [x.t.difference(start).inSeconds, x.bpm.round()]];
    }
    final out = <List<int>>[];
    final per = s.length / maxPoints;
    for (var b = 0; b < maxPoints; b++) {
      final from = (b * per).floor();
      final to = math.min(((b + 1) * per).floor(), s.length);
      if (from >= to) continue;
      var sum = 0.0;
      for (var i = from; i < to; i++) {
        sum += s[i].bpm;
      }
      out.add([s[from].t.difference(start).inSeconds, (sum / (to - from)).round()]);
    }
    return out;
  }
}
