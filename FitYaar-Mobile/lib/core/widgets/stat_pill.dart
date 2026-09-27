import 'package:flutter/material.dart';

import 'glass_card.dart';

/// A compact metric: a bold, high-contrast number over a small muted UPPERCASE
/// label (e.g. "12" / "WORKOUTS"). Used for the Home dashboard stat row.
class StatPill extends StatelessWidget {
  final String value;
  final String label;
  const StatPill({super.key, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800, height: 1)),
          const SizedBox(height: 4),
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6)),
        ],
      ),
    );
  }
}
