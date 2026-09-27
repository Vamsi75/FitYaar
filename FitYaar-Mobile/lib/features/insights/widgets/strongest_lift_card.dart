import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';
import '../../workout/active_workout_model.dart' show fmtWeight;
import '../../workout/models/workout_models.dart';
import '../analytics.dart';
import 'mini_line_chart.dart';

/// "Am I getting stronger?" — estimated-1RM trend for one lift, with a delta.
class StrongestLiftCard extends StatefulWidget {
  final List<WorkoutSession> sessions;
  final Map<int, Exercise> catalog;
  const StrongestLiftCard(
      {super.key, required this.sessions, required this.catalog});

  @override
  State<StrongestLiftCard> createState() => _StrongestLiftCardState();
}

class _StrongestLiftCardState extends State<StrongestLiftCard> {
  int? _selectedId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lifts = candidateLifts(widget.sessions, widget.catalog);
    if (lifts.isEmpty) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(theme, 'Your Progress', null),
            const SizedBox(height: 8),
            const Text('Log a lift across a few sessions to see if you\'re getting stronger.',
                style: TextStyle(color: Colors.white60)),
          ],
        ),
      );
    }
    if (_selectedId == null || !lifts.any((l) => l.id == _selectedId)) {
      _selectedId = lifts.first.id;
    }
    final selected = lifts.firstWhere((l) => l.id == _selectedId);
    final series = liftSeries(widget.sessions, _selectedId!);
    final values = series.map((p) => p.value).toList();
    final labels = series.map((p) => _monthLabel(p.date)).toList();

    String deltaText = '';
    Color deltaColor = Colors.white54;
    IconData deltaIcon = Icons.trending_flat;
    if (series.length >= 2) {
      final delta = series.last.value - series.first.value;
      final weeks =
          (series.last.date.difference(series.first.date).inDays / 7).round().clamp(1, 999);
      final sign = delta >= 0 ? '+' : '−';
      deltaText = '$sign${fmtWeight(double.parse(delta.abs().toStringAsFixed(1)))} kg in $weeks ${weeks == 1 ? 'week' : 'weeks'}';
      if (delta > 0.5) {
        deltaColor = Colors.greenAccent;
        deltaIcon = Icons.trending_up;
      } else if (delta < -0.5) {
        deltaColor = Colors.redAccent;
        deltaIcon = Icons.trending_down;
      }
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(theme, 'Your Progress', selected.name),
          const SizedBox(height: 6),
          MiniLineChart(
            values: values,
            labels: labels,
            height: 120,
            color: theme.colorScheme.primary,
            formatY: (v) => v.round().toString(),
          ),
          if (deltaText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(children: [
              Icon(deltaIcon, color: deltaColor, size: 20),
              const SizedBox(width: 6),
              Text(deltaText,
                  style: TextStyle(
                      color: deltaColor, fontWeight: FontWeight.w600, fontSize: 15)),
              const Spacer(),
              const Text('est. 1RM',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _header(ThemeData theme, String small, String? lift) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(small, style: const TextStyle(color: Colors.white60, fontSize: 12)),
        if (lift != null)
          // The lift name itself is the switcher — tap it to pick another lift.
          InkWell(
            onTap: _pickLift,
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(lift,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 22),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _pickLift() async {
    final lifts = candidateLifts(widget.sessions, widget.catalog);
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: const Color(0xFF1A1214),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choose a lift',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final l in lifts)
                    ListTile(
                      title: Text(l.name),
                      subtitle: Text('${l.sessions} sessions'),
                      trailing: l.id == _selectedId
                          ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                          : null,
                      onTap: () => Navigator.pop(ctx, l.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _selectedId = picked);
  }

  String _monthLabel(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return m[d.month - 1];
  }
}
