import 'package:google_sign_in/google_sign_in.dart';

import '../../core/config/google_config.dart';
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

  bool _googleReady = false;

  /// Google sign-in: shows the account picker, sends the ID token to the backend
  /// (which verifies it and creates the account on first use) and stores our tokens.
  /// Returns null if the user closed the picker.
  Future<AuthResponse?> loginWithGoogle() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize(
        serverClientId: GoogleConfig.serverClientId,
        clientId:
            GoogleConfig.iosClientId.isEmpty ? null : GoogleConfig.iosClientId,
      );
      _googleReady = true;
    }
    final GoogleSignInAccount account;
    try {
      account = await google.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw ApiException(
          0, 'Google didn\'t return a sign-in token. Try again.');
    }
    final json = await _api
        .post('/auth/google', auth: false, body: {'idToken': idToken});
    return _persist(AuthResponse.fromJson(json as Map<String, dynamic>));
  }

  Future<void> logout() async {
    await PushMessaging.instance.removeToken(_api);
    await _storage.clear();
    // Forget the Google account so the next sign-in shows the picker again.
    if (_googleReady) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  /// Register this device for push (after login / on an already-authed launch).
  Future<void> registerPush() => PushMessaging.instance.syncToken(_api);

  /// The signed-in user (GET /api/users/me) — restores the session on a cold start.
  Future<AuthUser> fetchMe() async {
    final json = await _api.get('/users/me') as Map<String, dynamic>;
    return AuthUser.fromJson(json);
  }

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
