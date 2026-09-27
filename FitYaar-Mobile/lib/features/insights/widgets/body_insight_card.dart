import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';
import '../../profile/measurement_models.dart';
import '../../workout/active_workout_model.dart' show fmtWeight;
import '../../workout/models/workout_models.dart';
import '../analytics.dart';
import 'mini_line_chart.dart';

/// Body progress: weight trend + plain-language insights ("you lost X kg",
/// plus a strength/volume proxy for muscle built).
class BodyInsightCard extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final List<BodyMeasurement> measurements;
  const BodyInsightCard(
      {super.key, required this.sessions, required this.measurements});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weights =
        measurements.where((m) => m.weightKg != null).toList(); // already asc
    final strengthPct = strengthTrendPct(sessions);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.monitor_weight_outlined,
                color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Body', style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 8),
          if (weights.length < 2)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Add your weight in Profile to track body progress here.',
                  style: TextStyle(color: Colors.white54)),
            )
          else ...[
            MiniLineChart(
              values: weights.map((m) => m.weightKg!).toList(),
              labels: weights.map((m) => _month(m.date)).toList(),
              color: theme.colorScheme.secondary,
              height: 150,
              formatY: (v) => v.toStringAsFixed(0),
            ),
            const SizedBox(height: 10),
            _weightInsight(theme, weights),
          ],
          if (strengthPct.abs() >= 1) ...[
            const SizedBox(height: 8),
            Row(children: [
              Icon(strengthPct >= 0 ? Icons.trending_up : Icons.trending_down,
                  size: 18,
                  color: strengthPct >= 0 ? Colors.greenAccent : Colors.redAccent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Training volume ${strengthPct >= 0 ? 'up' : 'down'} '
                  '${strengthPct.abs().round()}% this month — a proxy for muscle built.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _weightInsight(ThemeData theme, List<BodyMeasurement> weights) {
    final first = weights.first;
    final last = weights.last;
    final delta = last.weightKg! - first.weightKg!;
    final days = last.date.difference(first.date).inDays.clamp(1, 100000);
    final weeks = (days / 7).round().clamp(1, 999);
    final gained = delta > 0;
    final flat = delta.abs() < 0.1;
    final color = flat
        ? Colors.white54
        : (gained ? Colors.orange.shade300 : Colors.greenAccent);
    final icon = flat
        ? Icons.trending_flat
        : (gained ? Icons.arrow_upward : Icons.arrow_downward);
    final text = flat
        ? 'Weight steady at ${fmtWeight(last.weightKg!)} kg'
        : 'You ${gained ? 'gained' : 'lost'} '
            '${fmtWeight(double.parse(delta.abs().toStringAsFixed(1)))} kg in $weeks '
            '${weeks == 1 ? 'week' : 'weeks'}';
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 6),
      Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      const Spacer(),
      Text('now ${fmtWeight(last.weightKg!)} kg',
          style: const TextStyle(color: Colors.white38, fontSize: 12)),
    ]);
  }

  String _month(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[d.month - 1];
  }
}
