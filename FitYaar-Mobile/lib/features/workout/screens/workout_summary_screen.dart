import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../insights/analytics.dart';
import '../../insights/goal_progress.dart';
import '../../insights/widgets/muscle_body.dart';
import '../../profile/measurement_models.dart';
import '../../profile/measurement_service.dart';
import '../../profile/profile_models.dart';
import '../../profile/profile_service.dart';
import '../active_workout_model.dart' show fmtWeight;
import '../models/workout_models.dart';
import '../workout_service.dart';

typedef SummaryExtra = ({List<PrEvent> prs, String? gender, GoalProgress? goal});

/// Celebration + recap shown right after a workout is saved: today's muscle
/// map (only what was targeted), the lifts done, duration, and any new PRs.
class WorkoutSummaryScreen extends StatefulWidget {
  final String name;
  final Duration duration;
  final List<LoggedExercise> exercises;
  const WorkoutSummaryScreen({
    super.key,
    required this.name,
    required this.duration,
    required this.exercises,
  });

  @override
  State<WorkoutSummaryScreen> createState() => _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends State<WorkoutSummaryScreen> {
  late Future<SummaryExtra> _extra;

  @override
  void initState() {
    super.initState();
    _extra = _load();
  }

  Future<SummaryExtra> _load() async {
    final workoutSvc = context.read<WorkoutService>();
    final profileSvc = context.read<ProfileService>();
    final measureSvc = context.read<MeasurementService>();
    final history = await workoutSvc.getHistory();
    final today = DateTime.now();
    final prs = recentPRs(history, days: 2)
        .where((p) =>
            p.date.year == today.year &&
            p.date.month == today.month &&
            p.date.day == today.day)
        .toList();
    ProfileData? profile;
    try {
      profile = await profileSvc.getProfile();
    } catch (_) {}
    List<BodyMeasurement> ms = const [];
    try {
      ms = await measureSvc.list();
    } catch (_) {}
    final goal = profile == null
        ? null
        : buildGoalProgress(
            goal: profile.fitnessGoal,
            profileCurrentWeight: profile.currentWeight,
            targetWeight: profile.targetWeight,
            measurements: ms,
            sessions: history,
          );
    return (prs: prs, gender: profile?.gender, goal: goal);
  }

  /// Every muscle an exercise trains (primary + secondary), as body-map slugs, so
  /// a compound lift lights up each worked muscle individually — not just a region.
  Set<String> _slugsOf(Exercise e) {
    final out = <String>{};
    for (final m in e.primaryMuscleGroups) {
      final s = slugForToken(m);
      if (s != null) out.add(s);
    }
    for (final m in e.secondaryMuscleGroups) {
      final s = slugForToken(m);
      if (s != null) out.add(s);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Today's targeted muscles + intensity (per body-map slug).
    final counts = <String, int>{};
    var totalSets = 0;
    var volume = 0.0;
    for (final le in widget.exercises) {
      final slugs = _slugsOf(le.exercise);
      for (final s in le.sets) {
        if (s.type == WorkoutSetType.warmup) continue;
        totalSets++;
        volume += (s.weight ?? 0) * (s.reps ?? 0);
        for (final sl in slugs) {
          counts[sl] = (counts[sl] ?? 0) + 1;
        }
      }
    }
    final maxCount = counts.values.fold<int>(0, (a, b) => b > a ? b : a);
    final intensity = {
      for (final e in counts.entries)
        e.key: maxCount == 0 ? 0.0 : e.value / maxCount,
    };

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Workout Complete'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Text('💪 ${widget.name}',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Nice work — here\'s your session.',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 16),
          Row(children: [
            _stat(theme, _dur(widget.duration), 'Duration'),
            const SizedBox(width: 10),
            _stat(theme, '$totalSets', 'Sets'),
            const SizedBox(width: 10),
            _stat(theme, _vol(volume), 'Volume'),
          ]),
          const SizedBox(height: 16),
          FutureBuilder<SummaryExtra>(
            future: _extra,
            builder: (context, snap) {
              final gp = snap.data?.goal;
              if (gp == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GoalProgressCard(progress: gp),
              );
            },
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Muscles worked', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                FutureBuilder<SummaryExtra>(
                  future: _extra,
                  builder: (context, snap) => MuscleBody(
                    intensity: intensity,
                    gender: snap.data?.gender,
                    height: 260,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<SummaryExtra>(
            future: _extra,
            builder: (context, snap) {
              final prs = snap.data?.prs ?? const <PrEvent>[];
              if (prs.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Text('🏆', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text('${prs.length} new ${prs.length == 1 ? 'PR' : 'PRs'}!',
                            style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.amber, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 8),
                      for (final pr in prs)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(children: [
                            Expanded(
                                child: Text(pr.name,
                                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                            Text('${fmtWeight(pr.weight)} × ${pr.reps}',
                                style: const TextStyle(color: Colors.white70)),
                            const SizedBox(width: 10),
                            Text(
                                '+${fmtWeight(double.parse(pr.deltaKg.toStringAsFixed(1)))}kg',
                                style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.w600)),
                          ]),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Exercises', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final le in widget.exercises) _exerciseRow(theme, le),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassButton(
            icon: Icons.check,
            label: 'Done',
            expand: true,
            onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
          ),
        ],
      ),
    );
  }

  Widget _exerciseRow(ThemeData theme, LoggedExercise le) {
    final working = le.sets.where((s) => s.type != WorkoutSetType.warmup).toList();
    LoggedSet? top;
    for (final s in working) {
      if (top == null || (s.weight ?? 0) > (top.weight ?? 0)) top = s;
    }
    final topStr = top == null
        ? '${working.length} sets'
        : '${working.length} sets · top ${fmtWeight(top.weight ?? 0)}×${top.reps}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(Icons.fitness_center, size: 16, color: theme.colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
            child: Text(le.exercise.name,
                maxLines: 1, overflow: TextOverflow.ellipsis)),
        Text(topStr, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ]),
    );
  }

  Widget _stat(ThemeData theme, String value, String label) {
    return Expanded(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Column(children: [
          Text(value,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white60)),
        ]),
      ),
    );
  }

  String _dur(Duration d) {
    final h = d.inHours, m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String _vol(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}t' : '${v.round()} kg';
}
