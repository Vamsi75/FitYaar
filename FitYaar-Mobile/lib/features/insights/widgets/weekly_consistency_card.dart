import 'package:flutter/material.dart';

import '../../../core/widgets/glass_card.dart';
import '../../workout/models/workout_models.dart';
import '../activity_calendar_screen.dart';
import '../analytics.dart';
import '../rest_day_store.dart';

/// Mon–Sun activity strip: 🔥 worked out · rest (marked) · ○ nothing.
class WeeklyConsistencyCard extends StatefulWidget {
  final List<WorkoutSession> sessions;
  const WeeklyConsistencyCard({super.key, required this.sessions});

  @override
  State<WeeklyConsistencyCard> createState() => _WeeklyConsistencyCardState();
}

class _WeeklyConsistencyCardState extends State<WeeklyConsistencyCard> {
  final _store = RestDayStore();
  Set<String> _restDays = {};

  @override
  void initState() {
    super.initState();
    _store.load().then((s) {
      if (mounted) setState(() => _restDays = s);
    });
  }

  Future<void> _openCalendar() async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ActivityCalendarScreen(sessions: widget.sessions)));
    final s = await _store.load();
    if (mounted) setState(() => _restDays = s);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weekStart = startOfWeek();
    final worked = weekWorkoutWeekdays(widget.sessions, weekStart);
    final today = DateTime.now();
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return GlassCard(
      onTap: _openCalendar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('This week', style: theme.textTheme.titleMedium),
            const Spacer(),
            Text('${worked.length} ${worked.length == 1 ? 'workout' : 'workouts'}',
                style: TextStyle(
                    color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
            const SizedBox(width: 4),
            const Icon(Icons.calendar_month, size: 16, color: Colors.white38),
          ]),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(child: _pill(theme, weekStart.add(Duration(days: i)), i + 1,
                    names[i], worked, today)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Tap a day to mark rest · tap the card for the full calendar',
              style: TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _pill(ThemeData theme, DateTime date, int weekday, String label,
      Set<int> worked, DateTime today) {
    final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));
    final didWork = worked.contains(weekday);
    final isRest = _restDays.contains(RestDayStore.keyFor(date));

    Color bg;
    Widget content;
    if (didWork) {
      bg = theme.colorScheme.primary.withValues(alpha: 0.30);
      content = const Text('🔥', style: TextStyle(fontSize: 16));
    } else if (isRest) {
      bg = Colors.blueGrey.withValues(alpha: 0.28);
      content = const Icon(Icons.bedtime_outlined, size: 15, color: Colors.white70);
    } else {
      bg = Colors.white.withValues(alpha: 0.05);
      content = Text('—',
          style: TextStyle(
              color: isFuture ? Colors.white38 : Colors.white54, fontSize: 14));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: InkWell(
        onTap: didWork ? null : () => _toggleRest(date),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              alignment: Alignment.center,
              child: content,
            ),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRest(DateTime date) async {
    final updated = await _store.toggle(date);
    if (mounted) setState(() => _restDays = updated);
  }
}
