import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_store.dart';
import 'auth_service.dart';
import 'models/auth_models.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Holds auth state for the app and drives the auth-gated navigation.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final TokenStore _storage;

  AuthProvider(this._authService, this._storage);

  AuthStatus _status = AuthStatus.unknown;
  AuthUser? _user;
  String? _error;
  bool _loading = false;

  // FitYaar Pro entitlement (from login response, refreshable via /me/entitlements).
  bool _pro = false;
  String? _proPlan;
  DateTime? _proUntil;

  AuthStatus get status => _status;
  AuthUser? get user => _user;
  String? get error => _error;
  bool get loading => _loading;
  bool get isPro => _pro;
  String? get proPlan => _proPlan;
  DateTime? get proUntil => _proUntil;

  /// Called on app start: if a token exists, treat the session as authenticated.
  Future<void> bootstrap() async {
    // Hold the animated splash long enough for the spinner + logo reveal to play.
    final minSplash = Future<void>.delayed(const Duration(milliseconds: 2200));
    final token = await _storage.getAccessToken();
    await minSplash;
    _status =
        token != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    if (token != null) {
      _authService.registerPush();
      refreshEntitlements();
    }
    notifyListeners();
  }

  /// Re-fetch Pro from the backend (after a grant / gym-plan change).
  Future<void> refreshEntitlements() async {
    try {
      final e = await _authService.fetchEntitlements();
      _pro = e['pro'] as bool? ?? false;
      _proPlan = e['plan'] as String?;
      final until = e['until'];
      _proUntil = until is String ? DateTime.tryParse(until) : null;
      notifyListeners();
    } catch (_) {/* keep last known entitlement */}
  }

  Future<bool> login(String email, String password) =>
      _run(() => _authService.login(email: email, password: password));

  Future<bool> register(String email, String password, String displayName) =>
      _run(() => _authService.register(
            email: email,
            password: password,
            displayName: displayName,
          ));

  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _pro = false;
    _proPlan = null;
    _proUntil = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> _run(Future<AuthResponse> Function() action) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await action();
      _user = res.user;
      _pro = res.user.pro;
      _proPlan = res.user.plan;
      _proUntil = res.user.until;
      _status = AuthStatus.authenticated;
      _loading = false;
      _authService.registerPush();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _loading = false;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Could not reach the server. Is the backend running?';
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
