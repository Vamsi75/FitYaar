import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/accent_button.dart';
import '../../profile/profile_service.dart';
import '../../workout/active_workout_model.dart';
import '../../workout/models/workout_models.dart';
import '../../workout/screens/active_workout_screen.dart';
import '../../workout/workout_service.dart';
import '../gym_alert_prefs.dart';
import '../gym_focus.dart';
import '../gym_models.dart';
import '../gym_service.dart';
import '../widgets/glow_avatar.dart';
import '../widgets/gym_live_pager.dart';
import 'gym_leaderboard_screen.dart';

/// Member "arena" view (opened from the compact Home entry): gym-updates banner,
/// your read-only plan, live crowd + active-now, trainers, classes, leaderboard,
/// and a privacy toggle. Trainers/owners use the separate TrainerGymScreen.
class GymScreen extends StatefulWidget {
  final int gymId;
  const GymScreen({super.key, required this.gymId});

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  GymSummary? _g;
  GymPlan? _plan;
  List<GymActivityItem> _activity = [];
  List<GymActivityItem> _zones = [];
  List<HourlyBucket> _trends = [];
  List<ActiveMember> _active = [];
  List<GymClass> _classes = [];
  List<GymEventItem> _events = [];
  List<GymTrainer> _trainers = [];
  Set<int> _dismissed = {};
  bool _gymVisible = true;
  bool _loading = true;
  bool _busy = false;
  bool _starting = false;

  ActiveWorkoutModel? _workout;
  bool _wasActive = false;

