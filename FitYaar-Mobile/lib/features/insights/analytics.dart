import '../workout/active_workout_model.dart' show estimate1RM;
import '../workout/models/workout_models.dart';

/// Pure analytics derived from workout history + the exercise catalog.
/// History has no muscle group, so callers pass a `catalog` (exerciseId -> Exercise).

enum MuscleRegion { chest, back, shoulders, arms, core, legs }

String regionLabel(MuscleRegion r) => switch (r) {
      MuscleRegion.chest => 'Chest',
      MuscleRegion.back => 'Back',
      MuscleRegion.shoulders => 'Shoulders',
      MuscleRegion.arms => 'Arms',
      MuscleRegion.core => 'Core',
      MuscleRegion.legs => 'Legs',
    };

/// A representative MuscleGroup token for filtering the exercise picker.
String regionFilterToken(MuscleRegion r) => switch (r) {
      MuscleRegion.chest => 'CHEST',
      MuscleRegion.back => 'LATS',
      MuscleRegion.shoulders => 'SIDE_DELTS',
      MuscleRegion.arms => 'BICEPS',
      MuscleRegion.core => 'ABS',
      MuscleRegion.legs => 'QUADRICEPS',
    };

MuscleRegion? regionForToken(String token) {
  switch (token.toUpperCase()) {
    case 'UPPER_CHEST':
    case 'CHEST':
    case 'LOWER_CHEST':
      return MuscleRegion.chest;
    case 'LATS':
    case 'UPPER_BACK':
    case 'TRAPS':
    case 'LOWER_BACK':
      return MuscleRegion.back;
    case 'FRONT_DELTS':
    case 'SIDE_DELTS':
    case 'REAR_DELTS':
      return MuscleRegion.shoulders;
    case 'BICEPS':
    case 'TRICEPS':
    case 'FOREARMS':
      return MuscleRegion.arms;
    case 'ABS':
    case 'OBLIQUES':
      return MuscleRegion.core;
    case 'QUADRICEPS':
    case 'HAMSTRINGS':
    case 'GLUTES':
    case 'CALVES':
      return MuscleRegion.legs;
    default:
      return null;
  }
}

// ── Fine-grained per-muscle model (drives the anatomical heatmap) ────────────
// Backend MuscleGroup token -> body-map slug (the SVG shape it highlights). Some
// enums share one shape because the silhouette can't split them: front/side/rear
// delts -> "deltoids", the three chest regions -> "chest", and LATS folds into
// "upper-back" (there is no separate lats shape).
const Map<String, String> muscleGroupToSlug = {
  'UPPER_CHEST': 'chest', 'CHEST': 'chest', 'LOWER_CHEST': 'chest',
  'FRONT_DELTS': 'deltoids', 'SIDE_DELTS': 'deltoids', 'REAR_DELTS': 'deltoids',
  'BICEPS': 'biceps', 'TRICEPS': 'triceps', 'FOREARMS': 'forearm',
  'LATS': 'upper-back', 'UPPER_BACK': 'upper-back', 'TRAPS': 'trapezius',
  'LOWER_BACK': 'lower-back', 'ABS': 'abs', 'OBLIQUES': 'obliques',
  'QUADRICEPS': 'quadriceps', 'HAMSTRINGS': 'hamstring', 'GLUTES': 'gluteal',
  'CALVES': 'calves', 'NECK': 'neck',
};

/// Display label for each highlightable muscle slug.
const Map<String, String> muscleSlugLabel = {
  'chest': 'Chest', 'deltoids': 'Shoulders', 'biceps': 'Biceps',
  'triceps': 'Triceps', 'forearm': 'Forearms', 'upper-back': 'Back',
  'trapezius': 'Traps', 'lower-back': 'Lower back', 'abs': 'Abs',
  'obliques': 'Obliques', 'quadriceps': 'Quads', 'hamstring': 'Hamstrings',
  'gluteal': 'Glutes', 'calves': 'Calves', 'neck': 'Neck',
};

String? slugForToken(String token) => muscleGroupToSlug[token.toUpperCase()];

