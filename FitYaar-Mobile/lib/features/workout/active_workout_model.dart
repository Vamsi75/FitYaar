import 'dart:async';

import 'package:flutter/material.dart';

import 'metric_spec.dart';
import 'models/workout_models.dart';
import 'workout_service.dart';

/// Prefill data when editing an existing session.
class PrefilledSet {
  final double? weight;
  final int? reps;
  final int? durationSeconds;
  final double? distanceMeters;
  final WorkoutSetType type;
  final bool completed;
  PrefilledSet({
    this.weight,
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
    this.type = WorkoutSetType.normal,
    this.completed = true,
  });
}

class PrefilledExercise {
  final Exercise exercise;
  final List<PrefilledSet> sets;
  PrefilledExercise(this.exercise, this.sets);
}

class PrevSet {
  final double? weight;
  final int? reps;
  final int? durationSeconds;
  final double? distanceMeters;
  PrevSet(this.weight, this.reps, {this.durationSeconds, this.distanceMeters});
}

double estimate1RM(double? weight, int? reps) {
  if (weight == null || reps == null || reps <= 0) return 0;
  if (reps == 1) return weight;
  final d = 1.0278 - (0.0278 * reps);
  // Brzycki breaks down (denominator ≤ 0) around 37+ reps — fall back to Epley,
  // which stays positive and monotonic.
  if (d <= 0.1) return weight * (1 + reps / 30.0);
  return weight / d;
}

