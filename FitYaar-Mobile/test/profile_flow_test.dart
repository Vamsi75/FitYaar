// Profile get/update against the LIVE backend.
//   flutter test test/profile_flow_test.dart --dart-define=API_BASE_URL=http://localhost:2098
import 'package:flutter_test/flutter_test.dart';

import 'package:fityaar/core/network/api_client.dart';
import 'package:fityaar/core/storage/token_store.dart';
import 'package:fityaar/features/auth/auth_service.dart';
import 'package:fityaar/features/profile/profile_service.dart';

class InMemoryTokenStore implements TokenStore {
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
  final store = InMemoryTokenStore();
  final api = ApiClient(store);
  final auth = AuthService(api, store);
  final profile = ProfileService(api);
  final email = 'pf_${DateTime.now().millisecondsSinceEpoch}@fityaar.com';

  test('register then fetch profile', () async {
    await auth.register(
        email: email, password: 'password123', displayName: 'Pro File');
    final p = await profile.getProfile();
    expect(p.displayName, 'Pro File');
  });

  test('update profile bio persists', () async {
    final updated =
        await profile.updateProfile(bio: 'I lift in Bengaluru', displayName: 'Pro File');
    expect(updated.bio, 'I lift in Bengaluru');
  });

  test('update links + private fields persist', () async {
    final updated = await profile.updateProfile(
      displayName: 'Pro File',
      instagram: '@profile',
      website: 'https://fityaar.app',
      gender: 'Male',
      birthday: DateTime(1998, 5, 20),
    );
    expect(updated.instagram, '@profile');
    expect(updated.website, 'https://fityaar.app');
    expect(updated.gender, 'Male');
    expect(updated.birthday?.year, 1998);
  });
}
