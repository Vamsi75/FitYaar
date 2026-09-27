import type { NextResponse } from "next/server";
import type { AuthUser } from "./types";

/**
 * Server-side session cookie helpers. The website session lives in httpOnly cookies
 * set by the Next route handlers (app/api/session/*) — the browser never sees the
 * tokens in JS. A readable `fy_user` cookie (base64url JSON, non-secret) lets the UI
 * and the same-origin /admin portal know the identity/role without a round-trip.
 */
const isProd = process.env.NODE_ENV === "production";
const THIRTY_DAYS = 60 * 60 * 24 * 30;

export function backendBase(): string {
  return (
    process.env.API_BASE_URL ??
    process.env.NEXT_PUBLIC_API_BASE_URL ??
    "http://localhost:2098"
  );
}

interface AuthResponseShape {
  accessToken: string;
  refreshToken: string;
  expiresIn: number; // milliseconds
  user: AuthUser;
}

export function setSessionCookies(res: NextResponse, data: AuthResponseShape): void {
  const httpBase = {
    httpOnly: true,
    secure: isProd,
    sameSite: "lax" as const,
    path: "/",
  };
  const atMaxAge = data.expiresIn ? Math.floor(data.expiresIn / 1000) : THIRTY_DAYS;

  res.cookies.set("fy_at", data.accessToken, { ...httpBase, maxAge: atMaxAge });
  res.cookies.set("fy_rt", data.refreshToken, { ...httpBase, maxAge: THIRTY_DAYS });

  // Readable identity (base64url so it's cookie- and URL-safe, and UTF-8 clean).
  const encoded = Buffer.from(JSON.stringify(data.user), "utf8").toString("base64url");
  res.cookies.set("fy_user", encoded, {
    httpOnly: false,
    secure: isProd,
    sameSite: "lax",
    path: "/",
    maxAge: THIRTY_DAYS,
  });
}

export function clearSessionCookies(res: NextResponse): void {
  for (const name of ["fy_at", "fy_rt", "fy_user"]) {
    res.cookies.set(name, "", { path: "/", maxAge: 0 });
  }
}