/// Weighted weekly "muscle load" per body-map slug: each working set adds 1.0 to
/// its exercise's primary muscles and 0.5 to secondary muscles. Feeds the
/// anatomical heatmap + the per-muscle bars.
Map<String, double> weeklyMuscleLoad(
    List<WorkoutSession> sessions, Map<int, Exercise> catalog, DateTime weekStart) {
  final load = <String, double>{};
  for (final s in sessions) {
    final t = s.startTime;
    if (t == null || t.isBefore(weekStart)) continue;
    for (final we in s.exercises) {
      final ex = catalog[we.exerciseId];
      if (ex == null) continue;
      final sets = we.sets.where(_isWorking).length;
      if (sets == 0) continue;
      final prim = <String>{};
      for (final m in ex.primaryMuscleGroups) {
        final sl = slugForToken(m);
        if (sl != null) prim.add(sl);
      }
      final sec = <String>{};
      for (final m in ex.secondaryMuscleGroups) {
        final sl = slugForToken(m);
        if (sl != null && !prim.contains(sl)) sec.add(sl);
      }
      for (final sl in prim) {
        load[sl] = (load[sl] ?? 0) + sets;
      }
      for (final sl in sec) {
        load[sl] = (load[sl] ?? 0) + sets * 0.5;
      }
    }
  }
  return load;
}

MuscleRegion? _primaryRegion(Exercise? ex) {
  if (ex == null) return null;
  for (final m in ex.primaryMuscleGroups) {
    final r = regionForToken(m);
    if (r != null) return r;
  }
  for (final m in ex.secondaryMuscleGroups) {
    final r = regionForToken(m);
    if (r != null) return r;
  }
  return null;
}

bool _isWorking(SetEntryModel s) => s.type != WorkoutSetType.warmup;

/// Monday 00:00 of the week containing [now] (defaults to today).
DateTime startOfWeek([DateTime? now]) {
  final d = now ?? DateTime.now();
  final date = DateTime(d.year, d.month, d.day);
  return date.subtract(Duration(days: date.weekday - 1));
}

/// Working-set counts per region for sessions on/after [weekStart].
Map<MuscleRegion, int> weeklyRegionSets(
    List<WorkoutSession> sessions, Map<int, Exercise> catalog, DateTime weekStart) {
  final counts = {for (final r in MuscleRegion.values) r: 0};
  for (final s in sessions) {
    final t = s.startTime;
    if (t == null || t.isBefore(weekStart)) continue;
    for (final we in s.exercises) {
      final region = _primaryRegion(catalog[we.exerciseId]);
      if (region == null) continue;
      counts[region] = counts[region]! + we.sets.where(_isWorking).length;
    }
  }
  return counts;
}

/// Most recent date each region was trained.
Map<MuscleRegion, DateTime> lastTrainedByRegion(
    List<WorkoutSession> sessions, Map<int, Exercise> catalog) {
  final map = <MuscleRegion, DateTime>{};
  for (final s in sessions) {
    final t = s.startTime;
    if (t == null) continue;
    for (final we in s.exercises) {
      final r = _primaryRegion(catalog[we.exerciseId]);
      if (r == null) continue;
      final cur = map[r];
      if (cur == null || t.isAfter(cur)) map[r] = t;
    }
  }
  return map;
}

class LiftPoint {
  final DateTime date;
  final double value; // estimated 1RM
  LiftPoint(this.date, this.value);
}

/// Best estimated 1RM per session for one exercise, oldest → newest.
List<LiftPoint> liftSeries(List<WorkoutSession> sessions, int exerciseId) {
  final pts = <LiftPoint>[];
  for (final s in sessions) {
    final t = s.startTime;
    if (t == null) continue;
    var best = 0.0;
    for (final we in s.exercises) {
      if (we.exerciseId != exerciseId) continue;
      for (final st in we.sets) {
        if (!_isWorking(st)) continue;
        final e = estimate1RM(st.weight, st.reps);
        if (e > best) best = e;
      }
    }
    if (best > 0) pts.add(LiftPoint(t, best));
  }
  pts.sort((a, b) => a.date.compareTo(b.date));
  return pts;
}

class LiftOption {
  final int id;
  final String name;
  final int sessions;
  LiftOption(this.id, this.name, this.sessions);
}

const _keyLiftHints = ['bench', 'squat', 'deadlift', 'overhead', 'ohp', 'pull up', 'pull-up'];

