import type { Metadata } from "next";
import Link from "next/link";
import Section from "@/components/ui/Section";
import { CALCULATORS, CALCULATORS_SOON } from "@/lib/calc/catalog";

export const metadata: Metadata = {
  title: "Fitness Calculators & Tools",
  description:
    "Free fitness calculators from FitYaar — TDEE, BMR, protein and BMI. Get a number, understand what it means, then track the real thing in the app.",
  alternates: { canonical: "/calculators" },
};

export default function Page() {
  return (
    <Section>
      <h1 className="text-3xl font-extrabold tracking-tight text-white sm:text-4xl">
        FitYaar Tools
      </h1>
      <p className="mt-3 max-w-2xl text-white/65">
        Simple, honest calculators — each one explains what the number means and
        what it doesn&apos;t. No sign-up needed.
      </p>

      <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        {CALCULATORS.map((c) => (
          <Link
            key={c.slug}
            href={`/calculators/${c.slug}`}
            className="glass group p-5 transition hover:border-brand-orange/40 hover:bg-white/[0.08]"
          >
            <div className="text-2xl">{c.emoji}</div>
            <h2 className="mt-3 font-bold text-white">{c.title}</h2>
            <p className="mt-1 text-sm text-white/60">{c.blurb}</p>
            <span className="mt-3 inline-block text-sm font-semibold text-brand-light">
              Open →
            </span>
          </Link>
        ))}
      </div>

      <h3 className="mt-12 text-xs font-semibold uppercase tracking-wider text-white/45">
        More tools coming soon
      </h3>
      <div className="mt-3 flex flex-wrap gap-2">
        {CALCULATORS_SOON.map((name) => (
          <span
            key={name}
            className="rounded-pill border border-white/10 bg-white/5 px-3 py-1.5 text-sm text-white/45"
          >
            {name}
          </span>
        ))}
      </div>
    </Section>
  );
}
