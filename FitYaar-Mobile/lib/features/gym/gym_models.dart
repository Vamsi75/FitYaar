class GymSummary {
  final int gymId;
  final String name;
  final String? bannerText;
  final int? capacity;
  final int liveCount;
  final int? membershipId;
  final String? role;
  final String? status;
  final bool admin;
  final bool checkedIn;

  GymSummary({
    required this.gymId,
    required this.name,
    this.bannerText,
    this.capacity,
    this.liveCount = 0,
    this.membershipId,
    this.role,
    this.status,
    this.admin = false,
    this.checkedIn = false,
  });

  bool get isActive => status == 'ACTIVE';
  bool get isPending => status == 'PENDING';

  factory GymSummary.fromJson(Map<String, dynamic> j) => GymSummary(
        gymId: j['gymId'] as int,
        name: j['name'] as String,
        bannerText: j['bannerText'] as String?,
        capacity: (j['capacity'] as num?)?.toInt(),
        liveCount: (j['liveCount'] as num?)?.toInt() ?? 0,
        membershipId: (j['membershipId'] as num?)?.toInt(),
        role: j['role'] as String?,
        status: j['status'] as String?,
        admin: (j['admin'] as bool?) ?? false,
        checkedIn: (j['checkedIn'] as bool?) ?? false,
      );
}

class GymActivityItem {
  final String label;
  final int count;
  GymActivityItem(this.label, this.count);
  factory GymActivityItem.fromJson(Map<String, dynamic> j) =>
      GymActivityItem(j['label'] as String, (j['count'] as num).toInt());
}

/// Check-in count for one hour of the day (0–23), for the busy-by-hour trend.
class HourlyBucket {
  final int hour;
  final int count;
  HourlyBucket(this.hour, this.count);
  factory HourlyBucket.fromJson(Map<String, dynamic> j) =>
      HourlyBucket((j['hour'] as num).toInt(), (j['count'] as num).toInt());
}

class GymEventItem {
  final int id;
  final String title;
  final String? body;
  final DateTime? startsAt;
  final DateTime? createdAt;
  GymEventItem({
    required this.id,
    required this.title,
    this.body,
    this.startsAt,
    this.createdAt,
  });
  factory GymEventItem.fromJson(Map<String, dynamic> j) => GymEventItem(
        id: j['id'] as int,
        title: j['title'] as String,
        body: j['body'] as String?,
        startsAt: j['startsAt'] != null
            ? DateTime.tryParse(j['startsAt'] as String)
            : null,
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String)
            : null,
      );
}

class PlanItem {
  final String exerciseName;
  final int? sets;
  final int? reps;
  final String? note;
  PlanItem({required this.exerciseName, this.sets, this.reps, this.note});
  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
        exerciseName: j['exerciseName'] as String? ?? '',
        sets: (j['sets'] as num?)?.toInt(),
        reps: (j['reps'] as num?)?.toInt(),
        note: j['note'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'exerciseName': exerciseName,
        if (sets != null) 'sets': sets,
        if (reps != null) 'reps': reps,
        if (note != null && note!.isNotEmpty) 'note': note,
      };

  /// "3 × 10" / "3 sets" / "10 reps" / "" depending on what's set.
  String get scheme {
    if (sets != null && reps != null) return '$sets × $reps';
    if (sets != null) return '$sets sets';
    if (reps != null) return '$reps reps';
    return '';
  }
}

