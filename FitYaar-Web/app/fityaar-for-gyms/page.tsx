import type { Metadata } from "next";
import Link from "next/link";
import Section from "@/components/ui/Section";

export const metadata: Metadata = {
  title: "FitYaar for Gyms — Member & Trainer Management",
  description:
    "Run your gym and let FitYaar handle the tracking. Member and trainer management, live occupancy, workout & progress tracking, announcements and analytics — one platform.",
  alternates: { canonical: "/fityaar-for-gyms" },
};

const FEATURES: { emoji: string; title: string; body: string }[] = [
  {
    emoji: "👥",
    title: "Member management",
    body: "Approve join requests, manage memberships and see every member's status at a glance.",
  },
  {
    emoji: "🧑‍🏫",
    title: "Trainers & plans",
    body: "Add trainers, assign clients, and let them post plans-of-the-day and personal programs.",
  },
  {
    emoji: "📊",
    title: "Live occupancy",
    body: "See who's training right now, zone-by-zone crowd levels and your busiest hours.",
  },
  {
    emoji: "🏋",
    title: "Workout tracking",
    body: "Members log workouts, sets and PRs in the app — synced to one account, no clipboards.",
  },
  {
    emoji: "📣",
    title: "Announcements",
    body: "Post events and updates; members get them as push notifications instantly.",
  },
  {
    emoji: "💳",
    title: "Seats & billing",
    body: "Sponsor Pro for your members with seat-based plans, managed from your dashboard.",
  },
];

export default function Page() {
  return (
    <>
      <Section className="pt-16 sm:pt-24">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-brand-light/80">
          FitYaar for Gyms
        </p>
        <h1 className="mt-4 max-w-3xl text-4xl font-extrabold leading-tight tracking-tight text-white sm:text-5xl">
          Run your gym. Let FitYaar handle the tracking.
        </h1>
        <p className="mt-5 max-w-xl text-lg text-white/70">
          Member management, live gym insights, trainer tools and workout
          tracking — in the same app your members already love using.
        </p>
        <div className="mt-8 flex flex-wrap gap-3">
          <Link href="/register" className="accent-btn">
            Start your gym
          </Link>
          <Link href="/" className="glass-btn">
            See the platform
          </Link>
        </div>
      </Section>

      <Section>
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((f) => (
            <div key={f.title} className="glass p-5">
              <div className="text-2xl">{f.emoji}</div>
              <h2 className="mt-3 font-bold text-white">{f.title}</h2>
              <p className="mt-1 text-sm text-white/60">{f.body}</p>
            </div>
          ))}
        </div>
      </Section>

      <Section>
        <div className="glass flex flex-col items-start gap-5 p-8 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-2xl font-bold text-white">Try the demo gym</h2>
            <p className="mt-2 max-w-lg text-white/65">
              Create an account, then join the demo gym with code{" "}
              <code className="rounded bg-white/10 px-1.5 py-0.5 text-brand-light">
                IRON123
              </code>{" "}
              — or claim owner access with{" "}
              <code className="rounded bg-white/10 px-1.5 py-0.5 text-brand-light">
                OWNER123
              </code>{" "}
              to explore the management side.
            </p>
          </div>
          <Link href="/register" className="accent-btn shrink-0">
            Get started
          </Link>
        </div>
      </Section>
    </>
  );
}
