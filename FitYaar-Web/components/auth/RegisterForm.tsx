"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAuth } from "./AuthContext";
import AuthShell from "./AuthShell";
import { ApiError } from "@/lib/api";

export default function RegisterForm() {
  const { register } = useAuth();
  const router = useRouter();
  const [displayName, setDisplayName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (password.length < 8) {
      setError("Password must be at least 8 characters.");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      await register({ displayName, email, password });
      router.push("/me");
      router.refresh();
    } catch (err) {
      setError(err instanceof ApiError ? err.message : "Something went wrong.");
    } finally {
      setBusy(false);
    }
  }

  return (
    <AuthShell
      title="Create your FitYaar account"
      subtitle="One account for the app, the web and everything in between"
      footer={
        <>
          Already have an account?{" "}
          <Link href="/login" className="font-semibold text-brand-light">
            Log in
          </Link>
        </>
      }
    >
      <form onSubmit={onSubmit} className="space-y-4">
        <input
          type="text"
          required
          autoComplete="name"
          placeholder="Name"
          className="field"
          value={displayName}
          onChange={(e) => setDisplayName(e.target.value)}
        />
        <input
          type="email"
          required
          autoComplete="email"
          placeholder="Email"
          className="field"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
        />
        <input
          type="password"
          required
          autoComplete="new-password"
          placeholder="Password (min 8 characters)"
          className="field"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
        />
        {error && (
          <p className="rounded-pill border border-status-red/40 bg-status-red/10 px-4 py-2 text-sm text-status-red">
            {error}
          </p>
        )}
        <button type="submit" className="accent-btn w-full" disabled={busy}>
          {busy ? "Creating…" : "Create account"}
        </button>
      </form>
    </AuthShell>
  );
}