class GymPlan {
  final int id;
  final String title;
  final String? body;
  final DateTime? planDate;
  final String? authorName;
  final List<PlanItem> items;
  GymPlan({
    required this.id,
    required this.title,
    this.body,
    this.planDate,
    this.authorName,
    this.items = const [],
  });
  factory GymPlan.fromJson(Map<String, dynamic> j) => GymPlan(
        id: j['id'] as int,
        title: j['title'] as String,
        body: j['body'] as String?,
        planDate: j['planDate'] != null ? DateTime.tryParse(j['planDate'] as String) : null,
        authorName: j['authorName'] as String?,
        items: (j['items'] as List<dynamic>?)
                ?.map((e) => PlanItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}

class GymTrainer {
  final int userId;
  final String displayName;
  final String role;
  /// Checked in at the gym right now.
  final bool activeNow;
  GymTrainer(this.userId, this.displayName, this.role, {this.activeNow = false});
  factory GymTrainer.fromJson(Map<String, dynamic> j) => GymTrainer(
        (j['userId'] as num).toInt(),
        j['displayName'] as String? ?? 'Trainer',
        j['role'] as String? ?? 'TRAINER',
        activeNow: (j['activeNow'] as bool?) ?? false,
      );
  bool get isOwner => role == 'OWNER';
}

class MemberDetail {
  final int membershipId;
  final int userId;
  final String displayName;
  final String email;
  final String? phone;
  final String role;
  final String status;
  final DateTime? joinedAt;
  final DateTime? expiresAt;
  final String? trainerName;
  final String? ptNotes;

  MemberDetail({
    required this.membershipId,
    required this.userId,
    required this.displayName,
    required this.email,
    this.phone,
    required this.role,
    required this.status,
    this.joinedAt,
    this.expiresAt,
    this.trainerName,
    this.ptNotes,
  });

  bool get isClient => trainerName != null;

  factory MemberDetail.fromJson(Map<String, dynamic> j) => MemberDetail(
        membershipId: (j['membershipId'] as num).toInt(),
        userId: (j['userId'] as num).toInt(),
        displayName: j['displayName'] as String? ?? j['email'] as String,
        email: j['email'] as String,
        phone: j['phone'] as String?,
        role: j['role'] as String,
        status: j['status'] as String,
        joinedAt:
            j['joinedAt'] != null ? DateTime.tryParse(j['joinedAt'] as String) : null,
        expiresAt:
            j['expiresAt'] != null ? DateTime.tryParse(j['expiresAt'] as String) : null,
        trainerName: j['trainerName'] as String?,
        ptNotes: j['ptNotes'] as String?,
      );
}

class GymClass {
  final int id;
  final String title;
  final String? schedule;
  final String? description;
  final String? trainerName;
  GymClass({required this.id, required this.title, this.schedule, this.description, this.trainerName});
  factory GymClass.fromJson(Map<String, dynamic> j) => GymClass(
        id: j['id'] as int,
        title: j['title'] as String,
        schedule: j['schedule'] as String?,
        description: j['description'] as String?,
        trainerName: j['trainerName'] as String?,
      );
}

class ActiveMember {
  final String displayName;
  final String? focus;
  ActiveMember(this.displayName, this.focus);
  factory ActiveMember.fromJson(Map<String, dynamic> j) =>
      ActiveMember(j['displayName'] as String? ?? 'Member', j['focus'] as String?);
}

class LeaderboardEntry {
  final int userId;
  final String displayName;
  final int workouts;
  final int volume;
  LeaderboardEntry(this.userId, this.displayName, this.workouts, this.volume);
  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        (j['userId'] as num).toInt(),
        j['displayName'] as String? ?? 'Member',
        (j['workouts'] as num?)?.toInt() ?? 0,
        (j['volume'] as num?)?.toInt() ?? 0,
      );
}

class GymMember {
  final int membershipId;
  final int userId;
  final String? displayName;
  final String email;
  final String role;
  final String status;
  final DateTime? joinedAt;

  GymMember({
    required this.membershipId,
    required this.userId,
    this.displayName,
    required this.email,
    required this.role,
    required this.status,
    this.joinedAt,
  });

  factory GymMember.fromJson(Map<String, dynamic> j) => GymMember(
        membershipId: j['membershipId'] as int,
        userId: j['userId'] as int,
        displayName: j['displayName'] as String?,
        email: j['email'] as String,
        role: j['role'] as String,
        status: j['status'] as String,
        joinedAt:
            j['joinedAt'] != null ? DateTime.tryParse(j['joinedAt'] as String) : null,
      );
}
