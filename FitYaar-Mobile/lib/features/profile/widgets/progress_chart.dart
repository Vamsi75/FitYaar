import 'package:flutter/material.dart';

import '../../workout/models/workout_models.dart';

enum ProgressMetric { volume, duration, reps }

String metricLabel(ProgressMetric m) => switch (m) {
      ProgressMetric.volume => 'Volume',
      ProgressMetric.duration => 'Duration',
      ProgressMetric.reps => 'Reps',
    };

String metricUnit(ProgressMetric m) => switch (m) {
      ProgressMetric.volume => 'kg',
      ProgressMetric.duration => 'min',
      ProgressMetric.reps => 'reps',
    };

double sessionMetric(WorkoutSession s, ProgressMetric m) {
  switch (m) {
    case ProgressMetric.volume:
      return (s.totalVolume ?? 0).toDouble();
    case ProgressMetric.duration:
      if (s.startTime != null && s.endTime != null) {
        return s.endTime!.difference(s.startTime!).inMinutes.toDouble();
      }
      return 0;
    case ProgressMetric.reps:
      var r = 0;
      for (final e in s.exercises) {
        for (final st in e.sets) {
          r += st.reps ?? 0;
        }
      }
      return r.toDouble();
  }
}

/// Lightweight bucketed bar chart (dates on x, metric on y). Avoids external
/// chart-lib API risk; renders with plain widgets in the glass palette.
class ProgressChart extends StatelessWidget {
  final List<WorkoutSession> sessions; // already filtered to [start, end]
  final DateTime start;
  final DateTime end;
  final ProgressMetric metric;

  const ProgressChart({
    super.key,
    required this.sessions,
    required this.start,
    required this.end,
    required this.metric,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const buckets = 6;
    final totalMs = end.difference(start).inMilliseconds;
    final bucketMs = totalMs <= 0 ? 1 : (totalMs / buckets).round();
    final values = List<double>.filled(buckets, 0);

    for (final s in sessions) {
      final t = s.startTime;
      if (t == null) continue;
      var idx = (t.difference(start).inMilliseconds / bucketMs).floor();
      idx = idx.clamp(0, buckets - 1);
      values[idx] += sessionMetric(s, metric);
    }

    final maxVal = values.fold<double>(0, (a, b) => b > a ? b : a);
    if (maxVal <= 0) {
      return const SizedBox(
        height: 170,
        child: Center(
          child: Text('No data in this range yet',
              style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < buckets; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(values[i] == 0 ? '' : _short(values[i]),
                          maxLines: 1,
                          style: const TextStyle(fontSize: 10, color: Colors.white70)),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: (values[i] / maxVal) * 120 + (values[i] > 0 ? 4 : 0),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.primary.withValues(alpha: 0.35),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(_dateLabel(start.add(Duration(milliseconds: bucketMs * i))),
                        style:
                            const TextStyle(fontSize: 10, color: Colors.white54)),
                  ],
                ),
              ),
            ),
        ],
        ),
      ),
    );
  }

  String _short(double v) =>
      v >= 1000 ? '${(v / 1000).toStringAsFixed(1)}k' : v.round().toString();

  String _dateLabel(DateTime d) {
    const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${m[d.month - 1]}';
  }
}
