import 'package:flutter/material.dart';

/// The selectable fitness goals. Four are free; the more advanced, multi-metric
/// goals are gated behind Premium for now.
class GoalOption {
  final String label;
  final String emoji;
  final bool premium;
  const GoalOption(this.label, this.emoji, {this.premium = false});
}

const List<GoalOption> goalOptions = [
  GoalOption('Lose weight', '🔥'),
  GoalOption('Build muscle', '💪'),
  GoalOption('Get stronger', '🏋️'),
  GoalOption('Improve endurance', '🏃'),
  GoalOption('Get fitter', '✨', premium: true),
  GoalOption('Improve mobility', '🧘', premium: true),
  GoalOption('Maintain fitness', '⚖️', premium: true),
  GoalOption('Build consistency', '🔁', premium: true),
];

bool isWeightGoal(String? goal) =>
    goal == 'Lose weight' || goal == 'Build muscle';

/// Shared 2-column frosted-glass goal picker. Active = neon-orange glow fill;
/// inactive = translucent gray; premium = lock badge (taps call [onPremiumTap]).
class GoalPillGrid extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  final VoidCallback? onPremiumTap;

  /// When true, premium goals are selectable (no lock badge).
  final bool isPro;
  const GoalPillGrid({
    super.key,
    required this.selected,
    required this.onSelect,
    this.onPremiumTap,
    this.isPro = false,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.7,
      children: [
        for (final g in goalOptions) _pill(g, primary),
      ],
    );
  }

  Widget _pill(GoalOption g, Color primary) {
    final active = selected == g.label;
    final locked = g.premium && !isPro;
    return GestureDetector(
      onTap: () => locked ? onPremiumTap?.call() : onSelect(g.label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? primary.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: active
                  ? primary.withValues(alpha: 0.9)
                  : Colors.white.withValues(alpha: 0.12)),
          boxShadow: active
              ? [BoxShadow(color: primary.withValues(alpha: 0.4), blurRadius: 14, spreadRadius: -3)]
              : null,
        ),
        child: Row(
          children: [
            Opacity(
                opacity: locked ? 0.6 : 1,
                child: Text(g.emoji, style: const TextStyle(fontSize: 18))),
            const SizedBox(width: 8),
            Expanded(
              child: Text(g.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: locked ? Colors.white54 : Colors.white)),
            ),
            if (locked)
              const Icon(Icons.lock, size: 14, color: Colors.amber)
            else if (active)
              Icon(Icons.check_circle, size: 16, color: primary),
          ],
        ),
      ),
    );
  }
}
