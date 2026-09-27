import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../workout/models/workout_models.dart';
import '../analytics.dart';

/// "Main lifts" — the exercises you perform most, with a times count.
class TopExercisesCard extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final Map<int, Exercise> catalog;
  const TopExercisesCard(
      {super.key, required this.sessions, required this.catalog});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final freq = exerciseFrequency(sessions, catalog);
    final top = freq.take(6).toList();
    final maxTimes = top.isEmpty ? 0 : top.first.times;
    final prNames = {for (final p in recentPRs(sessions)) p.name};

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.repeat, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Main lifts', style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 12),
          if (top.isEmpty)
            const Text('No exercises logged yet',
                style: TextStyle(color: Colors.white54))
          else
            for (final e in top)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Row(children: [
                        Flexible(
                          child: Text(e.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        ),
                        if (prNames.contains(e.name)) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                                color: AppColors.pr.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.pr.withValues(alpha: 0.6))),
                            child: const Text('PR',
                                style: TextStyle(
                                    color: AppColors.pr,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5)),
                          ),
                        ],
                      ]),
                    ),
                    Expanded(
                      flex: 4,
                      child: Stack(children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        FractionallySizedBox(
                          widthFactor:
                              maxTimes == 0 ? 0 : (e.times / maxTimes).clamp(0.05, 1.0),
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4)),
                          ),
                        ),
                      ]),
                    ),
                    SizedBox(
                      width: 64,
                      child: Text('×${e.times}',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
