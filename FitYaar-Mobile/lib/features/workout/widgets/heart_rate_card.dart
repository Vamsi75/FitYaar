import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/health/health_sync_service.dart';
import '../../../core/widgets/glass_card.dart';
import '../../insights/widgets/mini_line_chart.dart';
import '../../profile/profile_service.dart';
import '../models/workout_models.dart';
import '../workout_service.dart';

const _hrColor = Color(0xFFFF5A5F);
const _zoneColors = [
  Color(0xFF5B8DEF), // Z1 warm-up
  Color(0xFF37E29A), // Z2 easy
  Color(0xFFF5D547), // Z3 aerobic
  Color(0xFFF5A623), // Z4 threshold
  Color(0xFFFF5A5F), // Z5 max
];

/// Heart rate, zones and active calories for one workout, from the user's watch via
/// Health Connect / Apple Health.
///
/// * [initial] — metrics already stored on the session: shown as-is.
/// * Otherwise, when the store is connected, reads the [start]–[end] window. With
///   [autoFetch] (the post-workout summary) it reads straight away and retries a few
///   times, because watches usually sync a few minutes after the workout ends;
///   without it (history) it shows a "Load" button.
/// * Found data is uploaded to the session ([sessionId]) so it shows up everywhere.
class WorkoutHeartRateCard extends StatefulWidget {
  final int? sessionId;
  final DateTime? start;
  final DateTime? end;
  final HealthMetrics? initial;
  final bool autoFetch;

  /// Called whenever the card has (new) metrics to show — e.g. for share images.
  final ValueChanged<HealthMetrics>? onMetrics;

  const WorkoutHeartRateCard({
    super.key,
    required this.sessionId,
    required this.start,
    required this.end,
    this.initial,
    this.autoFetch = false,
    this.onMetrics,
  });

  @override
  State<WorkoutHeartRateCard> createState() => _WorkoutHeartRateCardState();
}

enum _Phase { idle, loading, notFound, unavailable, found }

class _WorkoutHeartRateCardState extends State<WorkoutHeartRateCard> {
  /// Watches sync in batches (Fitbit often sends calories first, heart rate a few
  /// minutes later), so the summary screen re-checks on this schedule until it has
  /// heart rate.
  static const _retryDelays = [
    Duration(seconds: 30),
    Duration(seconds: 90),
    Duration(minutes: 3),
  ];

  HealthMetrics? _metrics;
  _Phase _phase = _Phase.idle;
  HealthAvailability? _availability;
  Timer? _retry;
  int _attempt = 0;
  bool _saveFailed = false;

