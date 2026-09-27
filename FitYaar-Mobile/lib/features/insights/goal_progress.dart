import 'package:flutter/material.dart';

import '../../core/widgets/glass_card.dart';
import '../profile/measurement_models.dart';
import '../workout/models/workout_models.dart';
import 'analytics.dart';

enum GoalStatus { onTrack, behind, off }

String goalStatusLabel(GoalStatus s) => switch (s) {
      GoalStatus.onTrack => 'On track',
      GoalStatus.behind => 'Slightly behind',
      GoalStatus.off => 'Off track',
    };

Color goalStatusColor(GoalStatus s) => switch (s) {
      GoalStatus.onTrack => Colors.greenAccent,
      GoalStatus.behind => Colors.amber,
      GoalStatus.off => Colors.redAccent,
    };

/// A goal-aware progress summary + status + next action.
class GoalProgress {
  final String title;
  final String message;
  final String cheer;
  final GoalStatus status;
  final String nextAction;
  final double? fraction; // 0..1 for weight goals
  final IconData icon;
  const GoalProgress({
    required this.title,
    required this.message,
    required this.cheer,
    required this.status,
    required this.nextAction,
    required this.icon,
    this.fraction,
  });
}

double _minutesBetween(List<WorkoutSession> sessions, DateTime from, DateTime to) {
  var m = 0.0;
  for (final s in sessions) {
    final st = s.startTime, en = s.endTime;
    if (st == null || en == null) continue;
    if (!st.isBefore(from) && st.isBefore(to)) m += en.difference(st).inMinutes;
  }
  return m;
}

/// 7-day rolling average of the most recent weights (smooths water swings),
/// falling back to the profile's stored weight.
double? _smoothedLatestWeight(List<BodyMeasurement> ms, double? profileWeight) {
  final w = ms.where((m) => m.weightKg != null).toList();
  if (w.isEmpty) return profileWeight;
  final cutoff = w.last.date.subtract(const Duration(days: 7));
  final recent = w.where((m) => !m.date.isBefore(cutoff)).map((m) => m.weightKg!);
  if (recent.isEmpty) return w.last.weightKg;
  return recent.reduce((a, b) => a + b) / recent.length;
}

double? _weightDaysAgo(List<BodyMeasurement> ms, int days) {
  final cutoff = DateTime.now().subtract(Duration(days: days));
  double? before;
  double? earliest;
  for (final m in ms) {
    if (m.weightKg == null) continue;
    earliest ??= m.weightKg;
    if (!m.date.isAfter(cutoff)) before = m.weightKg;
  }
  return before ?? earliest;
}

/// Signed weight change per week over ~the last 30 days (negative = losing).
double? weeklyWeightChangeKg(List<BodyMeasurement> ms) {
  final w = ms.where((m) => m.weightKg != null).toList();
  if (w.length < 2) return null;
  final cutoff = DateTime.now().subtract(const Duration(days: 30));
  BodyMeasurement? base;
  for (final m in w) {
    if (!m.date.isAfter(cutoff)) base = m;
  }
  base ??= w.first;
  final latest = w.last;
  final days = latest.date.difference(base.date).inDays;
  if (days <= 0) return null;
  return (latest.weightKg! - base.weightKg!) / (days / 7.0);
}

class WeightEta {
  final double ratePerWeek;
  final double? weeks;
  final DateTime? date;
  final bool onTrack;
  final bool reached;
  const WeightEta(
      {required this.ratePerWeek,
      this.weeks,
      this.date,
      required this.onTrack,
      required this.reached});
}

WeightEta? weightEta({
  required bool isLoss,
  double? latest,
  double? target,
  required List<BodyMeasurement> measurements,
}) {
  if (latest == null || target == null) return null;
  final toGo = isLoss ? latest - target : target - latest;
  if (toGo <= 0.1) {
    return const WeightEta(ratePerWeek: 0, onTrack: true, reached: true);
  }
  final change = weeklyWeightChangeKg(measurements);
  if (change == null) return null;
  final rate = isLoss ? -change : change;
  if (rate <= 0.05) {
    return WeightEta(ratePerWeek: rate, onTrack: false, reached: false);
  }
  final weeks = toGo / rate;
  final date = DateTime.now().add(Duration(days: (weeks * 7).round()));
  return WeightEta(
      ratePerWeek: rate, weeks: weeks, date: date, onTrack: true, reached: false);
}

