import '../../core/network/api_client.dart';
import '../../core/push/push_messaging.dart';
import '../../core/storage/token_store.dart';
import 'models/auth_models.dart';

/// Talks to /api/auth and persists the returned tokens.
class AuthService {
  final ApiClient _api;
  final TokenStore _storage;

  AuthService(this._api, this._storage);

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final json = await _api.post(
      '/auth/register',
      auth: false,
      body: {
        'email': email,
        'password': password,
        'displayName': displayName,
      },
    );
    return _persist(AuthResponse.fromJson(json as Map<String, dynamic>));
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final json = await _api.post(
      '/auth/login',
      auth: false,
      body: {'email': email, 'password': password},
    );
    return _persist(AuthResponse.fromJson(json as Map<String, dynamic>));
  }

  Future<void> logout() async {
    await PushMessaging.instance.removeToken(_api);
    await _storage.clear();
  }

  /// Register this device for push (after login / on an already-authed launch).
  Future<void> registerPush() => PushMessaging.instance.syncToken(_api);

  /// Current Pro entitlement (GET /api/me/entitlements).
  Future<Map<String, dynamic>> fetchEntitlements() async {
    final json = await _api.get('/me/entitlements');
    return json as Map<String, dynamic>;
  }

  Future<AuthResponse> _persist(AuthResponse res) async {
    await _storage.saveTokens(
      accessToken: res.accessToken,
      refreshToken: res.refreshToken,
    );
    return res;
  }
}
