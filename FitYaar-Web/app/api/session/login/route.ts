import { NextRequest, NextResponse } from "next/server";
import { backendBase, setSessionCookies } from "@/lib/session";

export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => null);
  let backendRes: Response;
  try {
    backendRes = await fetch(`${backendBase()}/api/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body ?? {}),
    });
  } catch {
    return NextResponse.json(
      { message: "Can't reach FitYaar. Is the backend running?" },
      { status: 502 },
    );
  }
  const data = await backendRes.json().catch(() => null);
  if (!backendRes.ok) {
    return NextResponse.json(
      { message: data?.message ?? "Login failed" },
      { status: backendRes.status },
    );
  }
  const res = NextResponse.json({ user: data.user });
  setSessionCookies(res, data);
  return res;
}
