export type Role = "USER" | "PREMIUM" | "ADMIN";

/** Mirrors backend UserResponse. */
export interface AuthUser {
  id: number;
  email: string;
  displayName: string;
  role: Role;
  pro: boolean;
  plan: string | null;
  until: string | null;
}

/** Mirrors backend AuthResponse. */
export interface AuthResponse {
  accessToken: string;
  refreshToken: string;
  tokenType: string;
  expiresIn: number;
  user: AuthUser;
}

export interface RegisterInput {
  email: string;
  password: string;
  displayName: string;
}