  @override
  void initState() {
    super.initState();
    _metrics = widget.initial;
    if (_metrics != null) {
      _phase = _Phase.found;
      // Saved at finish without heart rate (only calories had synced): keep checking.
      if (widget.autoFetch && !_metrics!.hasHeartRate) _scheduleRetry();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _init());
    }
  }

  @override
  void dispose() {
    _retry?.cancel();
    super.dispose();
  }

  Future<void> _init() async {
    final health = context.read<HealthSyncService>();
    if (!health.isSupported) return;
    await health.load();
    final availability = await health.availability();
    if (!mounted) return;
    setState(() => _availability = availability);
    if (availability != HealthAvailability.available) {
      setState(() => _phase = _Phase.unavailable);
      return;
    }
    if (health.isConnected && widget.autoFetch) _fetch();
  }

  /// Schedules the next automatic re-check (summary screen only). Returns false when
  /// the schedule is used up.
  bool _scheduleRetry() {
    if (!widget.autoFetch || _attempt >= _retryDelays.length) return false;
    _retry?.cancel();
    _retry = Timer(_retryDelays[_attempt++], () {
      if (mounted) _fetch();
    });
    return true;
  }

  Future<void> _connect() async {
    final health = context.read<HealthSyncService>();
    final ok = await health.connect();
    if (!mounted) return;
    if (ok) {
      _fetch();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${health.storeName} access wasn\'t granted.')));
    }
  }

  Future<void> _fetch() async {
    final start = widget.start, end = widget.end;
    if (start == null || end == null) return;
    _retry?.cancel();
    final health = context.read<HealthSyncService>();
    final workouts = context.read<WorkoutService>();
    final profiles = context.read<ProfileService>();
    setState(() => _phase = _Phase.loading);

    int? age;
    try {
      final b = (await profiles.getProfile()).birthday;
      if (b != null) age = _ageOn(b, start);
    } catch (_) {}

    HealthMetrics? m;
    try {
      await health.ensurePermissions();
      m = await health.readWorkoutMetrics(start, end, age: age);
    } catch (e) {
      debugPrint('heart rate read failed: $e');
    }
    if (!mounted) return;

    if (m == null && _metrics != null) {
      // A refresh found nothing new — keep what we already show.
      setState(() => _phase = _Phase.found);
      if (!_metrics!.hasHeartRate) _scheduleRetry();
      return;
    }
    if (m == null) {
      setState(() => _phase = _Phase.notFound);
      // Auto-retry on the summary screen: the watch may still be syncing.
      _scheduleRetry();
      return;
    }

    final found = m;
    setState(() {
      _metrics = found;
      _phase = _Phase.found;
    });
    widget.onMetrics?.call(found);
    // Calories but no heart rate yet: the watch's heart-rate batch usually follows.
    if (!found.hasHeartRate) _scheduleRetry();
    if (widget.sessionId != null) {
      try {
        final saved = await workouts.saveHealthMetrics(widget.sessionId!, found);
        if (mounted) setState(() => _metrics = saved);
        widget.onMetrics?.call(saved);
      } catch (_) {
        if (mounted) setState(() => _saveFailed = true);
      }
    }
  }

  static int _ageOn(DateTime birthday, DateTime on) {
    var age = on.year - birthday.year;
    if (on.month < birthday.month || (on.month == birthday.month && on.day < birthday.day)) {
      age--;
    }
    return age;
  }

  @override
  Widget build(BuildContext context) {
    final health = context.watch<HealthSyncService>();
    if ((_phase == _Phase.found || (_phase == _Phase.loading && _metrics != null)) &&
        _metrics != null) {
      return _found(context, _metrics!, refreshing: _phase == _Phase.loading);
    }
    if (!health.isSupported) return const SizedBox.shrink();
    if (widget.start == null || widget.end == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    Widget body;
    if (_phase == _Phase.unavailable) {
      final update = _availability == HealthAvailability.updateRequired;
      body = _message(
        update
            ? 'Update Health Connect to see heart rate and calories from your watch.'
            : 'Install Health Connect to see heart rate and calories from your watch.',
        action: TextButton.icon(
          onPressed: health.installHealthConnect,
          icon: const Icon(Icons.download, size: 18),
          label: Text(update ? 'Update' : 'Install'),
        ),
      );
    } else if (!health.isConnected) {
      body = _message(
        'Connect ${health.storeName} to see heart rate, zones and calories from '
        'your watch (Fitbit, Galaxy Watch, Garmin${health.storeName == 'Apple Health' ? ', Apple Watch' : ''}…).',
        action: FilledButton.tonalIcon(
          onPressed: _connect,
          icon: const Icon(Icons.favorite, size: 18),
          label: Text('Connect ${health.storeName}'),
        ),
      );
    } else if (_phase == _Phase.loading) {
      body = const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(
            child: SizedBox(
                width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    } else if (_phase == _Phase.notFound) {
      final retrying = _retry?.isActive ?? false;
      body = _message(
        retrying
            ? 'No watch data yet — watches can take a few minutes to sync. Checking again shortly…'
            : 'No heart rate found in ${health.storeName} for this workout. '
                'Open your watch\'s app to sync, then check again.',
        action: TextButton.icon(
          onPressed: _fetch,
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Check again'),
        ),
      );
    } else {
      body = _message(
        'Load heart rate and calories for this workout from ${health.storeName}.',
        action: TextButton.icon(
          onPressed: _fetch,
          icon: const Icon(Icons.favorite_border, size: 18),
          label: const Text('Load'),
        ),
      );
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.favorite, color: _hrColor, size: 18),
            const SizedBox(width: 8),
            Text('Heart rate', style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 8),
          body,
        ],
      ),
    );
  }

  Widget _message(String text, {Widget? action}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (action != null) ...[const SizedBox(height: 6), action],
        ],
      );

  Widget _found(BuildContext context, HealthMetrics m, {bool refreshing = false}) {
    final theme = Theme.of(context);
    final health = context.read<HealthSyncService>();
    final canRefresh = health.isSupported &&
        health.isConnected &&
        widget.start != null &&
        widget.end != null &&
        health.canReadFrom(widget.start!);
    final source = [
      if (m.sourceName != null && m.sourceName!.isNotEmpty)
        HealthSyncService.friendlySourceName(m.sourceName!),
      m.platformLabel,
    ].join(' · ');
    final bpms = m.heartRateSamples.map((s) => s[1].toDouble()).toList();
    final zoneTotal = m.zoneSeconds.fold<int>(0, (a, b) => a + b);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.favorite, color: _hrColor, size: 18),
            const SizedBox(width: 8),
            Text('Heart rate', style: theme.textTheme.titleMedium),
            const Spacer(),
            Flexible(
              child: Text(source,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ),
            if (canRefresh)
              refreshing
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(
                      icon: const Icon(Icons.refresh, size: 18, color: Colors.white54),
                      tooltip: 'Reload from ${health.storeName}',
                      visualDensity: VisualDensity.compact,
                      onPressed: _fetch,
                    ),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _stat(theme, m.avgHeartRate?.toString() ?? '—', 'Avg bpm'),
            _stat(theme, m.maxHeartRate?.toString() ?? '—', 'Max bpm'),
            // Fitbit only reports total (active + resting) calories — label it honestly.
            if (m.activeCalories == null && m.totalCalories != null)
              _stat(theme, '${m.totalCalories}', 'Total kcal')
            else
              _stat(theme, m.activeCalories?.toString() ?? '—', 'Active kcal'),
          ]),
          if (bpms.length >= 2) ...[
            const SizedBox(height: 12),
            MiniLineChart(
              values: bpms,
              color: _hrColor,
              height: 110,
              formatY: (v) => '${v.round()}',
            ),
          ],
          if (zoneTotal > 0) ...[
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(children: [
                for (var i = 0; i < m.zoneSeconds.length && i < 5; i++)
                  if (m.zoneSeconds[i] > 0)
                    Expanded(
                      flex: m.zoneSeconds[i],
                      child: Container(height: 10, color: _zoneColors[i]),
                    ),
              ]),
            ),
            const SizedBox(height: 8),
            Wrap(spacing: 12, runSpacing: 4, children: [
              for (var i = 0; i < m.zoneSeconds.length && i < 5; i++)
                if (m.zoneSeconds[i] > 0)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration:
                            BoxDecoration(color: _zoneColors[i], shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text('Z${i + 1} ${_mins(m.zoneSeconds[i])}',
                        style: const TextStyle(fontSize: 11, color: Colors.white70)),
                  ]),
            ]),
          ],
          if (!m.hasHeartRate && ((_retry?.isActive ?? false) || refreshing))
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Heart rate still syncing from your watch…',
                  style: TextStyle(fontSize: 11, color: Colors.white54)),
            ),
          if (_saveFailed)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text('Couldn\'t save to your workout — it will show here only.',
                  style: TextStyle(fontSize: 11, color: Colors.white38)),
            ),
        ],
      ),
    );
  }

  static String _mins(int secs) => secs < 60 ? '${secs}s' : '${(secs / 60).round()}m';

  Widget _stat(ThemeData theme, String value, String label) => Expanded(
        child: Column(children: [
          Text(value,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ]),
      );
}