int _keyRank(String name) {
  final n = name.toLowerCase();
  for (var i = 0; i < _keyLiftHints.length; i++) {
    if (n.contains(_keyLiftHints[i])) return i;
  }
  return _keyLiftHints.length;
}

/// Lifts with at least [minSessions] sessions of data, key lifts first.
List<LiftOption> candidateLifts(List<WorkoutSession> sessions, Map<int, Exercise> catalog,
    {int minSessions = 2}) {
  final sessionCount = <int, int>{};
  final names = <int, String>{};
  for (final s in sessions) {
    final seen = <int>{};
    for (final we in s.exercises) {
      seen.add(we.exerciseId);
      names[we.exerciseId] =
          we.exerciseName ?? catalog[we.exerciseId]?.name ?? 'Exercise';
    }
    for (final id in seen) {
      sessionCount[id] = (sessionCount[id] ?? 0) + 1;
    }
  }
  final opts = sessionCount.entries
      .where((e) => e.value >= minSessions)
      .map((e) => LiftOption(e.key, names[e.key]!, e.value))
      .toList();
  opts.sort((a, b) {
    final ka = _keyRank(a.name), kb = _keyRank(b.name);
    if (ka != kb) return ka.compareTo(kb);
    if (a.sessions != b.sessions) return b.sessions.compareTo(a.sessions);
    return a.name.compareTo(b.name);
  });
  return opts;
}

class PrEvent {
  final String name;
  final double weight;
  final int reps;
  final double deltaKg; // 1RM improvement over the previous best
  final DateTime date;
  PrEvent(this.name, this.weight, this.reps, this.deltaKg, this.date);
}

/// PR events (new all-time best estimated 1RM) landing within the last [days].
List<PrEvent> recentPRs(List<WorkoutSession> sessions, {int days = 30}) {
  final sorted = [...sessions.where((s) => s.startTime != null)]
    ..sort((a, b) => a.startTime!.compareTo(b.startTime!));
  final best = <int, double>{};
  final events = <PrEvent>[];
  final cutoff = DateTime.now().subtract(Duration(days: days));
  for (final s in sorted) {
    final perEx = <int, ({double v, double w, int r, String name})>{};
    for (final we in s.exercises) {
      for (final st in we.sets) {
        if (!_isWorking(st)) continue;
        final e = estimate1RM(st.weight, st.reps);
        if (e <= 0) continue;
        final cur = perEx[we.exerciseId];
        if (cur == null || e > cur.v) {
          perEx[we.exerciseId] = (
            v: e,
            w: st.weight ?? 0,
            r: st.reps ?? 0,
            name: we.exerciseName ?? 'Exercise'
          );
        }
      }
    }
    perEx.forEach((id, rec) {
      final prev = best[id];
      if (prev == null || rec.v > prev + 0.01) {
        if (prev != null && !s.startTime!.isBefore(cutoff)) {
          events.add(PrEvent(rec.name, rec.w, rec.r, rec.v - prev, s.startTime!));
        }
        best[id] = rec.v;
      }
    });
  }
  events.sort((a, b) => b.date.compareTo(a.date));
  return events;
}

class ExerciseFreq {
  final String name;
  final int times; // sessions that included this exercise
  ExerciseFreq(this.name, this.times);
}

/// Most-performed exercises (by number of sessions), most frequent first.
List<ExerciseFreq> exerciseFrequency(
    List<WorkoutSession> sessions, Map<int, Exercise> catalog) {
  final count = <int, int>{};
  final names = <int, String>{};
  for (final s in sessions) {
    final seen = <int>{};
    for (final we in s.exercises) {
      names[we.exerciseId] =
          we.exerciseName ?? catalog[we.exerciseId]?.name ?? 'Exercise';
      seen.add(we.exerciseId);
    }
    for (final id in seen) {
      count[id] = (count[id] ?? 0) + 1;
    }
  }
  final list = count.entries.map((e) => ExerciseFreq(names[e.key]!, e.value)).toList();
  list.sort((a, b) => b.times.compareTo(a.times));
  return list;
}

/// Working-set counts per region for sessions on/after [since].
Map<MuscleRegion, int> regionSetsSince(
        List<WorkoutSession> sessions, Map<int, Exercise> catalog, DateTime since) =>
    weeklyRegionSets(sessions, catalog, since);