  String get _dismissKey => 'gym_${widget.gymId}_dismissed';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final m = context.read<ActiveWorkoutModel>();
    if (!identical(m, _workout)) {
      _workout?.removeListener(_onWorkout);
      _workout = m;
      _wasActive = m.isActive;
      _workout!.addListener(_onWorkout);
    }
  }

  void _onWorkout() {
    final a = _workout?.isActive ?? false;
    // Refresh on any change (e.g. auto-checkout on finish). The re-check-in that
    // updates focus/zone on workout start is handled once by the Home gym card
    // (GymEntryCard) — doing it here too would double-count the member.
    if (_wasActive != a) _load();
    _wasActive = a;
  }

  @override
  void dispose() {
    _workout?.removeListener(_onWorkout);
    super.dispose();
  }

  Future<void> _load() async {
    final svc = context.read<GymService>();
    final profileSvc = context.read<ProfileService>();
    try {
      final prefs = await SharedPreferences.getInstance();
      final dismissed = (prefs.getStringList(_dismissKey) ?? [])
          .map(int.tryParse)
          .whereType<int>()
          .toSet();
      final gyms = await svc.myGyms();
      final g = gyms.where((x) => x.gymId == widget.gymId).toList();
      final summary = g.isNotEmpty ? g.first : (gyms.isNotEmpty ? gyms.first : null);
      GymPlan? plan;
      List<GymActivityItem> activity = [];
      List<GymActivityItem> zones = [];
      List<HourlyBucket> trends = [];
      List<ActiveMember> active = [];
      List<GymClass> classes = [];
      List<GymEventItem> events = [];
      List<GymTrainer> trainers = [];
      if (summary != null && summary.isActive) {
        plan = await svc.myPlan(summary.gymId);
        activity = await svc.activity(summary.gymId);
        zones = await svc.zones(summary.gymId);
        trends = await svc.trends(summary.gymId);
        active = await svc.activeMembers(summary.gymId);
        classes = await svc.classes(summary.gymId);
        events = await svc.events(summary.gymId);
        trainers = await svc.trainers(summary.gymId);
      }
      bool visible = true;
      try {
        visible = (await profileSvc.getProfile()).gymVisible;
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _g = summary;
        _plan = plan;
        _activity = activity;
        _zones = zones;
        _trends = trends;
        _active = active;
        _classes = classes;
        _events = events;
        _trainers = trainers;
        _dismissed = dismissed;
        _gymVisible = visible;
        _loading = false;
      });
      if (summary != null) {
        await GymAlertPrefs.evaluate(
            summary.gymId, summary.name, summary.liveCount, summary.capacity);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  GymEventItem? get _topUpdate {
    for (final e in _events) {
      if (!_dismissed.contains(e.id)) return e;
    }
    return null;
  }

  Future<void> _dismissUpdate(int id) async {
    setState(() => _dismissed = {..._dismissed, id});
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_dismissKey, _dismissed.map((e) => e.toString()).toList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final g = _g;
    final isStaff = g?.role == 'TRAINER' || g?.role == 'OWNER';
    return Scaffold(
      appBar: AppBar(
        title: Text(g?.name ?? 'Your Gym'),
        actions: [
          if (g != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) {
                if (v == 'visible') _setVisible(!_gymVisible);
              },
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: 'visible',
                  checked: _gymVisible,
                  child: const Text('Show me in this gym'),
                ),
              ],
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : g == null
              ? const Center(child: Text('Gym not found'))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_topUpdate != null) ...[
                        _updateBanner(theme, _topUpdate!),
                        const SizedBox(height: 14),
                      ],
                      _planCard(theme),
                      const SizedBox(height: 14),
                      GymLivePager(
                        gym: g,
                        activity: _activity,
                        zones: _zones,
                        trends: _trends,
                        active: _active,
                      ),
                      const SizedBox(height: 14),
                      _facilityCard(theme),
                      const SizedBox(height: 18),
                      if (!isStaff) ...[
                        AccentButton(
                          loading: _busy,
                          icon: g.checkedIn ? Icons.logout : Icons.login,
                          label: g.checkedIn ? 'Check out' : 'Check in',
                          onPressed: () => _toggleCheckin(g),
                        ),
                        const SizedBox(height: 10),
                      ],
                      GlassButton(
                        icon: Icons.leaderboard_outlined,
                        label: 'Leaderboard',
                        expand: true,
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                GymLeaderboardScreen(gymId: g.gymId, gymName: g.name))),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _updateBanner(ThemeData theme, GymEventItem e) {
    return GlassCard(
      tint: theme.colorScheme.primary,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign, color: theme.colorScheme.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (e.body != null && e.body!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(e.body!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ],
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18, color: Colors.white54),
            onPressed: () => _dismissUpdate(e.id),
          ),
        ],
      ),
    );
  }

  Future<void> _setVisible(bool v) async {
    setState(() => _gymVisible = v);
    try {
      await context.read<ProfileService>().updateProfile(gymVisible: v);
      await _load();
    } catch (_) {
      if (mounted) setState(() => _gymVisible = !v);
    }
  }

  Widget _planCard(ThemeData theme) {
    final p = _plan;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.assignment_outlined, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Your plan', style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 8),
          if (p == null)
            const Text('No plan yet — your trainer can assign one.',
                style: TextStyle(color: Colors.white54))
          else ...[
            Text(p.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            if (p.body != null && p.body!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(p.body!, style: const TextStyle(color: Colors.white70)),
            ],
            if (p.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              for (final it in p.items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_box_outline_blank,
                          size: 18, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(it.exerciseName,
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                              ),
                              if (it.scheme.isNotEmpty)
                                Text(it.scheme,
                                    style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13)),
                            ]),
                            if (it.note != null && it.note!.isNotEmpty)
                              Text(it.note!,
                                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (p.authorName != null) ...[
              const SizedBox(height: 8),
              Text('from ${p.authorName}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
            const SizedBox(height: 12),
            AccentButton(
              loading: _starting,
              icon: Icons.play_arrow_rounded,
              label: 'Start workout',
              onPressed: () => _startFromPlan(p),
            ),
          ],
        ],
      ),
    );
  }

  /// Turn the trainer-assigned plan into an active workout: match plan items to
  /// the exercise catalog by name, prefill, and open the active-workout screen.
  Future<void> _startFromPlan(GymPlan p) async {
    final model = context.read<ActiveWorkoutModel>();
    final navigator = Navigator.of(context);
    if (model.isActive) {
      navigator.push(MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
      return;
    }
    setState(() => _starting = true);
    final matched = <Exercise>[];
    try {
      final all = await context.read<WorkoutService>().searchExercises('');
      final byName = {for (final e in all) e.name.toLowerCase(): e};
      for (final it in p.items) {
        final e = byName[it.exerciseName.toLowerCase()];
        if (e != null) matched.add(e);
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() => _starting = false);
    model.start(title: p.title, exercises: matched);
    navigator.push(MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
  }

  /// Secondary facility info (trainers + classes) folded into one expandable
  /// card so it doesn't stretch the screen.
  Widget _facilityCard(ThemeData theme) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          leading: Icon(Icons.info_outline, size: 20, color: theme.colorScheme.primary),
          title: Text('Classes & trainers', style: theme.textTheme.titleMedium),
          subtitle: Text(
              '${_trainers.length} trainer${_trainers.length == 1 ? '' : 's'}'
              '${_trainers.any((t) => t.activeNow) ? ' · ${_trainers.where((t) => t.activeNow).length} here now' : ''} · '
              '${_classes.length} class${_classes.length == 1 ? '' : 'es'}',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          children: [
            _trainersRow(theme),
            const SizedBox(height: 14),
            _classesList(theme),
          ],
        ),
      ),
    );
  }

  Widget _trainersRow(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text('TRAINERS',
              style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5)),
          if (_trainers.any((t) => t.activeNow)) ...[
            const SizedBox(width: 8),
            Container(
                width: 6,
                height: 6,
                decoration:
                    const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
            const SizedBox(width: 4),
            Text('${_trainers.where((t) => t.activeNow).length} of ${_trainers.length} here now',
                style: const TextStyle(
                    color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w600)),
          ],
        ]),
        const SizedBox(height: 8),
        if (_trainers.isEmpty)
          const Text('No trainers listed.', style: TextStyle(color: Colors.white60))
        else
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _trainers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final t = _trainers[i];
                final active = t.activeNow;
                return Container(
                  padding: const EdgeInsets.fromLTRB(6, 5, 12, 5),
                  decoration: BoxDecoration(
                      color: active
                          ? Colors.greenAccent.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: active
                              ? Colors.greenAccent.withValues(alpha: 0.5)
                              : Colors.white.withValues(alpha: 0.1))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Stack(children: [
                      GlowAvatar(name: t.displayName, size: 28),
                      if (active)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFF1b1518), width: 1.5)),
                          ),
                        ),
                    ]),
                    const SizedBox(width: 8),
                    Text(t.displayName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    if (t.isOwner) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                    ],
                    if (active) ...[
                      const SizedBox(width: 6),
                      const Text('Now',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.greenAccent,
                              fontWeight: FontWeight.w700)),
                    ],
                  ]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _classesList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('CLASSES',
            style: TextStyle(
                color: theme.colorScheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5)),
        const SizedBox(height: 4),
        if (_classes.isEmpty)
          const Text('No classes scheduled.', style: TextStyle(color: Colors.white70))
        else
          for (final c in _classes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.event_note, size: 16, color: theme.colorScheme.primary.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text([
                          if (c.schedule != null && c.schedule!.isNotEmpty) c.schedule!,
                          if (c.trainerName != null) 'with ${c.trainerName}',
                        ].join(' · '),
                            style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        if (c.description != null && c.description!.isNotEmpty)
                          Text(c.description!,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }

  Future<void> _toggleCheckin(GymSummary g) async {
    final svc = context.read<GymService>();
    if (g.checkedIn) {
      setState(() => _busy = true);
      try {
        await svc.checkOut(g.gymId);
        await _load();
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }
    // Focus (Push/Pull/Legs) and zone are auto-derived from the active workout — no prompt.
    final exs = _workout?.entries.map((e) => e.exercise).toList() ?? const <Exercise>[];
    setState(() => _busy = true);
    try {
      await svc.checkIn(g.gymId, focus: classifyFocus(exs), zone: classifyZone(exs));
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
