import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';
import '../../workout/models/workout_models.dart';
import '../analytics.dart';
import 'muscle_body.dart';

/// FitYaar's signature muscle heatmap: real per-muscle vector art (front + back
/// together, male/female) with each trained muscle filling in glass-orange by
/// weekly volume. Muscle paths are MIT (react-native-body-highlighter).
class MuscleMapCard extends StatefulWidget {
  final List<WorkoutSession> sessions;
  final Map<int, Exercise> catalog;
  final String? gender;
  const MuscleMapCard({
    super.key,
    required this.sessions,
    required this.catalog,
    this.gender,
  });

  @override
  State<MuscleMapCard> createState() => _MuscleMapCardState();
}

class _MuscleMapCardState extends State<MuscleMapCard> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekStart = startOfWeek();
    final load = weeklyMuscleLoad(widget.sessions, widget.catalog, weekStart);
    final maxLoad = load.values.fold<double>(0, (a, b) => b > a ? b : a);
    // Header total = actual working sets this week.
    var total = 0;
    for (final s in widget.sessions) {
      final t = s.startTime;
      if (t == null || t.isBefore(weekStart)) continue;
      for (final we in s.exercises) {
        total += we.sets.where((st) => st.type != WorkoutSetType.warmup).length;
      }
    }
    final intensity = {
      for (final e in load.entries)
        e.key: maxLoad == 0 ? 0.0 : e.value / maxLoad,
    };
    final ordered = load.keys.toList()
      ..sort((a, b) => load[b]!.compareTo(load[a]!));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.accessibility_new, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Muscle map', style: theme.textTheme.titleMedium),
            const Spacer(),
            Text('$total sets this week',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          MuscleBody(
            intensity: intensity,
            gender: widget.gender,
            selected: _selected,
            height: 290,
            onTapMuscle: (m) => setState(() => _selected = m),
          ),
          const SizedBox(height: 12),
          if (total == 0)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text('No sets logged this week yet — the body stays dim.',
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
            )
          else ...[
            if (_selected != null && load[_selected] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${muscleSlugLabel[_selected!] ?? _selected!} — ${load[_selected!]!.round()} sets this week',
                  style: TextStyle(
                      color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                ),
              ),
            for (final slug in ordered) _bar(theme, slug, load[slug]!, maxLoad),
          ],
        ],
      ),
    );
  }

  Widget _bar(ThemeData theme, String slug, double loadVal, double maxLoad) {
    final frac = maxLoad == 0 ? 0.0 : loadVal / maxLoad;
    final selected = _selected == slug;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () => setState(() => _selected = selected ? null : slug),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            SizedBox(
                width: 82,
                child: Text(muscleSlugLabel[slug] ?? slug,
                    style: TextStyle(
                        fontSize: 13,
                        color: selected ? theme.colorScheme.primary : Colors.white70))),
            Expanded(
              child: Stack(children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(6)),
                ),
                FractionallySizedBox(
                  widthFactor: frac.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: 0.35 + 0.55 * frac),
                        borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ]),
            ),
            const SizedBox(width: 8),
            SizedBox(
                width: 22,
                child: Text('${loadVal.round()}',
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 13, color: Colors.white70))),
          ],
        ),
      ),
    );
  }
}
