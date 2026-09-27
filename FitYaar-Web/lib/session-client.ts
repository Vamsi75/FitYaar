import type { AuthUser, RegisterInput } from "./types";
import { ApiError } from "./api";

/**
 * Client-side session calls to the Next route handlers (which own the httpOnly
 * cookies). Identity for rendering is read from the non-httpOnly `fy_user` cookie.
 */
async function post(path: string, body?: unknown): Promise<AuthUser> {
  const res = await fetch(path, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  const data = await res.json().catch(() => null);
  if (!res.ok) {
    throw new ApiError(res.status, data?.message ?? "Something went wrong.");
  }
  return data.user as AuthUser;
}

export function sessionLogin(email: string, password: string): Promise<AuthUser> {
  return post("/api/session/login", { email, password });
}

export function sessionRegister(input: RegisterInput): Promise<AuthUser> {
  return post("/api/session/register", input);
}

export async function sessionLogout(): Promise<void> {
  try {
    await fetch("/api/session/logout", { method: "POST" });
  } catch {
    /* clearing local state is enough for UX; cookies expire regardless */
  }
}

/** Read the readable `fy_user` cookie (base64url JSON) for menu rendering. */
export function readUserCookie(): AuthUser | null {
  if (typeof document === "undefined") return null;
  const entry = document.cookie
    .split("; ")
    .find((c) => c.startsWith("fy_user="));
  if (!entry) return null;
  try {
    const raw = entry.slice("fy_user=".length);
    const b64 = raw.replace(/-/g, "+").replace(/_/g, "/");
    const bin = atob(b64);
    const bytes = Uint8Array.from(bin, (c) => c.charCodeAt(0));
    return JSON.parse(new TextDecoder().decode(bytes)) as AuthUser;
  } catch {
    return null;
  }
}
