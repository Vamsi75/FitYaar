// End-to-end test of the workout create/edit/delete flow against the LIVE backend.
//   flutter test test/workout_flow_test.dart --dart-define=API_BASE_URL=http://localhost:2098
import 'package:flutter_test/flutter_test.dart';

import 'package:fityaar/core/network/api_client.dart';
import 'package:fityaar/core/storage/token_store.dart';
import 'package:fityaar/features/auth/auth_service.dart';
import 'package:fityaar/features/workout/models/workout_models.dart';
import 'package:fityaar/features/workout/workout_service.dart';

class InMemoryTokenStore implements TokenStore {
  String? _access;
  String? _refresh;
  @override
  Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
    _access = accessToken;
    _refresh = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _access;
  @override
  Future<String?> getRefreshToken() async => _refresh;
  @override
  Future<void> clear() async {
    _access = null;
    _refresh = null;
  }
}

void main() {
  final store = InMemoryTokenStore();
  final api = ApiClient(store);
  final auth = AuthService(api, store);
  final workout = WorkoutService(api);
  final email = 'wk_${DateTime.now().millisecondsSinceEpoch}@fityaar.com';

  late Exercise anExercise;
  late int sessionId;

  test('setup: register an authenticated user', () async {
    await auth.register(
        email: email, password: 'password123', displayName: 'Workout Tester');
    expect(await store.getAccessToken(), isNotEmpty);
  });

  test('search returns the seeded exercise catalog', () async {
    final results = await workout.searchExercises('squat');
    expect(results, isNotEmpty);
    anExercise = results.first;
  });

  test('create a routine (req 1)', () async {
    final routine = await workout
        .createRoutine(name: 'Push Day', exerciseIds: [anExercise.id]);
    expect(routine.id, greaterThan(0));
    final routines = await workout.getRoutines();
    expect(routines.any((r) => r.name == 'Push Day'), isTrue);
  });

  test('search by muscle term returns matches (abs)', () async {
    final abs = await workout.searchExercises('abs');
    expect(abs, isNotEmpty);
  });

  test('update a routine replaces its exercises', () async {
    final routine = await workout
        .createRoutine(name: 'Pull Day', exerciseIds: [anExercise.id]);
    final more = await workout.searchExercises('deadlift');
    final second = more.isNotEmpty ? more.first : anExercise;
    final updated = await workout.updateRoutine(
      routineId: routine.id,
      name: 'Pull Day',
      exerciseIds: [anExercise.id, second.id],
    );
    expect(updated.exercises.length, 2);
  });

  test('finish a session with mixed set types', () async {
    final session = await workout.finishSession(
      name: 'Leg Day',
      startTime: DateTime.now().subtract(const Duration(minutes: 30)),
      exercises: [
        LoggedExercise(anExercise, [
          LoggedSet(weight: 40, reps: 10, completed: true, type: WorkoutSetType.warmup),
          LoggedSet(weight: 80, reps: 8, completed: true, type: WorkoutSetType.normal),
          LoggedSet(weight: 80, reps: 5, completed: true, type: WorkoutSetType.failure),
        ]),
      ],
    );
    expect(session.id, greaterThan(0));
    sessionId = session.id;
  });

  test('edit the session name (PUT)', () async {
    final updated = await workout.updateSession(
      sessionId: sessionId,
      name: 'Leg Day (edited)',
      startTime: DateTime.now().subtract(const Duration(minutes: 30)),
      exercises: [
        LoggedExercise(anExercise,
            [LoggedSet(weight: 90, reps: 5, completed: true)]),
      ],
    );
    expect(updated.name, 'Leg Day (edited)');
  });

  test('delete the session (DELETE) removes it from history', () async {
    await workout.deleteSession(sessionId);
    final history = await workout.getHistory();
    expect(history.any((s) => s.id == sessionId), isFalse);
  });
}
