import Link from "next/link";
import type { ReactNode } from "react";
import Section from "@/components/ui/Section";
import TrackCta from "./TrackCta";

export default function CalcPage({
  title,
  intro,
  children,
  explainer,
  ctaLine,
}: {
  title: string;
  intro: string;
  children: ReactNode;
  explainer: ReactNode;
  ctaLine?: string;
}) {
  return (
    <Section>
      <nav className="mb-4 text-sm text-white/50">
        <Link href="/calculators" className="hover:text-white">
          Calculators
        </Link>
        <span className="px-2">/</span>
        <span className="text-white/70">{title}</span>
      </nav>

      <h1 className="text-3xl font-extrabold tracking-tight text-white sm:text-4xl">
        {title}
      </h1>
      <p className="mt-3 max-w-2xl text-white/65">{intro}</p>

      <div className="mt-7">{children}</div>

      <article className="mt-12 max-w-2xl space-y-5 leading-relaxed text-white/70 [&_h2]:mt-8 [&_h2]:text-xl [&_h2]:font-bold [&_h2]:text-white [&_li]:ml-4 [&_li]:list-disc [&_strong]:text-white/90">
        {explainer}
      </article>

      <TrackCta line={ctaLine} />
    </Section>
  );
}
