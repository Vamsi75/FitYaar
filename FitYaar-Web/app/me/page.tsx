"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import Link from "next/link";
import { useAuth } from "@/components/auth/AuthContext";
import { API_BASE } from "@/lib/api";
import Section from "@/components/ui/Section";

export default function MePage() {
  const { user, loading } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (!loading && !user) router.replace("/login");
  }, [loading, user, router]);

  if (loading || !user) {
    return (
      <Section>
        <p className="text-white/55">Loading…</p>
      </Section>
    );
  }

  return (
    <Section>
      <p className="text-sm font-semibold uppercase tracking-wider text-white/45">
        Signed in
      </p>
      <h1 className="mt-2 text-3xl font-extrabold text-white sm:text-4xl">
        Hi, {user.displayName}
      </h1>
      <div className="mt-2 flex flex-wrap items-center gap-2 text-sm text-white/60">
        <span>{user.email}</span>
        <span className="rounded-pill border border-white/12 bg-white/5 px-2 py-0.5 text-xs uppercase tracking-wide">
          {user.role}
        </span>
        {user.pro && (
          <span className="rounded-pill border border-brand-gold/40 bg-brand-gold/10 px-2 py-0.5 text-xs font-semibold text-brand-gold">
            PRO{user.plan ? ` · ${user.plan}` : ""}
          </span>
        )}
      </div>

      <div className="mt-8 grid gap-4 sm:grid-cols-2">
        <div className="glass p-6">
          <h2 className="text-lg font-bold text-white">My Fitness</h2>
          <p className="mt-1 text-sm text-white/60">
            Your workouts, nutrition and progress live in the FitYaar app today.
            The web dashboard is coming next.
          </p>
          <div className="mt-4 flex gap-2">
            <Link href="/calculators" className="glass-btn">
              Open tools
            </Link>
          </div>
        </div>

        <div id="gym" className="glass p-6">
          <h2 className="text-lg font-bold text-white">My Gym</h2>
          <p className="mt-1 text-sm text-white/60">
            Gym membership, check-ins and your trainer&apos;s plans are managed
            in the app. Web gym pages arrive in a later phase.
          </p>
        </div>

        {user.role === "ADMIN" && (
          <div className="glass border-brand-orange/30 p-6 sm:col-span-2">
            <h2 className="text-lg font-bold text-brand-light">
              FitYaar Management
            </h2>
            <p className="mt-1 text-sm text-white/60">
              Platform cockpit — gyms, users, subscriptions, audit and metrics.
            </p>
            <button
              onClick={() => {
                window.location.href = `${API_BASE}/admin/`;
              }}
              className="accent-btn mt-4"
            >
              Open management portal ↗
            </button>
          </div>
        )}
      </div>
    </Section>
  );
}
