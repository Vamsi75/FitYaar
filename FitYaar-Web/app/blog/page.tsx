import type { Metadata } from "next";
import Link from "next/link";
import Section from "@/components/ui/Section";
import { getAllPosts } from "@/lib/blog";

export const metadata: Metadata = {
  title: "Blog — Training & Nutrition, without the bro-science",
  description:
    "Practical, honest fitness and nutrition articles from FitYaar — India-first, no fluff.",
  alternates: { canonical: "/blog" },
};

function fmtDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-IN", {
    day: "2-digit",
    month: "short",
    year: "numeric",
  });
}

export default function Page() {
  const posts = getAllPosts();

  return (
    <Section>
      <h1 className="text-3xl font-extrabold tracking-tight text-white sm:text-4xl">
        FitYaar Blog
      </h1>
      <p className="mt-3 max-w-2xl text-white/65">
        Training and nutrition, explained simply and honestly. No bro-science,
        no fake gurus.
      </p>

      {posts.length === 0 ? (
        <div className="glass mt-8 p-8 text-center text-white/60">
          Fresh articles are on the way — check back soon.
        </div>
      ) : (
        <div className="mt-8 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {posts.map((p) => (
            <Link
              key={p.slug}
              href={`/blog/${p.slug}`}
              className="glass flex flex-col p-5 transition hover:border-brand-orange/40 hover:bg-white/[0.08]"
            >
              <div className="flex flex-wrap gap-2">
                {p.tags.slice(0, 2).map((t) => (
                  <span
                    key={t}
                    className="rounded-pill border border-white/12 bg-white/5 px-2 py-0.5 text-xs text-brand-light/90"
                  >
                    {t}
                  </span>
                ))}
              </div>
              <h2 className="mt-3 font-bold leading-snug text-white">
                {p.title}
              </h2>
              <p className="mt-2 flex-1 text-sm text-white/60">{p.excerpt}</p>
              <p className="mt-3 text-xs text-white/40">
                {fmtDate(p.date)} · {p.readingMinutes} min read
              </p>
            </Link>
          ))}
        </div>
      )}
    </Section>
  );
}
