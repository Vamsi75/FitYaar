import 'package:intl/intl.dart';

import '../../core/network/api_client.dart';
import 'models/workout_models.dart';

/// Wraps /api/workout endpoints.
class WorkoutService {
  final ApiClient _api;
  WorkoutService(this._api);

  // Backend LocalDateTime parses ISO_LOCAL_DATE_TIME (no timezone offset).
  static final DateFormat _dateTime = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  Future<List<Exercise>> searchExercises(String query,
      {String? muscle, String? equipment}) async {
    final params = <String>[];
    if (query.isNotEmpty) params.add('query=${Uri.encodeQueryComponent(query)}');
    if (muscle != null && muscle.isNotEmpty) params.add('muscle=$muscle');
    if (equipment != null && equipment.isNotEmpty) params.add('equipment=$equipment');
    final path =
        '/workout/exercises${params.isEmpty ? '' : '?${params.join('&')}'}';
    final list = await _api.get(path) as List<dynamic>;
    return list
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Routine> updateRoutine({
    required int routineId,
    required String name,
    required List<int> exerciseIds,
  }) async {
    final body = {
      'name': name,
      'isTemplate': false,
      'exercises': [
        for (var i = 0; i < exerciseIds.length; i++)
          {'exerciseId': exerciseIds[i], 'orderIndex': i}
      ],
    };
    final json = await _api.put('/workout/routines/$routineId', body: body)
        as Map<String, dynamic>;
    return Routine.fromJson(json);
  }

  Future<List<Routine>> getRoutines() async {
    final list = await _api.get('/workout/routines') as List<dynamic>;
    return list.map((e) => Routine.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Routine> createRoutine({
    required String name,
    required List<int> exerciseIds,
  }) async {
    final body = {
      'name': name,
      'isTemplate': false,
      'exercises': [
        for (var i = 0; i < exerciseIds.length; i++)
          {'exerciseId': exerciseIds[i], 'orderIndex': i}
      ],
    };
    final json =
        await _api.post('/workout/routines', body: body) as Map<String, dynamic>;
    return Routine.fromJson(json);
  }

  Future<List<WorkoutSession>> getHistory() async {
    final list = await _api.get('/workout/history') as List<dynamic>;
    return list
        .map((e) => WorkoutSession.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PersonalRecord>> getPersonalRecords() async {
    final list = await _api.get('/workout/prs') as List<dynamic>;
    return list
        .map((e) => PersonalRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<WorkoutSession> finishSession({
    required String name,
    required DateTime startTime,
    required List<LoggedExercise> exercises,
    String? notes,
  }) async {
    final json = await _api.post('/workout/sessions',
            body: _sessionBody(
                name: name,
                startTime: startTime,
                exercises: exercises,
                notes: notes))
        as Map<String, dynamic>;
    return WorkoutSession.fromJson(json);
  }

  Future<WorkoutSession> updateSession({
    required int sessionId,
    required String name,
    required DateTime startTime,
    required List<LoggedExercise> exercises,
    String? notes,
  }) async {
    final json = await _api.put('/workout/sessions/$sessionId',
            body: _sessionBody(
                name: name,
                startTime: startTime,
                exercises: exercises,
                notes: notes))
        as Map<String, dynamic>;
    return WorkoutSession.fromJson(json);
  }

  Future<void> deleteSession(int sessionId) async {
    await _api.delete('/workout/sessions/$sessionId');
  }

  Map<String, dynamic> _sessionBody({
    required String name,
    required DateTime startTime,
    required List<LoggedExercise> exercises,
    String? notes,
  }) {
    return {
      'name': name,
      'startTime': _dateTime.format(startTime),
      'endTime': _dateTime.format(DateTime.now()),
      'notes': notes,
      'exercises': [
        for (var i = 0; i < exercises.length; i++)
          {
            'exerciseId': exercises[i].exercise.id,
            'orderIndex': i,
            'notes': null,
            'sets': [
              for (var s = 0; s < exercises[i].sets.length; s++)
                {
                  'orderIndex': s,
                  'weight': exercises[i].sets[s].weight,
                  'reps': exercises[i].sets[s].reps,
                  'durationSeconds': exercises[i].sets[s].durationSeconds,
                  'distanceMeters': exercises[i].sets[s].distanceMeters,
                  'rpe': null,
                  'type': setTypeApi(exercises[i].sets[s].type),
                  'isCompleted': exercises[i].sets[s].completed,
                }
            ],
          }
      ],
    };
  }
}
