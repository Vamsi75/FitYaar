import '../../core/network/api_client.dart';
import 'gym_models.dart';

class GymService {
  final ApiClient _api;
  GymService(this._api);

  Future<List<GymSummary>> myGyms() async {
    final list = await _api.get('/gyms/me') as List<dynamic>;
    return list.map((e) => GymSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GymSummary> join(String code) async {
    final json = await _api.post('/gyms/join', body: {'code': code}) as Map<String, dynamic>;
    return GymSummary.fromJson(json);
  }

  Future<void> checkIn(int gymId, {String? focus, String? zone}) async {
    await _api.post('/gyms/$gymId/checkin', body: {'focus': focus, 'zone': zone});
  }

  Future<List<GymActivityItem>> activity(int gymId) async {
    final list = await _api.get('/gyms/$gymId/activity') as List<dynamic>;
    return list
        .map((e) => GymActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Live zone occupancy (free weights / racks / cardio / …).
  Future<List<GymActivityItem>> zones(int gymId) async {
    final list = await _api.get('/gyms/$gymId/zones') as List<dynamic>;
    return list
        .map((e) => GymActivityItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Busy-by-hour trend (24 buckets) over the last 30 days.
  Future<List<HourlyBucket>> trends(int gymId) async {
    final list = await _api.get('/gyms/$gymId/trends') as List<dynamic>;
    return list.map((e) => HourlyBucket.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<GymEventItem>> events(int gymId) async {
    final list = await _api.get('/gyms/$gymId/events') as List<dynamic>;
    return list
        .map((e) => GymEventItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> createEvent(int gymId, String title, String? body) async {
    await _api.post('/gyms/$gymId/events', body: {
      'title': title,
      if (body != null && body.isNotEmpty) 'body': body,
    });
  }

  Future<void> checkOut(int gymId) async {
    await _api.post('/gyms/$gymId/checkout');
  }

  // ---- G.6 / Gym v3 ----

  /// The current user's personal plan (assigned by a trainer), or null.
  Future<GymPlan?> myPlan(int gymId) async {
    final j = await _api.get('/gyms/$gymId/plan/me');
    return j == null ? null : GymPlan.fromJson(j as Map<String, dynamic>);
  }

  /// Trainer/admin assigns a structured plan (exercise list) to a client.
  Future<GymPlan> assignPlan(int gymId, int clientId, String title,
      {String? note, required List<PlanItem> items}) async {
    final j = await _api.post('/gyms/$gymId/plan', body: {
      'clientId': clientId,
      'title': title,
      if (note != null && note.isNotEmpty) 'note': note,
      'items': items.map((e) => e.toJson()).toList(),
    }) as Map<String, dynamic>;
    return GymPlan.fromJson(j);
  }

  /// Trainers/owners of the gym — names always visible to members.
  Future<List<GymTrainer>> trainers(int gymId) async {
    final list = await _api.get('/gyms/$gymId/trainers') as List<dynamic>;
    return list.map((e) => GymTrainer.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---- Gym v4: member records ----

  Future<MemberDetail> memberDetail(int membershipId) async {
    final j = await _api.get('/gyms/members/$membershipId') as Map<String, dynamic>;
    return MemberDetail.fromJson(j);
  }

  Future<MemberDetail> updateMember(int membershipId,
      {String? phone, DateTime? expiresAt, String? ptNotes}) async {
    final j = await _api.put('/gyms/members/$membershipId', body: {
      if (phone != null) 'phone': phone,
      if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String().split('T').first,
      if (ptNotes != null) 'ptNotes': ptNotes,
    }) as Map<String, dynamic>;
    return MemberDetail.fromJson(j);
  }

  /// Take a member on as a personal-training client (self, or a named trainer).
  Future<MemberDetail> setClient(int membershipId, {int? trainerId}) async {
    final q = trainerId != null ? '?trainerId=$trainerId' : '';
    final j = await _api.post('/gyms/members/$membershipId/client$q') as Map<String, dynamic>;
    return MemberDetail.fromJson(j);
  }

  Future<MemberDetail> unsetClient(int membershipId) async {
    final j = await _api.delete('/gyms/members/$membershipId/client') as Map<String, dynamic>;
    return MemberDetail.fromJson(j);
  }

  // ---- Gym v4: edit/delete updates ----

  Future<void> updateEvent(int eventId, String title, String? body) async {
    await _api.put('/gyms/events/$eventId', body: {
      'title': title,
      if (body != null && body.isNotEmpty) 'body': body,
    });
  }

  Future<void> deleteEvent(int eventId) async {
    await _api.delete('/gyms/events/$eventId');
  }

  /// Active members (trainer's client picker).
  Future<List<GymMember>> roster(int gymId) async {
    final list = await _api.get('/gyms/$gymId/roster') as List<dynamic>;
    return list.map((e) => GymMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<GymClass>> classes(int gymId) async {
    final list = await _api.get('/gyms/$gymId/classes') as List<dynamic>;
    return list.map((e) => GymClass.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> addClass(int gymId, String title, String? schedule, String? description) async {
    await _api.post('/gyms/$gymId/classes', body: {
      'title': title,
      if (schedule != null && schedule.isNotEmpty) 'schedule': schedule,
      if (description != null && description.isNotEmpty) 'description': description,
    });
  }

  Future<void> deleteClass(int classId) async {
    await _api.delete('/gyms/classes/$classId');
  }

  Future<void> changeRole(int membershipId, String role) async {
    await _api.post('/gyms/memberships/$membershipId/role', body: {'role': role});
  }

  Future<List<ActiveMember>> activeMembers(int gymId) async {
    final list = await _api.get('/gyms/$gymId/active') as List<dynamic>;
    return list.map((e) => ActiveMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LeaderboardEntry>> leaderboard(int gymId) async {
    final list = await _api.get('/gyms/$gymId/leaderboard') as List<dynamic>;
    return list.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<GymMember>> requests(int gymId) async {
    final list = await _api.get('/gyms/$gymId/requests') as List<dynamic>;
    return list.map((e) => GymMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<GymMember>> members(int gymId) async {
    final list = await _api.get('/gyms/$gymId/members') as List<dynamic>;
    return list.map((e) => GymMember.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<GymMember> addMember(int gymId, String email, {String? role}) async {
    final json = await _api.post('/gyms/$gymId/members', body: {
      'email': email,
      if (role != null) 'role': role,
    }) as Map<String, dynamic>;
    return GymMember.fromJson(json);
  }

  Future<void> approve(int membershipId) async {
    await _api.post('/gyms/memberships/$membershipId/approve');
  }

  Future<void> reject(int membershipId) async {
    await _api.post('/gyms/memberships/$membershipId/reject');
  }

  Future<void> remove(int membershipId) async {
    await _api.delete('/gyms/memberships/$membershipId');
  }

  Future<GymSummary> updateBanner(int gymId, String text) async {
    final json =
        await _api.put('/gyms/$gymId/banner', body: {'text': text}) as Map<String, dynamic>;
    return GymSummary.fromJson(json);
  }
}
