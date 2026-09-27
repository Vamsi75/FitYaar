import type { Metadata } from "next";
import Link from "next/link";
import Section from "@/components/ui/Section";

export const metadata: Metadata = {
  title: "About FitYaar",
  description:
    "FitYaar is an India-first fitness platform — one account across an app that tracks your training, a website that helps you learn, and tools for gyms.",
  alternates: { canonical: "/about" },
};

export default function Page() {
  return (
    <Section className="pt-16">
      <p className="text-sm font-semibold uppercase tracking-[0.2em] text-brand-light/80">
        Better you, together
      </p>
      <h1 className="mt-4 max-w-3xl text-4xl font-extrabold tracking-tight text-white sm:text-5xl">
        Fitness that feels made for here.
      </h1>

      <div className="mt-6 max-w-2xl space-y-5 leading-relaxed text-white/70">
        <p>
          FitYaar is a fitness platform built India-first. Most tracking apps are
          designed around a Western gym and Western food. We&apos;re building the
          one that understands dal, roti and curd as naturally as chicken and
          rice — and that speaks like a friend, not a coach barking at you.
        </p>
        <p>
          It&apos;s <strong>one platform with three faces</strong>. The{" "}
          <strong>app</strong> is where you log workouts, nutrition, water and
          progress. The <strong>website</strong> — the one you&apos;re on — is
          where you learn, calculate and discover without any sign-up. And for
          gyms, there&apos;s a management side that turns all of that into member
          and trainer tools.
        </p>
        <p>
          Behind all three is a <strong>single account and a single backend</strong>
          , so your data and identity move with you wherever you meet FitYaar.
        </p>
        <p>
          No bro-science, no fake gurus, no spammy content. Just useful tools,
          honest information and a product that respects your time.
        </p>
      </div>

      <div className="mt-8 flex flex-wrap gap-3">
        <Link href="/register" className="accent-btn">
          Create your account
        </Link>
        <Link href="/calculators" className="glass-btn">
          Explore the tools
        </Link>
      </div>
    </Section>
  );
}
