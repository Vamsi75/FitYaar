// Social follow/feed/compare + private-account request flow against the LIVE backend.
//   flutter test test/social_flow_test.dart --dart-define=API_BASE_URL=http://localhost:2098
import 'package:flutter_test/flutter_test.dart';

import 'package:fityaar/core/network/api_client.dart';
import 'package:fityaar/core/storage/token_store.dart';
import 'package:fityaar/features/auth/auth_service.dart';
import 'package:fityaar/features/social/social_service.dart';
import 'package:fityaar/features/workout/models/workout_models.dart';
import 'package:fityaar/features/workout/workout_service.dart';

class MemStore implements TokenStore {
  String? _a, _r;
  @override
  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    _a = accessToken;
    _r = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _a;
  @override
  Future<String?> getRefreshToken() async => _r;
  @override
  Future<void> clear() async {
    _a = null;
    _r = null;
  }
}

void main() {
  final ts = DateTime.now().millisecondsSinceEpoch;

  // Build A
  final aStore = MemStore();
  final aApi2 = ApiClient(aStore);
  final aAuth2 = AuthService(aApi2, aStore);
  final aSocial = SocialService(aApi2);

  // Build B
  final bStore = MemStore();
  final bApi = ApiClient(bStore);
  final bAuth = AuthService(bApi, bStore);
  final bWorkout = WorkoutService(bApi);

  // Build C (private)
  final cStore = MemStore();
  final cApi = ApiClient(cStore);
  final cAuth = AuthService(cApi, cStore);
  final cSocial = SocialService(cApi);

  final bEmail = 'sb_$ts@fityaar.com';
  final cEmail = 'sc_$ts@fityaar.com';
  late int bId;
  late int cId;
  late int aId;

  test('setup: register A, B, C; B logs a workout', () async {
    final a = await aAuth2.register(
        email: 'sa_$ts@fityaar.com', password: 'password123', displayName: 'Alice');
    aId = a.user.id;
    final b = await bAuth.register(
        email: bEmail, password: 'password123', displayName: 'Bob');
    bId = b.user.id;
    final c = await cAuth.register(
        email: cEmail, password: 'password123', displayName: 'Cara');
    cId = c.user.id;

    final ex = (await bWorkout.searchExercises('bench')).first;
    await bWorkout.finishSession(
      name: 'Bob Push',
      startTime: DateTime.now(),
      exercises: [LoggedExercise(ex, [LoggedSet(weight: 60, reps: 8, completed: true)])],
    );
  });

  test('A searches and finds B', () async {
    final results = await aSocial.search('sb_$ts');
    expect(results.any((u) => u.userId == bId), isTrue);
  });

  test('A follows public B → FOLLOWING, feed shows Bob Push', () async {
    final res = await aSocial.follow(bId);
    expect(res.followStatus, 'FOLLOWING');
    final feed = await aSocial.feed();
    expect(feed.any((f) => f.authorId == bId && f.name == 'Bob Push'), isTrue);
  });

  test('A can compare with B', () async {
    final c = await aSocial.compare(bId);
    expect(c.them.workouts, greaterThanOrEqualTo(1));
  });

  test('B has one follower', () async {
    final counts = await SocialService(bApi).counts();
    expect(counts.followers, greaterThanOrEqualTo(1));
  });

  test('private account: A requests C, C approves', () async {
    // Make C private via raw profile update.
    await cApi.put('/users/profile', body: {'isPublic': false});

    final res = await aSocial.follow(cId);
    expect(res.followStatus, 'PENDING');

    final reqs = await cSocial.requests();
    expect(reqs.any((u) => u.userId == aId), isTrue);

    await cSocial.approve(aId);
    final prof = await aSocial.profile(cId);
    expect(prof.followStatus, 'FOLLOWING');
    expect(prof.canView, isTrue);
  });
}
