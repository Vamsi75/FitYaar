/// Abstraction over token persistence. The app uses the secure-storage
/// implementation ([TokenStorage]); tests can supply an in-memory one since
/// platform channels aren't available under `flutter test`.
abstract class TokenStore {
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clear();
}
