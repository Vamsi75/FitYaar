import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../workout/active_workout_model.dart' show fmtWeight;
import '../../workout/models/workout_models.dart';
import '../analytics.dart';

/// Recent personal records — a motivating "look how far you've come" card.
class PrTimelineCard extends StatelessWidget {
  final List<WorkoutSession> sessions;
  const PrTimelineCard({super.key, required this.sessions});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prs = recentPRs(sessions);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('🏆', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(
                prs.isEmpty
                    ? 'Personal records'
                    : '${prs.length} ${prs.length == 1 ? 'PR' : 'PRs'} this month',
                style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 12),
          if (prs.isEmpty)
            const Text('No new PRs in the last 30 days — go set one! 💪',
                style: TextStyle(color: Colors.white54))
          else
            for (final pr in prs.take(6))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(pr.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                    Text('${fmtWeight(pr.weight)} × ${pr.reps}',
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(width: 10),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                          color: AppColors.pr.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                          '↑ +${fmtWeight(double.parse(pr.deltaKg.toStringAsFixed(1)))}kg',
                          style: const TextStyle(
                              color: AppColors.pr,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
