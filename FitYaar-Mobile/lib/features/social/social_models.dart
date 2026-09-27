class SocialUser {
  final int userId;
  final String displayName;
  final String? profilePictureUrl;
  final bool isPublic;
  final String followStatus; // NONE / PENDING / FOLLOWING / SELF

  SocialUser({
    required this.userId,
    required this.displayName,
    this.profilePictureUrl,
    this.isPublic = true,
    this.followStatus = 'NONE',
  });

  bool get isFollowing => followStatus == 'FOLLOWING';
  bool get isPending => followStatus == 'PENDING';
  bool get isSelf => followStatus == 'SELF';

  factory SocialUser.fromJson(Map<String, dynamic> j) => SocialUser(
        userId: j['userId'] as int,
        displayName: (j['displayName'] as String?) ?? 'Athlete',
        profilePictureUrl: j['profilePictureUrl'] as String?,
        isPublic: (j['isPublic'] as bool?) ?? true,
        followStatus: (j['followStatus'] as String?) ?? 'NONE',
      );
}

class PublicProfile {
  final int userId;
  final String? displayName;
  final String? bio;
  final String? profilePictureUrl;
  final bool isPublic;
  final int followersCount;
  final int followingCount;
  final int workoutsCount;
  final String followStatus;
  final bool canView;
  final bool self;

  PublicProfile({
    required this.userId,
    this.displayName,
    this.bio,
    this.profilePictureUrl,
    this.isPublic = true,
    this.followersCount = 0,
    this.followingCount = 0,
    this.workoutsCount = 0,
    this.followStatus = 'NONE',
    this.canView = false,
    this.self = false,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> j) => PublicProfile(
        userId: j['userId'] as int,
        displayName: j['displayName'] as String?,
        bio: j['bio'] as String?,
        profilePictureUrl: j['profilePictureUrl'] as String?,
        isPublic: (j['isPublic'] as bool?) ?? true,
        followersCount: (j['followersCount'] as num?)?.toInt() ?? 0,
        followingCount: (j['followingCount'] as num?)?.toInt() ?? 0,
        workoutsCount: (j['workoutsCount'] as num?)?.toInt() ?? 0,
        followStatus: (j['followStatus'] as String?) ?? 'NONE',
        canView: (j['canView'] as bool?) ?? false,
        self: (j['self'] as bool?) ?? false,
      );
}

class StatBlock {
  final int workouts;
  final int sets;
  final int volume;
  final int minutes;
  StatBlock({this.workouts = 0, this.sets = 0, this.volume = 0, this.minutes = 0});
  factory StatBlock.fromJson(Map<String, dynamic> j) => StatBlock(
        workouts: (j['workouts'] as num?)?.toInt() ?? 0,
        sets: (j['sets'] as num?)?.toInt() ?? 0,
        volume: (j['volume'] as num?)?.toInt() ?? 0,
        minutes: (j['minutes'] as num?)?.toInt() ?? 0,
      );
}

class CompareStats {
  final String meName;
  final String themName;
  final StatBlock me;
  final StatBlock them;
  CompareStats(
      {required this.meName, required this.themName, required this.me, required this.them});
  factory CompareStats.fromJson(Map<String, dynamic> j) => CompareStats(
        meName: (j['meName'] as String?) ?? 'You',
        themName: (j['themName'] as String?) ?? 'Them',
        me: StatBlock.fromJson(j['me'] as Map<String, dynamic>),
        them: StatBlock.fromJson(j['them'] as Map<String, dynamic>),
      );
}

class FeedItem {
  final int sessionId;
  final String? name;
  final DateTime? startTime;
  final int exercisesCount;
  final int sets;
  final int volume;
  final int authorId;
  final String authorName;

  FeedItem({
    required this.sessionId,
    this.name,
    this.startTime,
    this.exercisesCount = 0,
    this.sets = 0,
    this.volume = 0,
    required this.authorId,
    required this.authorName,
  });

  factory FeedItem.fromJson(Map<String, dynamic> j) => FeedItem(
        sessionId: j['sessionId'] as int,
        name: j['name'] as String?,
        startTime: j['startTime'] != null ? DateTime.tryParse(j['startTime'] as String) : null,
        exercisesCount: (j['exercisesCount'] as num?)?.toInt() ?? 0,
        sets: (j['sets'] as num?)?.toInt() ?? 0,
        volume: (j['volume'] as num?)?.toInt() ?? 0,
        authorId: j['authorId'] as int,
        authorName: (j['authorName'] as String?) ?? 'Athlete',
      );
}

class SocialCounts {
  final int followers;
  final int following;
  final int pendingRequests;
  SocialCounts({this.followers = 0, this.following = 0, this.pendingRequests = 0});
  factory SocialCounts.fromJson(Map<String, dynamic> j) => SocialCounts(
        followers: (j['followers'] as num?)?.toInt() ?? 0,
        following: (j['following'] as num?)?.toInt() ?? 0,
        pendingRequests: (j['pendingRequests'] as num?)?.toInt() ?? 0,
      );
}
