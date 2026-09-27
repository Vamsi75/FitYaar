// End-to-end test of the app's networking layer against the LIVE backend.
// Run with the dev backend up on the host:
//   flutter test test/auth_api_integration_test.dart --dart-define=API_BASE_URL=http://localhost:2098
import 'package:flutter_test/flutter_test.dart';

import 'package:fityaar/core/network/api_client.dart';
import 'package:fityaar/core/storage/token_store.dart';
import 'package:fityaar/features/auth/auth_service.dart';

/// In-memory [TokenStore] so the test avoids platform-channel secure storage.
class InMemoryTokenStore implements TokenStore {
  String? _access;
  String? _refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
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
  final email = 'mob_${DateTime.now().millisecondsSinceEpoch}@fityaar.com';
  const password = 'password123';

  test('register returns tokens and persists the access token', () async {
    final res = await auth.register(
      email: email,
      password: password,
      displayName: 'Mobile Test',
    );
    expect(res.accessToken, isNotEmpty);
    expect(res.refreshToken, isNotEmpty);
    expect(res.user.email, email);
    expect(await store.getAccessToken(), isNotEmpty);
  });

  test('authenticated GET /users/profile returns the profile', () async {
    final profile = await api.get('/users/profile') as Map<String, dynamic>;
    expect(profile['displayName'], 'Mobile Test');
  });

  test('login with correct password returns tokens', () async {
    final res = await auth.login(email: email, password: password);
    expect(res.accessToken, isNotEmpty);
  });

  test('login with wrong password throws ApiException(401)', () async {
    await expectLater(
      auth.login(email: email, password: 'wrong-password'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 401)),
    );
  });

  test('duplicate register throws ApiException(409)', () async {
    await expectLater(
      auth.register(email: email, password: password, displayName: 'Dup'),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 409)),
    );
  });

  test('refresh rotates the token; the old refresh token is rejected', () async {
    final rt = await store.getRefreshToken();
    final r1 = await api.post('/auth/refresh', auth: false, body: {'refreshToken': rt})
        as Map<String, dynamic>;
    expect(r1['accessToken'], isNotEmpty);
    expect(r1['refreshToken'], isNot(rt));
    // The old (rotated) refresh token must no longer work.
    await expectLater(
      api.post('/auth/refresh', auth: false, body: {'refreshToken': rt}),
      throwsA(isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401)),
    );
  });
}