String fmtWeight(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toString();

class ActiveSetRow {
  final TextEditingController weight = TextEditingController();
  final TextEditingController reps = TextEditingController();
  final TextEditingController duration = TextEditingController();
  final TextEditingController distance = TextEditingController();
  bool completed;
  WorkoutSetType type;
  double? prevWeight;
  int? prevReps;
  int? prevDurationSeconds;
  double? prevDistanceMeters;
  DateTime? durationStartedAt; // non-null while a duration timer is running

  bool get durationRunning => durationStartedAt != null;
  int get durationElapsed => durationStartedAt == null
      ? 0
      : DateTime.now().difference(durationStartedAt!).inSeconds;

  ActiveSetRow({
    double? weight,
    int? reps,
    int? durationSeconds,
    double? distanceMeters,
    this.completed = false,
    this.type = WorkoutSetType.normal,
    this.prevWeight,
    this.prevReps,
    this.prevDurationSeconds,
    this.prevDistanceMeters,
  }) {
    if (weight != null) this.weight.text = fmtWeight(weight);
    if (reps != null) this.reps.text = reps.toString();
    if (durationSeconds != null) duration.text = fmtDuration(durationSeconds);
    if (distanceMeters != null) distance.text = fmtDistanceKm(distanceMeters);
  }

  void dispose() {
    weight.dispose();
    reps.dispose();
    duration.dispose();
    distance.dispose();
  }
}

class ActiveExercise {
  final Exercise exercise;
  final List<ActiveSetRow> sets = [];
  int restSeconds = 60;
  List<PrevSet> previousSets = const [];
  double previousBest1RM = 0;

  ActiveExercise(this.exercise);

  void addSet() {
    final i = sets.length;
    final p = i < previousSets.length ? previousSets[i] : null;
    sets.add(ActiveSetRow(
      prevWeight: p?.weight,
      prevReps: p?.reps,
      prevDurationSeconds: p?.durationSeconds,
      prevDistanceMeters: p?.distanceMeters,
    ));
  }

  void removeSet(int i) => sets.removeAt(i).dispose();

  double currentBest1RM() {
    var best = 0.0;
    for (final s in sets) {
      if (!s.completed) continue;
      final e = estimate1RM(double.tryParse(s.weight.text), int.tryParse(s.reps.text));
      if (e > best) best = e;
    }
    return best;
  }

  /// True once a completed set this session beats last time's best for this lift.
  bool get beatsPrevious => previousBest1RM > 0 && currentBest1RM() > previousBest1RM;

  void dispose() {
    for (final s in sets) {
      s.dispose();
    }
  }
}

/// App-level state for the in-progress workout so it survives navigation and
/// can be shown as a minimized banner.
class ActiveWorkoutModel extends ChangeNotifier {
  final WorkoutService _service;
  ActiveWorkoutModel(this._service);

  bool isActive = false;
  String title = 'New Workout';
  int? editingSessionId;
  int? sourceRoutineId;
  List<int> originalExerciseIds = const [];
  DateTime? startedAt;
  final List<ActiveExercise> entries = [];

  // Timer supports pause/resume + manual edit: elapsed = accumulated + current run.
  Duration _accumulated = Duration.zero;
  DateTime? _runStart;
  bool paused = false;

  /// Live elapsed time (advances while running, frozen while paused).
  Duration get elapsed {
    var e = _accumulated;
    final rs = _runStart;
    if (rs != null) e += DateTime.now().difference(rs);
    return e;
  }

  void pauseTimer() {
    if (paused || _runStart == null) return;
    _accumulated += DateTime.now().difference(_runStart!);
    _runStart = null;
    paused = true;
    _ticker?.cancel();
    _ticker = null;
    notifyListeners();
  }

  void resumeTimer() {
    if (!paused) return;
    _runStart = DateTime.now();
    paused = false;
    _startTicker();
    notifyListeners();
  }

  /// Manually set the elapsed time (from the "adjust time" dialog).
  void setElapsed(Duration d) {
    _accumulated = d.isNegative ? Duration.zero : d;
    if (_runStart != null) _runStart = DateTime.now();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
  }

  Timer? _ticker;
  Map<int, List<PrevSet>> _previousByExercise = {};
  Map<int, double> _prevBest1RM = {};

  bool get isEditing => editingSessionId != null;
  int get totalSets => entries.fold(0, (s, e) => s + e.sets.length);

  List<int> currentExerciseIds() => entries.map((e) => e.exercise.id).toList();

  /// Exercises present now that weren't in the source routine.
  List<int> addedExerciseIds() {
    final orig = originalExerciseIds.toSet();
    return currentExerciseIds().where((id) => !orig.contains(id)).toList();
  }

  void start({
    required String title,
    List<Exercise> exercises = const [],
    int? editingSessionId,
    int? routineId,
    List<PrefilledExercise>? prefill,
  }) {
    _reset();
    this.title = title;
    this.editingSessionId = editingSessionId;
    sourceRoutineId = routineId;
    originalExerciseIds = exercises.map((e) => e.id).toList();
    startedAt = DateTime.now();
    _accumulated = Duration.zero;
    _runStart = DateTime.now();
    paused = false;
    isActive = true;

    if (prefill != null) {
      for (final pe in prefill) {
        final e = ActiveExercise(pe.exercise);
        for (final ps in pe.sets) {
          e.sets.add(ActiveSetRow(
              weight: ps.weight,
              reps: ps.reps,
              durationSeconds: ps.durationSeconds,
              distanceMeters: ps.distanceMeters,
              type: ps.type,
              completed: ps.completed));
        }
        if (e.sets.isEmpty) e.addSet();
        entries.add(e);
      }
    } else {
      for (final ex in exercises) {
        entries.add(ActiveExercise(ex)..addSet());
      }
    }

    _startTicker();
    _loadPrevious();
    notifyListeners();
  }

  void addExercises(List<Exercise> exs) {
    for (final ex in exs) {
      final e = ActiveExercise(ex)..addSet();
      _applyPrevious(e);
      entries.add(e);
    }
    notifyListeners();
  }

  void removeExercise(int i) {
    entries.removeAt(i).dispose();
    notifyListeners();
  }

  void addSet(ActiveExercise e) {
    e.addSet();
    notifyListeners();
  }

  void removeSet(ActiveExercise e, int i) {
    e.removeSet(i);
    notifyListeners();
  }

  void setType(ActiveExercise e, int i, WorkoutSetType type) {
    e.sets[i].type = type;
    notifyListeners();
  }

  void startDurationTimer(ActiveSetRow row) {
    row.durationStartedAt = DateTime.now();
    notifyListeners();
  }

  /// Stop a running duration timer and capture its elapsed time into the field.
  void stopDurationTimer(ActiveSetRow row) {
    if (row.durationRunning) {
      row.duration.text = fmtDuration(row.durationElapsed);
      row.durationStartedAt = null;
    }
    notifyListeners();
  }

  void toggleComplete(ActiveSetRow row, bool value) {
    row.completed = value;
    // Ticking "done" with blank boxes should adopt the last-time placeholder
    // (Hevy-style) so the set carries data and isn't dropped on finish.
    if (value) {
      // A still-running duration timer is captured + stopped on completion.
      if (row.durationRunning) {
        row.duration.text = fmtDuration(row.durationElapsed);
        row.durationStartedAt = null;
      }
      if (row.weight.text.trim().isEmpty && row.prevWeight != null) {
        row.weight.text = fmtWeight(row.prevWeight!);
      }
      if (row.reps.text.trim().isEmpty && row.prevReps != null) {
        row.reps.text = row.prevReps!.toString();
      }
      if (row.duration.text.trim().isEmpty && row.prevDurationSeconds != null) {
        row.duration.text = fmtDuration(row.prevDurationSeconds!);
      }
      if (row.distance.text.trim().isEmpty && row.prevDistanceMeters != null) {
        row.distance.text = fmtDistanceKm(row.prevDistanceMeters!);
      }
    }
    notifyListeners();
  }

  void setRest(ActiveExercise e, int seconds) {
    e.restSeconds = seconds;
    notifyListeners();
  }

  List<LoggedExercise> buildLogged() {
    final logged = <LoggedExercise>[];
    for (final e in entries) {
      // Only persist metrics this exercise's type actually uses, so a value left
      // in a hidden field (e.g. from a tap-to-fill of a differently-typed
      // previous set) can't leak into the saved set.
      final kinds =
          metricFieldsFor(e.exercise.exerciseType).map((f) => f.kind).toSet();
      final sets = <LoggedSet>[];
      for (final row in e.sets) {
        if (!row.completed) continue;
        final weight = kinds.contains(MetricKind.weight)
            ? double.tryParse(row.weight.text)
            : null;
        final reps =
            kinds.contains(MetricKind.reps) ? int.tryParse(row.reps.text) : null;
        final durationSeconds = kinds.contains(MetricKind.duration)
            ? parseDuration(row.duration.text)
            : null;
        final distanceMeters = kinds.contains(MetricKind.distance)
            ? parseDistanceKmToMeters(row.distance.text)
            : null;
        // Keep the set if it carries any metric (reps, time, distance or weight).
        if (reps == null &&
            durationSeconds == null &&
            distanceMeters == null &&
            weight == null) {
          continue;
        }
        sets.add(LoggedSet(
          weight: weight,
          reps: reps,
          durationSeconds: durationSeconds,
          distanceMeters: distanceMeters,
          completed: true,
          type: row.type,
        ));
      }
      if (sets.isNotEmpty) logged.add(LoggedExercise(e.exercise, sets));
    }
    return logged;
  }

  String defaultName() {
    if (title != 'New Workout') return title;
    final h = (startedAt ?? DateTime.now()).hour;
    if (h < 12) return 'Morning Workout';
    if (h < 17) return 'Afternoon Workout';
    if (h < 21) return 'Evening Workout';
    return 'Night Workout';
  }

  void discard() {
    _reset();
    notifyListeners();
  }

  void finishAndClear() {
    _reset();
    notifyListeners();
  }

  Future<void> _loadPrevious() async {
    try {
      final history = await _service.getHistory();
      history.sort((a, b) =>
          (b.startTime ?? DateTime(0)).compareTo(a.startTime ?? DateTime(0)));
      final byEx = <int, List<PrevSet>>{};
      final best = <int, double>{};
      for (final s in history) {
        if (s.id == editingSessionId) continue; // ignore the session being edited
        for (final we in s.exercises) {
          if (byEx.containsKey(we.exerciseId)) continue; // first = most recent
          byEx[we.exerciseId] = we.sets
              .map((x) => PrevSet(x.weight, x.reps,
                  durationSeconds: x.durationSeconds,
                  distanceMeters: x.distanceMeters))
              .toList();
          var b = 0.0;
          for (final x in we.sets) {
            final e = estimate1RM(x.weight, x.reps);
            if (e > b) b = e;
          }
          best[we.exerciseId] = b;
        }
      }
      _previousByExercise = byEx;
      _prevBest1RM = best;
      for (final e in entries) {
        _applyPrevious(e);
      }
      notifyListeners();
    } catch (_) {
      // No history / offline — placeholders just won't show.
    }
  }

  void _applyPrevious(ActiveExercise e) {
    e.previousSets = _previousByExercise[e.exercise.id] ?? const [];
    e.previousBest1RM = _prevBest1RM[e.exercise.id] ?? 0;
    for (var i = 0; i < e.sets.length; i++) {
      if (i < e.previousSets.length) {
        e.sets[i].prevWeight ??= e.previousSets[i].weight;
        e.sets[i].prevReps ??= e.previousSets[i].reps;
        e.sets[i].prevDurationSeconds ??= e.previousSets[i].durationSeconds;
        e.sets[i].prevDistanceMeters ??= e.previousSets[i].distanceMeters;
      }
    }
  }

  void _reset() {
    _ticker?.cancel();
    _ticker = null;
    for (final e in entries) {
      for (final s in e.sets) {
        s.durationStartedAt = null; // stop any running set timer before teardown
      }
      e.dispose();
    }
    entries.clear();
    isActive = false;
    editingSessionId = null;
    sourceRoutineId = null;
    originalExerciseIds = const [];
    startedAt = null;
    _accumulated = Duration.zero;
    _runStart = null;
    paused = false;
    _previousByExercise = {};
    _prevBest1RM = {};
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
