import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../insights/analytics.dart' show PrEvent, recentPRs, slugForToken;
import '../../profile/profile_service.dart';
import '../models/workout_models.dart';
import '../workout_service.dart';
import 'share_workout_screen.dart';
import 'workout_share_cards.dart';

/// Body-map intensity for a workout: each working set adds 1 to the exercise's
/// primary muscles and 0.5 to secondary ones, scaled so the busiest muscle is 1.
Map<String, double> muscleIntensityOf(List<LoggedExercise> exercises) {
  final load = <String, double>{};
  for (final le in exercises) {
    final sets = le.sets.where((s) => s.type != WorkoutSetType.warmup).length;
    if (sets == 0) continue;
    final prim = le.exercise.primaryMuscleGroups
        .map(slugForToken)
        .whereType<String>()
        .toSet();
    for (final sl in prim) {
      load[sl] = (load[sl] ?? 0) + sets;
    }
    for (final m in le.exercise.secondaryMuscleGroups) {
      final sl = slugForToken(m);
      if (sl != null && !prim.contains(sl)) {
        load[sl] = (load[sl] ?? 0) + sets * 0.5;
      }
    }
  }
  final max = load.values.fold<double>(0, (a, b) => b > a ? b : a);
  return {for (final e in load.entries) e.key: max == 0 ? 0 : e.value / max};
}

/// PRs set in the workout that started at [start] (matched to the minute).
List<PrEvent> prsForWorkout(List<WorkoutSession> history, DateTime start) {
  bool same(DateTime a) =>
      a.year == start.year &&
      a.month == start.month &&
      a.day == start.day &&
      a.hour == start.hour &&
      a.minute == start.minute;
  return recentPRs(history, days: 36500).where((p) => same(p.date)).toList();
}

/// Month totals, active days and the weekly streak around [date].
MonthRecap buildMonthRecap(List<WorkoutSession> history, DateTime date) {
  var workouts = 0;
  var volume = 0.0;
  var time = Duration.zero;
  final days = <int>{};
  final weeks = <DateTime>{};
  DateTime weekOf(DateTime t) {
    final d = DateTime(t.year, t.month, t.day);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  for (final s in history) {
    final t = s.startTime;
    if (t == null) continue;
    if (!t.isAfter(date.add(const Duration(minutes: 1)))) weeks.add(weekOf(t));
    if (t.year != date.year || t.month != date.month) continue;
    workouts++;
    days.add(t.day);
    final end = s.endTime;
    if (end != null && end.isAfter(t)) time += end.difference(t);
    for (final we in s.exercises) {
      for (final st in we.sets) {
        if (!st.isCompleted || st.type == WorkoutSetType.warmup) continue;
        volume += (st.weight ?? 0) * (st.reps ?? 0);
      }
    }
  }
  var streak = 0;
  var w = weekOf(date);
  while (weeks.contains(w)) {
    streak++;
    w = DateTime(w.year, w.month, w.day - 7);
  }
  return MonthRecap(
    month: date,
    workouts: workouts,
    volumeKg: volume,
    time: time,
    activeDays: days,
    weekStreak: streak,
  );
}

/// Opens the share sheet for a saved session (history / session detail).
Future<void> shareSavedSession(
    BuildContext context, WorkoutSession session) async {
  final workouts = context.read<WorkoutService>();
  final profiles = context.read<ProfileService>();
  final nav = Navigator.of(context);

  // Session exercises don't carry muscle groups — look them up in the catalog.
  Map<int, Exercise> catalog = const {};
  String? gender;
  try {
    final results = await Future.wait([
      workouts.searchExercises(''),
      profiles.getProfile().then((p) => p.gender).catchError((_) => null),
    ]);
    catalog = {for (final e in results[0] as List<Exercise>) e.id: e};
    gender = results[1] as String?;
  } catch (_) {}

  final logged = [
    for (final we in session.exercises)
      LoggedExercise(
        catalog[we.exerciseId] ??
            Exercise(
                id: we.exerciseId,
                name: we.exerciseName ?? 'Exercise',
                exerciseType: we.exerciseType),
        [
          for (final s in we.sets.where((s) => s.isCompleted))
            LoggedSet(
              weight: s.weight,
              reps: s.reps,
              durationSeconds: s.durationSeconds,
              distanceMeters: s.distanceMeters,
              completed: true,
              type: s.type,
            ),
        ],
      ),
  ].where((le) => le.sets.isNotEmpty).toList();

  final start = session.startTime ?? DateTime.now();
  final end = session.endTime ?? start;
  nav.push(MaterialPageRoute(
    builder: (_) => ShareWorkoutScreen(
      data: WorkoutShareData(
        name: session.name ?? 'Workout',
        date: start,
        duration: end.difference(start),
        exercises: logged,
        muscleIntensity: muscleIntensityOf(logged),
        gender: gender,
        metrics: session.healthMetrics,
      ),
    ),
  ));
}
