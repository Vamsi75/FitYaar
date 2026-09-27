enum WorkoutSetType { normal, warmup, drop, failure }

String setTypeApi(WorkoutSetType t) => switch (t) {
      WorkoutSetType.normal => 'NORMAL',
      WorkoutSetType.warmup => 'WARMUP',
      WorkoutSetType.drop => 'DROPSET',
      WorkoutSetType.failure => 'FAILURE',
    };

WorkoutSetType setTypeFromApi(String? s) => switch (s) {
      'WARMUP' => WorkoutSetType.warmup,
      'DROPSET' => WorkoutSetType.drop,
      'FAILURE' => WorkoutSetType.failure,
      _ => WorkoutSetType.normal,
    };

/// Single-letter badge for non-numeric set types ('' means "use the set number").
String setTypeBadge(WorkoutSetType t) => switch (t) {
      WorkoutSetType.normal => '',
      WorkoutSetType.warmup => 'W',
      WorkoutSetType.drop => 'D',
      WorkoutSetType.failure => 'F',
    };

/// Turns an enum-ish token like FRONT_DELTS into "Front Delts".
String prettyEnum(String? value) {
  if (value == null || value.isEmpty) return '';
  return value
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0]}${w.substring(1).toLowerCase()}')
      .join(' ');
}

class Exercise {
  final int id;
  final String name;
  final String? description;
  final List<String> primaryMuscleGroups;
  final List<String> secondaryMuscleGroups;
  final String? equipment;
  final String? exerciseType;
  final String? category;

  Exercise({
    required this.id,
    required this.name,
    this.description,
    this.primaryMuscleGroups = const [],
    this.secondaryMuscleGroups = const [],
    this.equipment,
    this.exerciseType,
    this.category,
  });

  factory Exercise.fromJson(Map<String, dynamic> j) => Exercise(
        id: j['id'] as int,
        name: j['name'] as String,
        description: j['description'] as String?,
        primaryMuscleGroups: (j['primaryMuscleGroups'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        secondaryMuscleGroups: (j['secondaryMuscleGroups'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        equipment: j['equipment'] as String?,
        exerciseType: j['exerciseType'] as String?,
        category: j['category'] as String?,
      );

  /// e.g. "Chest · Barbell"
  String get subtitle {
    final muscle =
        primaryMuscleGroups.isNotEmpty ? prettyEnum(primaryMuscleGroups.first) : prettyEnum(category);
    final gear = prettyEnum(equipment);
    return [muscle, gear].where((s) => s.isNotEmpty).join(' · ');
  }
}

class SetEntryModel {
  final double? weight;
  final int? reps;
  final int? durationSeconds;
  final double? distanceMeters;
  final bool isCompleted;
  final WorkoutSetType type;

  SetEntryModel({
    this.weight,
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
    this.isCompleted = false,
    this.type = WorkoutSetType.normal,
  });

  factory SetEntryModel.fromJson(Map<String, dynamic> j) => SetEntryModel(
        weight: (j['weight'] as num?)?.toDouble(),
        reps: j['reps'] as int?,
        durationSeconds: j['durationSeconds'] as int?,
        distanceMeters: (j['distanceMeters'] as num?)?.toDouble(),
        isCompleted: (j['isCompleted'] as bool?) ?? false,
        type: setTypeFromApi(j['type'] as String?),
      );
}

class WorkoutExerciseModel {
  final int exerciseId;
  final String? exerciseName;
  final String? exerciseType;
  final List<SetEntryModel> sets;

  WorkoutExerciseModel({
    required this.exerciseId,
    this.exerciseName,
    this.exerciseType,
    this.sets = const [],
  });

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> j) =>
      WorkoutExerciseModel(
        exerciseId: j['exerciseId'] as int,
        exerciseName: j['exerciseName'] as String?,
        exerciseType: j['exerciseType'] as String?,
        sets: (j['sets'] as List?)
                ?.map((e) => SetEntryModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class WorkoutSession {
  final int id;
  final String? name;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? notes;
  final List<WorkoutExerciseModel> exercises;
  final int? totalVolume;

  WorkoutSession({
    required this.id,
    this.name,
    this.startTime,
    this.endTime,
    this.notes,
    this.exercises = const [],
    this.totalVolume,
  });

  factory WorkoutSession.fromJson(Map<String, dynamic> j) => WorkoutSession(
        id: j['id'] as int,
        name: j['name'] as String?,
        startTime: j['startTime'] != null
            ? DateTime.tryParse(j['startTime'] as String)
            : null,
        endTime:
            j['endTime'] != null ? DateTime.tryParse(j['endTime'] as String) : null,
        notes: j['notes'] as String?,
        totalVolume: j['totalVolume'] as int?,
        exercises: (j['exercises'] as List?)
                ?.map((e) =>
                    WorkoutExerciseModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  int get setCount =>
      exercises.fold(0, (sum, e) => sum + e.sets.length);
}

class RoutineExercise {
  final int exerciseId;
  final String? exerciseName;

  RoutineExercise({required this.exerciseId, this.exerciseName});

  factory RoutineExercise.fromJson(Map<String, dynamic> j) => RoutineExercise(
        exerciseId: j['exerciseId'] as int,
        exerciseName: j['exerciseName'] as String?,
      );
}

class Routine {
  final int id;
  final String name;
  final String? notes;
  final bool isTemplate;
  final List<RoutineExercise> exercises;

  Routine({
    required this.id,
    required this.name,
    this.notes,
    this.isTemplate = false,
    this.exercises = const [],
  });

  factory Routine.fromJson(Map<String, dynamic> j) => Routine(
        id: j['id'] as int,
        name: j['name'] as String,
        notes: j['notes'] as String?,
        isTemplate: (j['isTemplate'] as bool?) ?? false,
        exercises: (j['exercises'] as List?)
                ?.map((e) => RoutineExercise.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class PersonalRecord {
  final int exerciseId;
  final String? exerciseName;
  final double? weight;
  final int? reps;
  final double? oneRepMaxEstimate;

  PersonalRecord({
    required this.exerciseId,
    this.exerciseName,
    this.weight,
    this.reps,
    this.oneRepMaxEstimate,
  });

  factory PersonalRecord.fromJson(Map<String, dynamic> j) => PersonalRecord(
        exerciseId: j['exerciseId'] as int,
        exerciseName: j['exerciseName'] as String?,
        weight: (j['weight'] as num?)?.toDouble(),
        reps: j['reps'] as int?,
        oneRepMaxEstimate: (j['oneRepMaxEstimate'] as num?)?.toDouble(),
      );
}

/// Plain value objects the active-workout screen produces on finish.
class LoggedSet {
  final double? weight;
  final int? reps;
  final int? durationSeconds;
  final double? distanceMeters;
  final bool completed;
  final WorkoutSetType type;
  LoggedSet({
    this.weight,
    this.reps,
    this.durationSeconds,
    this.distanceMeters,
    this.completed = false,
    this.type = WorkoutSetType.normal,
  });
}

class LoggedExercise {
  final Exercise exercise;
  final List<LoggedSet> sets;
  LoggedExercise(this.exercise, this.sets);
}