/// Volume trend: last 30 days vs the prior 30 days, as a percentage.
/// Used as a "muscle built" proxy (real muscle isn't directly measured).
double strengthTrendPct(List<WorkoutSession> sessions) {
  final now = DateTime.now();
  final last30 = now.subtract(const Duration(days: 30));
  final prev30 = now.subtract(const Duration(days: 60));
  var cur = 0.0, prev = 0.0;
  for (final s in sessions) {
    final t = s.startTime;
    if (t == null) continue;
    final v = (s.totalVolume ?? 0).toDouble();
    if (!t.isBefore(last30)) {
      cur += v;
    } else if (!t.isBefore(prev30)) {
      prev += v;
    }
  }
  if (prev <= 0) return 0;
  return (cur - prev) / prev * 100;
}

/// Shareable one-month recap text.
String buildMonthlyRecap(List<WorkoutSession> sessions, Map<int, Exercise> catalog) {
  final since = DateTime.now().subtract(const Duration(days: 30));
  final month =
      sessions.where((s) => s.startTime != null && !s.startTime!.isBefore(since));
  final workouts = month.length;
  final volume = month.fold<int>(0, (a, s) => a + (s.totalVolume ?? 0));
  final prs = recentPRs(sessions, days: 30).length;
  final regionSets = regionSetsSince(sessions, catalog, since);
  MuscleRegion? top;
  var topN = 0;
  regionSets.forEach((r, n) {
    if (n > topN) {
      topN = n;
      top = r;
    }
  });
  final volStr =
      volume >= 1000 ? '${(volume / 1000).toStringAsFixed(1)}t' : '$volume kg';
  final b = StringBuffer()
    ..writeln('💪 My FitYaar month')
    ..writeln('• $workouts workouts')
    ..writeln('• $volStr lifted');
  if (top != null) b.writeln('• Top focus: ${regionLabel(top!)}');
  b
    ..writeln('• $prs new ${prs == 1 ? 'PR' : 'PRs'}')
    ..write('Tracked with FitYaar 🇮🇳');
  return b.toString();
}

/// Weekly training volume (kg) for the last [weeks] ISO weeks, oldest → newest.
List<double> weeklyVolumeSeries(List<WorkoutSession> sessions, {int weeks = 12}) {
  final thisWeek = startOfWeek();
  final out = List<double>.filled(weeks, 0);
  for (final s in sessions) {
    final t = s.startTime;
    if (t == null) continue;
    final ago = thisWeek.difference(startOfWeek(t)).inDays ~/ 7;
    if (ago < 0 || ago >= weeks) continue;
    out[weeks - 1 - ago] += (s.totalVolume ?? 0).toDouble();
  }
  return out;
}

class DayVolume {
  final DateTime day;
  final double volume;
  DayVolume(this.day, this.volume);
}

/// Per-day training volume for the last [days] days, oldest → newest.
List<DayVolume> dailyVolumeSeries(List<WorkoutSession> sessions, {int days = 14}) {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day)
      .subtract(Duration(days: days - 1));
  final buckets = <int, double>{};
  for (final s in sessions) {
    final t = s.startTime;
    if (t == null) continue;
    final d = DateTime(t.year, t.month, t.day);
    final idx = d.difference(start).inDays;
    if (idx < 0 || idx >= days) continue;
    buckets[idx] = (buckets[idx] ?? 0) + (s.totalVolume ?? 0).toDouble();
  }
  return [
    for (var i = 0; i < days; i++)
      DayVolume(start.add(Duration(days: i)), buckets[i] ?? 0)
  ];
}

/// Distinct workout days in the current week vs a weekly target.
({int done, int target}) weeklyConsistency(List<WorkoutSession> sessions,
        {int target = 4}) =>
    (done: weekWorkoutWeekdays(sessions, startOfWeek()).length, target: target);

/// Weekday numbers (1=Mon..7=Sun) with a workout in the week from [weekStart].
Set<int> weekWorkoutWeekdays(List<WorkoutSession> sessions, DateTime weekStart) {
  final set = <int>{};
  final weekEnd = weekStart.add(const Duration(days: 7));
  for (final s in sessions) {
    final t = s.startTime;
    if (t == null) continue;
    if (!t.isBefore(weekStart) && t.isBefore(weekEnd)) set.add(t.weekday);
  }
  return set;
}
