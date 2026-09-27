import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_client.dart';
import '../../../core/widgets/accent_button.dart';
import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../workout/active_workout_model.dart';
import '../../workout/models/workout_models.dart';
import '../gym_alert_prefs.dart';
import '../gym_focus.dart';
import '../gym_models.dart';
import '../gym_service.dart';
import '../screens/gym_screen.dart';
import '../screens/trainer_gym_screen.dart';

/// Compact Home entry for the gym: a single button — **Check in** when not
/// checked in, **My Arena** once you are (auto-reverts on workout finish).
/// Opening it navigates to the full [GymScreen]. Keeps Home uncluttered.
class GymEntryCard extends StatefulWidget {
  const GymEntryCard({super.key});

  @override
  State<GymEntryCard> createState() => _GymEntryCardState();
}

class _GymEntryCardState extends State<GymEntryCard> {
  List<GymSummary>? _gyms;
  bool _busy = false;
  final _codeCtrl = TextEditingController();

  ActiveWorkoutModel? _workout;
  bool _wasActive = false;

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
    if (_wasActive && !a) _load(); // auto-checkout on finish → flip button back
    if (!_wasActive && a) _syncFocus(); // starting a workout → update check-in focus
    _wasActive = a;
  }

  /// If already checked in, re-check-in with the focus derived from the newly
  /// started workout so the gym crowd breakdown stays accurate.
  Future<void> _syncFocus() async {
    final g = _primary;
    if (g == null || !g.checkedIn) return;
    final exs = _workout?.entries.map((e) => e.exercise).toList() ?? const <Exercise>[];
    final focus = classifyFocus(exs);
    if (focus == null) return;
    try {
      await context.read<GymService>().checkIn(g.gymId, focus: focus, zone: classifyZone(exs));
      await _load();
    } catch (_) {}
  }

  @override
  void dispose() {
    _workout?.removeListener(_onWorkout);
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final g = await context.read<GymService>().myGyms();
      if (mounted) setState(() => _gyms = g);
      for (final s in g) {
        if (s.isActive) {
          await GymAlertPrefs.evaluate(s.gymId, s.name, s.liveCount, s.capacity);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _gyms = []);
    }
  }

  GymSummary? get _primary {
    final g = _gyms;
    if (g == null || g.isEmpty) return null;
    for (final m in g) {
      if (m.isActive) return m;
    }
    return g.first;
  }

  Future<void> _openGym(int gymId) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => GymScreen(gymId: gymId)));
    _load();
  }

  Future<void> _openManage(int gymId) async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => TrainerGymScreen(gymId: gymId)));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_gyms == null) return const SizedBox.shrink();
    final g = _primary;
    if (g == null) return _joinCard(context);
    if (g.isPending) return _pendingCard(context, g);
    return _activeCard(context, g);
  }

  Widget _activeCard(BuildContext context, GymSummary g) {
    final theme = Theme.of(context);
    final isStaff = g.role == 'TRAINER' || g.role == 'OWNER';
    return GlassCard(
      // Staff open the Manage gym screen (which now shows live status + management together).
      onTap: () => isStaff ? _openManage(g.gymId) : _openGym(g.gymId),
      child: Row(
        children: [
          Icon(Icons.stadium, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                    isStaff
                        ? (g.role == 'OWNER' ? 'Owner · ${g.liveCount} here now' : 'Trainer · ${g.liveCount} here now')
                        : g.checkedIn
                            ? 'Checked in · ${g.liveCount} here now'
                            : '${g.liveCount} here now',
                    style: TextStyle(
                        color: g.checkedIn && !isStaff ? Colors.greenAccent : Colors.white54,
                        fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isStaff)
            GlassButton(
                dense: true,
                icon: Icons.tune,
                label: 'Manage gym',
                onPressed: () => _openManage(g.gymId))
          else
            _busy
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : g.checkedIn
                    ? GlassButton(
                        dense: true,
                        icon: Icons.stadium_outlined,
                        label: 'My Arena',
                        onPressed: () => _openGym(g.gymId))
                    : GlassButton(
                        dense: true,
                        icon: Icons.login,
                        label: 'Check in',
                        onPressed: () => _checkIn(g)),
        ],
      ),
    );
  }

  Future<void> _checkIn(GymSummary g) async {
    final svc = context.read<GymService>();
    // Focus (Push/Pull/Legs) and zone are auto-derived from the active workout — no prompt.
    final exs = _workout?.entries.map((e) => e.exercise).toList() ?? const <Exercise>[];
    setState(() => _busy = true);
    try {
      await svc.checkIn(g.gymId, focus: classifyFocus(exs), zone: classifyZone(exs));
      await _load();
      if (mounted) await _openGym(g.gymId); // check in → straight into the arena
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Check-in failed.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _pendingCard(BuildContext context, GymSummary g) {
    return GlassCard(
      child: Row(children: [
        const Icon(Icons.hourglass_top, color: Colors.amber),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(g.name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const Text('Membership pending admin approval',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _joinCard(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.stadium_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text('Your gym', style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 6),
          const Text('Have a gym code? Join to see live crowd, plans & classes.',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _codeCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                    hintText: 'Gym code',
                    isDense: true,
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide:
                            BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.5))),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.6))),
              ),
            ),
            const SizedBox(width: 8),
            _busy
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)))
                : AccentButton(label: 'Join', expand: false, onPressed: _join),
          ]),
        ],
      ),
    );
  }

  Future<void> _join() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) return;
    setState(() => _busy = true);
    try {
      final res = await context.read<GymService>().join(code);
      _codeCtrl.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(res.isActive
              ? 'Joined ${res.name}!'
              : 'Request sent to ${res.name} — awaiting approval.'),
        ));
        if (res.isActive) _openGym(res.gymId);
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Could not join gym.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
