import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/widgets/glass_button.dart';
import '../../../core/widgets/glass_card.dart';
import '../../workout/models/workout_models.dart';
import '../analytics.dart';

/// A shareable one-month recap. Share copies the recap text for now (a native
/// share sheet can replace the clipboard call later).
class MonthlyRecapCard extends StatelessWidget {
  final List<WorkoutSession> sessions;
  final Map<int, Exercise> catalog;
  const MonthlyRecapCard(
      {super.key, required this.sessions, required this.catalog});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recap = buildMonthlyRecap(sessions, catalog);
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.auto_awesome, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Monthly recap', style: theme.textTheme.titleMedium),
          ]),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Text(recap,
                style: const TextStyle(height: 1.5, color: Colors.white70)),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: GlassButton(
              icon: Icons.ios_share,
              label: 'Share recap',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: recap));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Recap copied to clipboard')));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
