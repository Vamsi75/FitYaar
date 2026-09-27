import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/accent_button.dart';
import '../../../core/widgets/anim_icon.dart';
import '../../../core/widgets/glass_card.dart';
import '../active_workout_model.dart';
import '../models/workout_models.dart';
import '../workout_service.dart';
import 'active_workout_screen.dart';
import 'create_routine_screen.dart';

/// The "Log" tab: start an empty workout or launch/create a routine (max 4).
class WorkoutLogScreen extends StatefulWidget {
  const WorkoutLogScreen({super.key});

  @override
  State<WorkoutLogScreen> createState() => _WorkoutLogScreenState();
}

class _WorkoutLogScreenState extends State<WorkoutLogScreen> {
  static const _maxRoutines = 4;

  List<Routine> _routines = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    try {
      final all = await context.read<WorkoutService>().getRoutines();
      if (!mounted) return;
      setState(() {
        _routines = all.where((r) => !r.isTemplate).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _openActiveWorkout() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()),
    );
  }

  void _startEmpty() {
    context.read<ActiveWorkoutModel>().start(title: 'New Workout');
    _openActiveWorkout();
  }

  void _startFromRoutine(Routine routine) {
    final exercises = routine.exercises
        .map((re) =>
            Exercise(id: re.exerciseId, name: re.exerciseName ?? 'Exercise'))
        .toList();
    context.read<ActiveWorkoutModel>().start(
          title: routine.name,
          exercises: exercises,
          routineId: routine.id,
        );
    _openActiveWorkout();
  }

  Future<void> _createRoutine() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateRoutineScreen()),
    );
    if (created == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child:
                            Text('Ready to train?', style: theme.textTheme.titleLarge)),
                    const AnimIcon(
                        asset: 'assets/anim/dumbbell.json',
                        fallback: Icons.fitness_center,
                        size: 40),
                  ]),
                  const SizedBox(height: 4),
                  const Text('Start a blank session and add exercises as you go.'),
                  const SizedBox(height: 16),
                  AccentButton(
                    onPressed: _startEmpty,
                    icon: Icons.add,
                    label: 'Start Empty Workout',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Your routines', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            const Text('Save up to $_maxRoutines routines to start your day fast.',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  for (final r in _routines.take(_maxRoutines))
                    _RoutineTile(routine: r, onTap: () => _startFromRoutine(r)),
                  if (_routines.length < _maxRoutines)
                    _CreateTile(onTap: _createRoutine),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _RoutineTile extends StatelessWidget {
  final Routine routine;
  final VoidCallback onTap;
  const _RoutineTile({required this.routine, required this.onTap});

  static String _titleCase(String s) => s
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');

  static IconData _routineIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('push')) return Icons.arrow_upward_rounded;
    if (n.contains('pull')) return Icons.arrow_downward_rounded;
    if (n.contains('leg') || n.contains('lower') || n.contains('squat')) {
      return Icons.directions_run_rounded;
    }
    if (n.contains('core') || n.contains('ab')) return Icons.self_improvement;
    return Icons.fitness_center;
  }

  /// Matching animated icon, when the Lottie asset has been added
  /// (see assets/anim/README.md — missing files fall back to [_routineIcon]).
  static String _routineAsset(String name) {
    final n = name.toLowerCase();
    if (n.contains('push')) return 'assets/anim/push.json';
    if (n.contains('pull')) return 'assets/anim/pull.json';
    if (n.contains('leg') || n.contains('lower') || n.contains('squat')) {
      return 'assets/anim/legs.json';
    }
    return 'assets/anim/dumbbell.json';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final previews = routine.exercises
        .map((e) => e.exerciseName)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .take(3)
        .toList();
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: AnimIcon(
                  asset: _routineAsset(routine.name),
                  fallback: _routineIcon(routine.name),
                  size: 24),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(_titleCase(routine.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 8),
          if (previews.isEmpty)
            const Text('No exercises yet',
                style: TextStyle(color: Colors.white38, fontSize: 12))
          else
            for (final p in previews)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('•  $p',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ),
          const Spacer(),
          Row(
            children: [
              Text('${routine.exercises.length} exercises',
                  style: const TextStyle(color: Colors.white54, fontSize: 12)),
              const Spacer(),
              Icon(Icons.play_circle_fill, color: theme.colorScheme.primary, size: 22),
            ],
          ),
        ],
      ),
    );
  }
}

class _CreateTile extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary, width: 1.5),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text('Create routine',
                  style: TextStyle(color: theme.colorScheme.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
