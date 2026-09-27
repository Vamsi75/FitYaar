class ProfileData {
  final String? email;
  final String? displayName;
  final String? bio;
  final String? profilePictureUrl;
  final String? fitnessGoal;
  final double? currentWeight;
  final double? targetWeight;
  final double? height;
  final double? dailyCalorieGoal;
  final bool isPublic;
  final bool gymVisible;
  final String? gender;
  final DateTime? birthday;
  final String? instagram;
  final String? website;
  final String? phone;
  final String? theme;
  final String? language;
  final String? weightUnit;
  final String? distanceUnit;
  final String? measurementUnit;

  ProfileData({
    this.email,
    this.displayName,
    this.bio,
    this.profilePictureUrl,
    this.fitnessGoal,
    this.currentWeight,
    this.targetWeight,
    this.height,
    this.dailyCalorieGoal,
    this.isPublic = true,
    this.gymVisible = true,
    this.gender,
    this.birthday,
    this.instagram,
    this.website,
    this.phone,
    this.theme,
    this.language,
    this.weightUnit,
    this.distanceUnit,
    this.measurementUnit,
  });

  factory ProfileData.fromJson(Map<String, dynamic> j) => ProfileData(
        email: j['email'] as String?,
        displayName: j['displayName'] as String?,
        bio: j['bio'] as String?,
        profilePictureUrl: j['profilePictureUrl'] as String?,
        fitnessGoal: j['fitnessGoal'] as String?,
        currentWeight: (j['currentWeight'] as num?)?.toDouble(),
        targetWeight: (j['targetWeight'] as num?)?.toDouble(),
        height: (j['height'] as num?)?.toDouble(),
        dailyCalorieGoal: (j['dailyCalorieGoal'] as num?)?.toDouble(),
        isPublic: (j['isPublic'] as bool?) ?? true,
        gymVisible: (j['gymVisible'] as bool?) ?? true,
        gender: j['gender'] as String?,
        birthday: j['birthday'] != null
            ? DateTime.tryParse(j['birthday'] as String)
            : null,
        instagram: j['instagram'] as String?,
        website: j['website'] as String?,
        phone: j['phone'] as String?,
        theme: j['theme'] as String?,
        language: j['language'] as String?,
        weightUnit: j['weightUnit'] as String?,
        distanceUnit: j['distanceUnit'] as String?,
        measurementUnit: j['measurementUnit'] as String?,
      );
}
