// Gym membership + admin flow against the LIVE backend (seeded demo gym).
//   flutter test test/gym_flow_test.dart --dart-define=API_BASE_URL=http://localhost:2098
import 'package:flutter_test/flutter_test.dart';

import 'package:fityaar/core/network/api_client.dart';
import 'package:fityaar/core/storage/token_store.dart';
import 'package:fityaar/features/auth/auth_service.dart';
import 'package:fityaar/features/gym/gym_service.dart';
import 'package:fityaar/features/workout/models/workout_models.dart';
import 'package:fityaar/features/workout/workout_service.dart';

class MemStore implements TokenStore {
  String? _a, _r;
  @override
  Future<void> saveTokens(
      {required String accessToken, required String refreshToken}) async {
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
  final adminStore = MemStore();
  final adminApi = ApiClient(adminStore);
  final adminAuth = AuthService(adminApi, adminStore);
  final adminGym = GymService(adminApi);

  final memStore = MemStore();
  final memApi = ApiClient(memStore);
  final memAuth = AuthService(memApi, memStore);
  final memGym = GymService(memApi);

  final ts = DateTime.now().millisecondsSinceEpoch;
  final adminEmail = 'gymadmin_$ts@fityaar.com';
  final memEmail = 'gymmem_$ts@fityaar.com';

  late int gymId;
  late int memMembershipId;

  test('admin claims the gym with the owner code', () async {
    await adminAuth.register(
        email: adminEmail, password: 'password123', displayName: 'Gym Admin');
    final g = await adminGym.join('OWNER123');
    expect(g.admin, isTrue);
    expect(g.status, 'ACTIVE');
    gymId = g.gymId;
  });

  test('member requests to join (pending)', () async {
    await memAuth.register(
        email: memEmail, password: 'password123', displayName: 'Gym Member');
    final g = await memGym.join('IRON123');
    expect(g.status, 'PENDING');
    expect(g.gymId, gymId);
  });

  test('admin sees the request and approves it', () async {
    final reqs = await adminGym.requests(gymId);
    expect(reqs.any((m) => m.email == memEmail), isTrue);
    memMembershipId =
        reqs.firstWhere((m) => m.email == memEmail).membershipId;
    await adminGym.approve(memMembershipId);
    final members = await adminGym.members(gymId);
    expect(members.any((m) => m.email == memEmail), isTrue);
  });

  test('approved member can check in (live crowd increments)', () async {
    final before = (await memGym.myGyms()).first;
    expect(before.status, 'ACTIVE');
    await memGym.checkIn(gymId, focus: 'Chest');
    final after = (await memGym.myGyms()).first;
    expect(after.checkedIn, isTrue);
    expect(after.liveCount, greaterThanOrEqualTo(1));
  });

  test('non-admin cannot view join requests (403)', () async {
    await expectLater(
      memGym.requests(gymId),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403)),
    );
  });

  test('activity shows the focus breakdown', () async {
    final act = await memGym.activity(gymId);
    expect(act.any((a) => a.label == 'Chest'), isTrue);
  });

  test('admin posts an event and members see it', () async {
    await adminGym.createEvent(gymId, 'Closed Sunday', 'Maintenance');
    final events = await memGym.events(gymId);
    expect(events.any((e) => e.title == 'Closed Sunday'), isTrue);
  });

  test('finishing a workout auto checks the member out', () async {
    final workout = WorkoutService(memApi);
    final ex = (await workout.searchExercises('bench')).first;
    await workout.finishSession(
      name: 'Quick',
      startTime: DateTime.now(),
      exercises: [
        LoggedExercise(ex, [LoggedSet(weight: 40, reps: 5, completed: true)]),
      ],
    );
    final g = (await memGym.myGyms()).first;
    expect(g.checkedIn, isFalse);
  });

  test('super-admin can claim, create a gym, and list', () async {
    final superStore = MemStore();
    final superApi = ApiClient(superStore);
    final superAuth = AuthService(superApi, superStore);
    await superAuth.register(
        email: 'super_$ts@fityaar.com',
        password: 'password123',
        displayName: 'Super');
    await superApi.post('/admin/claim', body: {'code': 'LETMEIN-SUPER'});
    final joinCode = 'NEW$ts';
    final created = await superApi.post('/admin/gyms', body: {
      'name': 'Second Gym',
      'capacity': 50,
      'joinCode': joinCode,
      'ownerCode': 'own$ts',
    }) as Map<String, dynamic>;
    expect(created['joinCode'], joinCode);
    final gyms = await superApi.get('/admin/gyms') as List;
    expect(gyms.length, greaterThanOrEqualTo(2));
  });
}
