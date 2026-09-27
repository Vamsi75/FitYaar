import '../../core/network/api_client.dart';
import 'profile_models.dart';

class ProfileService {
  final ApiClient _api;
  ProfileService(this._api);

  Future<ProfileData> getProfile() async {
    final json = await _api.get('/users/profile') as Map<String, dynamic>;
    return ProfileData.fromJson(json);
  }

  Future<ProfileData> updateProfile({
    String? displayName,
    String? bio,
    String? profilePictureUrl,
    String? fitnessGoal,
    String? gender,
    DateTime? birthday,
    String? instagram,
    String? website,
    String? phone,
    double? currentWeight,
    double? targetWeight,
    double? height,
    double? dailyCalorieGoal,
    bool? gymVisible,
    bool? isPublic,
    String? theme,
    String? language,
    String? weightUnit,
    String? distanceUnit,
    String? measurementUnit,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) body['displayName'] = displayName;
    if (bio != null) body['bio'] = bio;
    if (profilePictureUrl != null) body['profilePictureUrl'] = profilePictureUrl;
    if (fitnessGoal != null) body['fitnessGoal'] = fitnessGoal;
    if (gender != null) body['gender'] = gender;
    if (birthday != null) {
      body['birthday'] = birthday.toIso8601String().split('T').first;
    }
    if (instagram != null) body['instagram'] = instagram;
    if (website != null) body['website'] = website;
    if (phone != null) body['phone'] = phone;
    if (currentWeight != null) body['currentWeight'] = currentWeight;
    if (targetWeight != null) body['targetWeight'] = targetWeight;
    if (height != null) body['height'] = height;
    if (dailyCalorieGoal != null) body['dailyCalorieGoal'] = dailyCalorieGoal;
    if (gymVisible != null) body['gymVisible'] = gymVisible;
    if (isPublic != null) body['isPublic'] = isPublic;
    if (theme != null) body['theme'] = theme;
    if (language != null) body['language'] = language;
    if (weightUnit != null) body['weightUnit'] = weightUnit;
    if (distanceUnit != null) body['distanceUnit'] = distanceUnit;
    if (measurementUnit != null) body['measurementUnit'] = measurementUnit;

    final json = await _api.put('/users/profile', body: body) as Map<String, dynamic>;
    return ProfileData.fromJson(json);
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    await _api.post('/users/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<void> updateEmail(String newEmail, String password) async {
    await _api.post('/users/update-email', body: {
      'newEmail': newEmail,
      'password': password,
    });
  }

  Future<void> deleteAccount() async {
    await _api.delete('/users');
  }
}