/// Builds a goal-tailored progress read-out. Returns null if there's nothing
/// meaningful to say yet.
GoalProgress? buildGoalProgress({
  required String? goal,
  double? profileCurrentWeight,
  double? targetWeight,
  required List<BodyMeasurement> measurements,
  required List<WorkoutSession> sessions,
}) {
  final g = (goal ?? '').toLowerCase();
  final now = DateTime.now();

  String fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  // ---- Weight loss / gain ----
  final isLoss = g.contains('lose') || g.contains('loss');
  final isGain = g.contains('muscle') || g.contains('gain') || g.contains('bulk');
  if (isLoss || isGain) {
    final latest = _smoothedLatestWeight(measurements, profileCurrentWeight);
    final start = measurements.isNotEmpty
        ? _weightDaysAgo(measurements, 100000)
        : profileCurrentWeight;
    final w30 = _weightDaysAgo(measurements, 30);
    final delta30 = (latest != null && w30 != null) ? latest - w30 : null;
    double? fraction;
    if (start != null && targetWeight != null && latest != null && start != targetWeight) {
      fraction = ((start - latest) / (start - targetWeight)).clamp(0.0, 1.0);
    }
    final eta = weightEta(
        isLoss: isLoss, latest: latest, target: targetWeight, measurements: measurements);

    final parts = <String>[];
    if (delta30 != null && delta30.abs() >= 0.1) {
      final moved = delta30.abs();
      if (isLoss) {
        parts.add(delta30 < 0
            ? 'You lost ${fmt(moved)} kg in the last 30 days.'
            : 'Up ${fmt(moved)} kg lately — let\'s turn it around.');
      } else {
        parts.add(delta30 > 0
            ? 'You gained ${fmt(moved)} kg in the last 30 days.'
            : 'Down ${fmt(moved)} kg lately — fuel up and push.');
      }
    }
    if (latest != null && targetWeight != null) {
      final toGo = isLoss ? latest - targetWeight : targetWeight - latest;
      parts.add(toGo > 0.1 ? '${fmt(toGo)} kg to go 🎯' : 'Target reached — incredible! 🎉');
    }
    if (parts.isEmpty) {
      parts.add(isLoss ? 'Log your weight to track the drop.' : 'Log your weight to track the gains.');
    }

    GoalStatus status;
    String next;
    final wrongWay = delta30 != null &&
        ((isLoss && delta30 > 0.15) || (isGain && delta30 < -0.15));
    if (eta?.reached == true) {
      status = GoalStatus.onTrack;
      next = 'Target hit — set a new goal to keep the momentum.';
    } else if (wrongWay) {
      status = GoalStatus.off;
      next = isLoss
          ? 'Refocus: a small calorie deficit + 3 workouts this week.'
          : 'Eat in a slight surplus and hit 3–4 lifting sessions.';
    } else if (eta?.onTrack == true) {
      status = GoalStatus.onTrack;
      next = 'Keep the same pace — you\'re trending to target.';
    } else {
      status = GoalStatus.behind;
      next = isLoss
          ? 'Tighten nutrition and add a workout to speed things up.'
          : 'Add a little more food and volume to grow faster.';
    }

    return GoalProgress(
      title: isLoss ? 'Weight loss' : 'Muscle gain',
      message: parts.join('  '),
      cheer: isLoss ? 'Every session counts 🔥' : 'Eat, lift, grow 💪',
      status: status,
      nextAction: next,
      icon: Icons.flag_outlined,
      fraction: fraction,
    );
  }

  // ---- Endurance ----
  if (g.contains('endur') || g.contains('cardio') || g.contains('stamina')) {
    final cur = _minutesBetween(sessions, now.subtract(const Duration(days: 30)), now);
    final prev = _minutesBetween(sessions,
        now.subtract(const Duration(days: 60)), now.subtract(const Duration(days: 30)));
    final hours = cur / 60;
    final pct = prev > 0 ? ((cur - prev) / prev * 100).round() : null;
    final trend = pct == null
        ? ''
        : (pct >= 0 ? '  (+$pct% vs last month)' : '  ($pct% vs last month)');
    final status = cur <= 0
        ? GoalStatus.off
        : (prev > 0 && cur < prev * 0.9 ? GoalStatus.behind : GoalStatus.onTrack);
    return GoalProgress(
      title: 'Endurance',
      message: 'You trained ${hours.toStringAsFixed(1)}h this month$trend',
      cheer: 'Keep the engine running 🏃',
      status: status,
      nextAction: status == GoalStatus.onTrack
          ? 'Add one interval session to push your pace.'
          : 'Get a couple of cardio sessions in this week.',
      icon: Icons.directions_run,
    );
  }

  // ---- Strength (volume trend as a proxy until per-lift targets land) ----
  if (g.contains('strength') || g.contains('strong') || g.contains('power')) {
    final pct = strengthTrendPct(sessions).round();
    final hasData = sessions.any((s) => s.startTime != null);
    final steady = pct >= -2 && pct <= 2;
    // Holding your base is fine — only a real sustained drop reads as off-track,
    // so finishing a normal session never greets you with a discouraging tag.
    final status = !hasData
        ? GoalStatus.behind
        : (pct < -2 ? GoalStatus.off : GoalStatus.onTrack);
    return GoalProgress(
      title: 'Strength',
      message: !hasData || pct == 0
          ? 'Log a few sessions to see your strength trend.'
          : steady
              ? 'Volume steady — you\'re holding your base.'
              : 'Your training volume is ${pct >= 0 ? 'up' : 'down'} ${pct.abs()}% this month',
      cheer: 'Progressive overload wins 💪',
      status: status,
      nextAction: 'Add weight or a rep to your main lifts this week.',
      icon: Icons.fitness_center,
    );
  }

  // ---- Get fitter / maintain / consistency / default ----
  final month = sessions
      .where((s) => s.startTime != null &&
          s.startTime!.isAfter(now.subtract(const Duration(days: 30))))
      .length;
  if (month == 0 && sessions.isEmpty) return null;
  final status = month >= 12
      ? GoalStatus.onTrack
      : (month >= 6 ? GoalStatus.behind : GoalStatus.off);
  return GoalProgress(
    title: 'Consistency',
    message: '$month ${month == 1 ? 'workout' : 'workouts'} in the last 30 days',
    cheer: 'Consistency is everything 🔥',
    status: status,
    nextAction: 'Aim for 3–4 sessions a week to stay sharp.',
    icon: Icons.local_fire_department,
  );
}

/// Renders a [GoalProgress] as a glass card with a status pill + next action.
class GoalProgressCard extends StatelessWidget {
  final GoalProgress progress;
  const GoalProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sc = goalStatusColor(progress.status);
    return GlassCard(
      tint: theme.colorScheme.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(progress.icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(progress.title,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: sc.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.circle, size: 8, color: sc),
                const SizedBox(width: 6),
                Text(goalStatusLabel(progress.status),
                    style: TextStyle(color: sc, fontWeight: FontWeight.w600, fontSize: 12)),
              ]),
            ),
          ]),
          const SizedBox(height: 8),
          Text(progress.message,
              style: const TextStyle(fontSize: 15, color: Colors.white)),
          if (progress.fraction != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress.fraction,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            const SizedBox(height: 4),
            Text('${(progress.fraction! * 100).round()}% to goal',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.bolt, size: 16, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Next: ${progress.nextAction}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ),
            ]),
          ),
          const SizedBox(height: 8),
          Text(progress.cheer,
              style: TextStyle(
                  color: Colors.orange.shade200,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }
}
