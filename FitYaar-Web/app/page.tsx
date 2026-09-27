import Link from "next/link";
import Section from "@/components/ui/Section";
import { CALCULATORS } from "@/lib/calc/catalog";

const INTENTS: { emoji: string; label: string; href: string }[] = [
  { emoji: "🏋", label: "Train", href: "/register" },
  { emoji: "🥗", label: "Eat better", href: "/calculators/protein" },
  { emoji: "📊", label: "Understand your body", href: "/calculators/tdee" },
  { emoji: "🧮", label: "Calculate", href: "/calculators" },
  { emoji: "📚", label: "Learn", href: "/calculators" },
  { emoji: "🔥", label: "Stay consistent", href: "/register" },
];

const MUSCLES: { label: string; muscle: string }[] = [
  { label: "Chest", muscle: "CHEST" },
  { label: "Back", muscle: "LATS" },
  { label: "Shoulders", muscle: "SIDE_DELTS" },
  { label: "Legs", muscle: "QUADRICEPS" },
  { label: "Arms", muscle: "BICEPS" },
  { label: "Core", muscle: "ABS" },
];

export default function Home() {
  return (
    <>
      {/* Hero */}
      <Section className="pt-16 sm:pt-24">
        <p className="text-sm font-semibold uppercase tracking-[0.2em] text-brand-light/80">
          Better you, together
        </p>
        <h1 className="mt-4 max-w-3xl text-4xl font-extrabold leading-tight tracking-tight text-white sm:text-6xl">
          Fitness, without the confusion.
        </h1>
        <p className="mt-5 max-w-xl text-lg text-white/70">
          Train. Track. Eat. Understand your body. One platform — an app that
          logs your training and a web that helps you learn and decide.
        </p>
        <div className="mt-8 flex flex-wrap gap-3">
          <Link href="/register" className="accent-btn">
            Start tracking
          </Link>
          <Link href="/calculators" className="glass-btn">
            Explore FitYaar
          </Link>
        </div>
      </Section>

      {/* What do you want to do today */}
      <Section>
        <h2 className="text-xs font-semibold uppercase tracking-wider text-white/45">
          What do you want to do today?
        </h2>
        <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
          {INTENTS.map((i) => (
            <Link
              key={i.label}
              href={i.href}
              className="glass flex flex-col items-center gap-2 p-4 text-center transition hover:border-brand-orange/40 hover:bg-white/[0.08]"
            >
              <span className="text-2xl">{i.emoji}</span>
              <span className="text-sm font-semibold text-white/85">
                {i.label}
              </span>
            </Link>
          ))}
        </div>
      </Section>

      {/* Popular tools */}
      <Section id="tools">
        <div className="flex items-end justify-between">
          <h2 className="text-2xl font-bold text-white">Popular tools</h2>
          <Link
            href="/calculators"
            className="text-sm font-semibold text-brand-light hover:underline"
          >
            All calculators →
          </Link>
        </div>
        <div className="mt-5 grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {CALCULATORS.slice(0, 4).map((c) => (
            <Link
              key={c.slug}
              href={`/calculators/${c.slug}`}
              className="glass p-5 transition hover:border-brand-orange/40 hover:bg-white/[0.08]"
            >
              <div className="text-2xl">{c.emoji}</div>
              <h3 className="mt-3 font-bold text-white">{c.title}</h3>
              <p className="mt-1 text-sm text-white/60">{c.blurb}</p>
            </Link>
          ))}
        </div>
      </Section>

      {/* Explore exercises (placeholder — the library lands in a later phase) */}
      <Section id="explore">
        <div className="flex items-end justify-between">
          <h2 className="text-2xl font-bold text-white">Explore exercises</h2>
          <Link
            href="/exercises"
            className="text-sm font-semibold text-brand-light hover:underline"
          >
            Browse all →
          </Link>
        </div>
        <div className="mt-5 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
          {MUSCLES.map((m) => (
            <Link
              key={m.muscle}
              href={`/exercises?muscle=${m.muscle}`}
              className="glass flex h-24 items-center justify-center p-4 text-center font-semibold text-white/70 transition hover:border-brand-orange/40 hover:bg-white/[0.08] hover:text-white"
            >
              {m.label}
            </Link>
          ))}
        </div>
      </Section>

      {/* App CTA */}
      <Section>
        <div className="glass flex flex-col items-start gap-5 p-8 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-2xl font-bold text-white">
              Track everything in the FitYaar app
            </h2>
            <p className="mt-2 max-w-lg text-white/65">
              Log workouts, sets and PRs, your India-first nutrition and water,
              and see your progress — all synced to one account.
            </p>
          </div>
          <Link href="/register" className="accent-btn shrink-0">
            Get FitYaar
          </Link>
        </div>
      </Section>
    </>
  );
}
