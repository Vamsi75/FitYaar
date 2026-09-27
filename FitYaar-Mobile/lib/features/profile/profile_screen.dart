import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/glass_card.dart';
import '../auth/auth_provider.dart';
import '../insights/goal_progress.dart';
import '../workout/models/workout_models.dart';
import '../workout/screens/personal_records_screen.dart';
import '../social/social_models.dart';
import '../social/social_service.dart';
import '../workout/screens/session_tile.dart';
import '../workout/workout_service.dart';
import 'edit_profile_screen.dart';
import 'measurement_models.dart';
import 'measurement_service.dart';
import 'profile_models.dart';
import 'profile_service.dart';
import 'screens/body_measurements_screen.dart';
import 'screens/follow_list_screen.dart';
import 'screens/go_pro_screen.dart';
import 'screens/goal_screen.dart';
import 'settings_screen.dart';
import 'widgets/progress_chart.dart';

enum _Range { m1, m3, m6, y1, all }

String _rangeLabel(_Range r) => switch (r) {
      _Range.m1 => '1 Month',
      _Range.m3 => '3 Months',
      _Range.m6 => '6 Months',
      _Range.y1 => '1 Year',
      _Range.all => 'All time',
    };

bool _rangeIsPro(_Range r) => r == _Range.y1 || r == _Range.all;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  ProfileData? _profile;
  List<WorkoutSession> _sessions = [];
  GoalProgress? _goal;
  Future<SocialCounts>? _counts;
  bool _loading = true;
  ProgressMetric _metric = ProgressMetric.volume;
  _Range _range = _Range.m3;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final profileSvc = context.read<ProfileService>();
    final workoutSvc = context.read<WorkoutService>();
    final measureSvc = context.read<MeasurementService>();
    _counts = context.read<SocialService>().counts();
    try {
      final p = await profileSvc.getProfile();
      final h = await workoutSvc.getHistory();
      List<BodyMeasurement> ms = const [];
      try {
        ms = await measureSvc.list();
      } catch (_) {}
      final goal = buildGoalProgress(
        goal: p.fitnessGoal,
        profileCurrentWeight: p.currentWeight,
        targetWeight: p.targetWeight,
        measurements: ms,
        sessions: h,
      );
      if (!mounted) return;
      setState(() {
        _profile = p;
        _sessions = h;
        _goal = goal;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit() async {
    if (_profile == null) return;
    final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => EditProfileScreen(current: _profile!)));
    if (saved == true) _load();
  }

  Future<void> _openSettings() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    _load();
  }

  Future<void> _share() async {
    final name = _profile?.displayName ?? 'A FitYaar athlete';
    final bio = _profile?.bio;
    await Clipboard.setData(ClipboardData(
        text: '$name on FitYaar${bio != null && bio.isNotEmpty ? '\n$bio' : ''}'
            '\nfityaar.app/u/me'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile link copied to clipboard')));
    }
  }

  DateTime _rangeStart() {
    final now = DateTime.now();
    switch (_range) {
      case _Range.m1:
        return now.subtract(const Duration(days: 30));
      case _Range.m3:
        return now.subtract(const Duration(days: 90));
      case _Range.m6:
        return now.subtract(const Duration(days: 180));
      case _Range.y1:
        return now.subtract(const Duration(days: 365));
      case _Range.all:
        final earliest = _sessions
            .map((s) => s.startTime)
            .whereType<DateTime>()
            .fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
        return earliest ?? now.subtract(const Duration(days: 365));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
              tooltip: 'Edit', icon: const Icon(Icons.edit_outlined), onPressed: _edit),
          IconButton(
              tooltip: 'Share', icon: const Icon(Icons.ios_share), onPressed: _share),
          IconButton(
              tooltip: 'Settings',
              icon: const Icon(Icons.settings_outlined),
              onPressed: _openSettings),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _headerCard(theme),
                  const SizedBox(height: 16),
                  _goalCard(theme),
                  const SizedBox(height: 16),
                  _progressCard(theme),
                  const SizedBox(height: 16),
                  _measurementsButton(theme),
                  const SizedBox(height: 20),
                  Text('History', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  if (_sessions.isEmpty)
                    const GlassCard(
                        child: Text('No workouts yet.',
                            style: TextStyle(color: Colors.white70)))
                  else
                    for (final s in (List<WorkoutSession>.from(_sessions)
                      ..sort((a, b) => (b.startTime ?? DateTime(0))
                          .compareTo(a.startTime ?? DateTime(0)))))
                      SessionTile(session: s, onChanged: _load),
                ],
              ),
            ),
    );
  }

  Widget _headerCard(ThemeData theme) {
    final p = _profile;
    final name = p?.displayName ??
        context.watch<AuthProvider>().user?.displayName ??
        'Athlete';
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _avatar(p?.profilePictureUrl, name),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    if (p?.bio != null && p!.bio!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(p.bio!,
                            style: const TextStyle(color: Colors.white70)),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<SocialCounts>(
            future: _counts,
            builder: (context, snap) {
              final c = snap.data;
              return Row(
                children: [
                  _countButton('${c?.followers ?? 0}', 'Followers', true),
                  const SizedBox(width: 28),
                  _countButton('${c?.following ?? 0}', 'Following', false),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _countButton(String count, String label, bool showFollowers) {
    return InkWell(
      onTap: () {
        final uid = context.read<AuthProvider>().user?.id;
        if (uid == null) return;
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) =>
                FollowListScreen(userId: uid, showFollowers: showFollowers)));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(count,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _progressCard(ThemeData theme) {
    final start = _rangeStart();
    final filtered = _sessions
        .where((s) => s.startTime != null && !s.startTime!.isBefore(start))
        .toList();
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Progress', style: theme.textTheme.titleMedium),
              const Spacer(),
              _rangeDropdown(theme),
            ],
          ),
          const SizedBox(height: 12),
          _MetricSelector(
            metric: _metric,
            onChanged: (m) => setState(() => _metric = m),
          ),
          const SizedBox(height: 6),
          Text('${metricLabel(_metric)} · ${metricUnit(_metric)}',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 12),
          ProgressChart(
            sessions: filtered,
            start: start,
            end: DateTime.now(),
            metric: _metric,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const PersonalRecordsScreen())),
              icon: const Icon(Icons.emoji_events_outlined, size: 18),
              label: const Text('Personal records'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _goalCard(ThemeData theme) {
    final goalName = _profile?.fitnessGoal;
    final g = _goal;
    return GlassCard(
      tint: theme.colorScheme.primary,
      glow: theme.colorScheme.primary,
      onTap: () async {
        await Navigator.of(context)
            .push(MaterialPageRoute(builder: (_) => const GoalScreen()));
        _load();
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.20),
            child: Icon(Icons.flag, color: Colors.orange.shade200),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Your goal',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
                Text(
                    goalName == null || goalName.isEmpty
                        ? 'Set your goal'
                        : goalName,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                if (g != null) ...[
                  const SizedBox(height: 4),
                  Text(g.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  if (g.fraction != null) ...[
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: g.fraction,
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.10),
                        valueColor:
                            AlwaysStoppedAnimation(theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ] else
                  const Text('Tap to choose and track progress',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _measurementsButton(ThemeData theme) {
    return GlassCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => const BodyMeasurementsScreen())),
      child: Row(
        children: [
          Icon(Icons.monitor_weight_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Measurements',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Text('Weight, waist & body fat — log and track',
                    style: TextStyle(color: Colors.white60, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _rangeDropdown(ThemeData theme) {
    final isPro = context.watch<AuthProvider>().isPro;
    return DropdownButton<_Range>(
      value: _range,
      isDense: true,
      underline: const SizedBox.shrink(),
      borderRadius: BorderRadius.circular(12),
      items: [
        for (final r in _Range.values)
          DropdownMenuItem(
            value: r,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_rangeLabel(r)),
                if (_rangeIsPro(r) && !isPro)
                  const Padding(
                      padding: EdgeInsets.only(left: 6),
                      child: Icon(Icons.lock, size: 13)),
              ],
            ),
          ),
      ],
      onChanged: (r) {
        if (r == null) return;
        if (_rangeIsPro(r) && !isPro) {
          Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GoProScreen()));
        } else {
          setState(() => _range = r);
        }
      },
    );
  }

  Widget _avatar(String? url, String name) {
    if (url != null && url.isNotEmpty) {
      return CircleAvatar(radius: 34, backgroundImage: NetworkImage(url));
    }
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.isEmpty || parts.first.isEmpty
        ? '?'
        : parts.map((w) => w[0]).take(2).join().toUpperCase();
    return CircleAvatar(
      radius: 34,
      child: Text(initials,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }
}

/// Sleek segmented control for the progress metric.
class _MetricSelector extends StatelessWidget {
  final ProgressMetric metric;
  final ValueChanged<ProgressMetric> onChanged;
  const _MetricSelector({required this.metric, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final m in ProgressMetric.values)
            GestureDetector(
              onTap: () => onChanged(m),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: m == metric
                      ? theme.colorScheme.primary.withValues(alpha: 0.9)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  metricLabel(m),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        m == metric ? FontWeight.w600 : FontWeight.normal,
                    color: m == metric ? Colors.white : Colors.white70,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
