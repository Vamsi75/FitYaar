/// Response of POST /api/workout/import (a preview when [dryRun] is true).
class WorkoutImportResult {
  final String format; // HEVY | STRONG
  final bool dryRun;
  final int workoutsFound;
  final int workoutsImported;
  final int duplicatesSkipped;
  final int setsImported;
  final int rowsSkipped;
  final DateTime? firstWorkout;
  final DateTime? lastWorkout;
  final List<ImportExerciseMapping> exercises;
  final List<String> warnings;

  WorkoutImportResult({
    required this.format,
    required this.dryRun,
    required this.workoutsFound,
    required this.workoutsImported,
    required this.duplicatesSkipped,
    required this.setsImported,
    required this.rowsSkipped,
    this.firstWorkout,
    this.lastWorkout,
    this.exercises = const [],
    this.warnings = const [],
  });

  String get appName => format == 'HEVY' ? 'Hevy' : 'Strong';

  int get newCustomCount => exercises.where((e) => e.isNewCustom).length;

  factory WorkoutImportResult.fromJson(Map<String, dynamic> j) => WorkoutImportResult(
        format: j['format'] as String? ?? '',
        dryRun: j['dryRun'] as bool? ?? false,
        workoutsFound: j['workoutsFound'] as int? ?? 0,
        workoutsImported: j['workoutsImported'] as int? ?? 0,
        duplicatesSkipped: j['duplicatesSkipped'] as int? ?? 0,
        setsImported: j['setsImported'] as int? ?? 0,
        rowsSkipped: j['rowsSkipped'] as int? ?? 0,
        firstWorkout: j['firstWorkout'] != null
            ? DateTime.tryParse(j['firstWorkout'] as String)
            : null,
        lastWorkout: j['lastWorkout'] != null
            ? DateTime.tryParse(j['lastWorkout'] as String)
            : null,
        exercises: (j['exercises'] as List?)
                ?.map((e) => ImportExerciseMapping.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
        warnings: (j['warnings'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
}

class ImportExerciseMapping {
  final String sourceName;
  final int? exerciseId;
  final String exerciseName;
  final String method; // ALIAS | EXACT | FUZZY | NEW_CUSTOM
  final int sets;

  ImportExerciseMapping({
    required this.sourceName,
    this.exerciseId,
    required this.exerciseName,
    required this.method,
    required this.sets,
  });

  bool get isNewCustom => method == 'NEW_CUSTOM';

  factory ImportExerciseMapping.fromJson(Map<String, dynamic> j) => ImportExerciseMapping(
        sourceName: j['sourceName'] as String? ?? '',
        exerciseId: j['exerciseId'] as int?,
        exerciseName: j['exerciseName'] as String? ?? '',
        method: j['method'] as String? ?? '',
        sets: j['sets'] as int? ?? 0,
      );
}
