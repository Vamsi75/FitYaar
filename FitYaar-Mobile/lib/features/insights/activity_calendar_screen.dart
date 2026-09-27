import 'package:flutter/material.dart';

import '../workout/models/workout_models.dart';
import 'rest_day_store.dart';

/// Full activity calendar: workout days (🔥) + marked rest days, viewable a
/// month at a time or the last 3 months. Reached from the weekly-streak card.
class ActivityCalendarScreen extends StatefulWidget {
  final List<WorkoutSession> sessions;
  const ActivityCalendarScreen({super.key, required this.sessions});

  @override
  State<ActivityCalendarScreen> createState() => _ActivityCalendarScreenState();
}

enum _Range { month, threeMonths }

class _ActivityCalendarScreenState extends State<ActivityCalendarScreen> {
  final _store = RestDayStore();
  Set<String> _restDays = {};
  late Set<String> _workoutDays;
  _Range _range = _Range.month;
  late DateTime _anchor; // first-of-month currently shown in month view

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _anchor = DateTime(now.year, now.month, 1);
    _workoutDays = {
      for (final s in widget.sessions)
        if (s.startTime != null) RestDayStore.keyFor(s.startTime!),
    };
    _store.load().then((s) {
      if (mounted) setState(() => _restDays = s);
    });
  }

  Future<void> _toggleRest(DateTime day) async {
    final updated = await _store.toggle(day);
    if (mounted) setState(() => _restDays = updated);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = _range == _Range.month
        ? [_anchor]
        : [
            DateTime(now.year, now.month - 2, 1),
            DateTime(now.year, now.month - 1, 1),
            DateTime(now.year, now.month, 1),
          ];
    return Scaffold(
      appBar: AppBar(title: const Text('Activity')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _rangeToggle(context),
          const SizedBox(height: 16),
          if (_range == _Range.month) _monthNav(context),
          for (final m in months) ...[
            _MonthGrid(
              month: m,
              workoutDays: _workoutDays,
              restDays: _restDays,
              onToggleRest: _toggleRest,
            ),
            const SizedBox(height: 20),
          ],
          _legend(context),
        ],
      ),
    );
  }

  Widget _rangeToggle(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    Widget seg(String label, _Range r) {
      final active = _range == r;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _range = r),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: active ? primary.withValues(alpha: 0.22) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: active
                      ? primary.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.12)),
            ),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    color: active ? Colors.orange.shade200 : Colors.white70,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      );
    }

    return Row(children: [
      seg('This month', _Range.month),
      const SizedBox(width: 10),
      seg('Last 3 months', _Range.threeMonths),
    ]);
  }

  Widget _monthNav(BuildContext context) {
    final now = DateTime.now();
    final atCurrent = _anchor.year == now.year && _anchor.month == now.month;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() =>
                _anchor = DateTime(_anchor.year, _anchor.month - 1, 1)),
          ),
          Text(_monthTitle(_anchor),
              style: Theme.of(context).textTheme.titleMedium),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            // Don't navigate into the future.
            onPressed: atCurrent
                ? null
                : () => setState(() =>
                    _anchor = DateTime(_anchor.year, _anchor.month + 1, 1)),
          ),
        ],
      ),
    );
  }

  Widget _legend(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    Widget item(Widget dot, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          dot,
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ]);
    return Wrap(
      spacing: 18,
      runSpacing: 8,
      children: [
        item(
            CircleAvatar(radius: 8, backgroundColor: primary.withValues(alpha: 0.35), child: const Text('🔥', style: TextStyle(fontSize: 9))),
            'Workout'),
        item(
            CircleAvatar(radius: 8, backgroundColor: Colors.blueGrey.withValues(alpha: 0.30), child: const Icon(Icons.bedtime_outlined, size: 9, color: Colors.white70)),
            'Rest day'),
        const Text('Tap a day to mark rest', style: TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  String _monthTitle(DateTime d) {
    const m = ['January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'];
    return '${m[d.month - 1]} ${d.year}';
  }
}

class _MonthGrid extends StatelessWidget {
  final DateTime month; // first-of-month
  final Set<String> workoutDays;
  final Set<String> restDays;
  final void Function(DateTime) onToggleRest;

  const _MonthGrid({
    required this.month,
    required this.workoutDays,
    required this.restDays,
    required this.onToggleRest,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1; // Mon=1 -> 0 blanks
    final today = DateTime.now();
    final todayKey = RestDayStore.keyFor(today);

    final cells = <Widget>[];
    for (var i = 0; i < leading; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(month.year, month.month, day);
      final key = RestDayStore.keyFor(date);
      final worked = workoutDays.contains(key);
      final rest = restDays.contains(key);
      final isToday = key == todayKey;
      final isFuture = date.isAfter(DateTime(today.year, today.month, today.day));

      Color bg;
      Widget label;
      if (worked) {
        bg = theme.colorScheme.primary.withValues(alpha: 0.32);
        label = const Text('🔥', style: TextStyle(fontSize: 13));
      } else if (rest) {
        bg = Colors.blueGrey.withValues(alpha: 0.28);
        label = const Icon(Icons.bedtime_outlined, size: 13, color: Colors.white70);
      } else {
        bg = Colors.white.withValues(alpha: 0.04);
        label = Text('$day',
            style: TextStyle(
                fontSize: 12,
                color: isFuture ? Colors.white38 : Colors.white70));
      }

      cells.add(GestureDetector(
        onTap: (worked || isFuture) ? null : () => onToggleRest(date),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: isToday
                ? Border.all(color: theme.colorScheme.primary, width: 1.5)
                : Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          alignment: Alignment.center,
          child: label,
        ),
      ));
    }

    // Chunk into weeks of 7.
    final rows = <Widget>[];
    const weekdayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    rows.add(Row(
      children: [
        for (final n in weekdayNames)
          Expanded(
              child: Center(
                  child: Text(n,
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 11)))),
      ],
    ));
    rows.add(const SizedBox(height: 6));
    for (var i = 0; i < cells.length; i += 7) {
      final week = cells.sublist(i, (i + 7).clamp(0, cells.length));
      while (week.length < 7) {
        week.add(const SizedBox.shrink());
      }
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            for (final cell in week)
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(3),
                child: AspectRatio(aspectRatio: 1, child: cell),
              )),
          ],
        ),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_monthTitle(month),
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 10),
        ...rows,
      ],
    );
  }

  String _monthTitle(DateTime d) {
    const m = ['January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December'];
    return '${m[d.month - 1]} ${d.year}';
  }
}
