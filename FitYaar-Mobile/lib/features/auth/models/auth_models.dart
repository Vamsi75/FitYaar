/// Authenticated user, as returned inside the backend's AuthResponse.
class AuthUser {
  final int id;
  final String email;
  final String? displayName;
  final String role;

  /// Computed FitYaar Pro entitlement (personal sub or gym-sponsored).
  final bool pro;
  final String? plan;
  final DateTime? until;

  AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    required this.role,
    this.pro = false,
    this.plan,
    this.until,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        email: json['email'] as String,
        displayName: json['displayName'] as String?,
        role: (json['role'] as String?) ?? 'USER',
        pro: json['pro'] as bool? ?? false,
        plan: json['plan'] as String?,
        until: json['until'] != null
            ? DateTime.tryParse(json['until'] as String)
            : null,
      );
}

/// Response from /api/auth/register and /api/auth/login.
class AuthResponse {
  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
