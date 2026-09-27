import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../workout/active_workout_model.dart';
import '../../workout/models/workout_models.dart';
import '../../workout/screens/active_workout_screen.dart';
import '../../workout/screens/exercise_picker_screen.dart';
import '../analytics.dart';

/// Rule-based nudge: surfaces the muscle group the user has neglected longest.
class NeglectedMuscleCard extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final Map<int, Exercise> catalog;
  const NeglectedMuscleCard(
      {super.key, required this.sessions, required this.catalog});

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final last = lastTrainedByRegion(sessions, catalog);
    final now = DateTime.now();

    // Oldest-trained (or never-trained) region wins.
    MuscleRegion? worst;
    int worstDays = -1;
    bool worstNever = false;
    for (final r in MuscleRegion.values) {
      final t = last[r];
      if (t == null) {
        if (!worstNever || worst == null) {
          worst = r;
          worstNever = true;
          worstDays = 1 << 30;
        }
      } else if (!worstNever) {
        final days = now.difference(t).inDays;
        if (days > worstDays) {
          worst = r;
          worstDays = days;
        }
      }
    }
    if (worst == null) return const SizedBox.shrink();
    // Only nag once there are enough sessions (avoids noise on a fresh account),
    // and only once a muscle has genuinely been skipped ~2 weeks.
    if (worstNever && sessions.length < 3) return const SizedBox.shrink();
    if (!worstNever && worstDays < 14) return const SizedBox.shrink();

    final label = regionLabel(worst);
    final weeks = worstDays ~/ 7;
    final msg = worstNever
        ? 'You haven\'t trained $label yet.'
        : '$label hasn\'t been trained in ${weeks >= 2 ? '$weeks weeks' : '$worstDays days'}.';

    // Compact single-row nudge — the whole card taps through to training.
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: () => _train(context, worst!),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          GlassButton(
            dense: true,
            icon: Icons.fitness_center,
            label: 'Train',
            onPressed: () => _train(context, worst!),
          ),
        ],
      ),
    );
  }

  Future<void> _train(BuildContext context, MuscleRegion region) async {
    final model = context.read<ActiveWorkoutModel>();
    final navigator = Navigator.of(context);
    // Don't clobber an in-progress workout — just reopen it.
    if (model.isActive) {
      navigator.push(
          MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
      return;
    }
    model.start(title: '${regionLabel(region)} Day');
    final picked = await navigator.push<List<Exercise>>(
      MaterialPageRoute(
        builder: (_) =>
            ExercisePickerScreen(initialMuscle: regionFilterToken(region)),
      ),
    );
    if (picked != null && picked.isNotEmpty) model.addExercises(picked);
    navigator.push(
        MaterialPageRoute(builder: (_) => const ActiveWorkoutScreen()));
  }
}
