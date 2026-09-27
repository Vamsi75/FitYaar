import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { MDXRemote } from "next-mdx-remote/rsc";
import remarkGfm from "remark-gfm";
import Section from "@/components/ui/Section";
import TrackCta from "@/components/calculators/TrackCta";
import { mdxComponents } from "@/components/blog/mdx";
import { getPostBySlug, getPostSlugs } from "@/lib/blog";

type Params = { params: Promise<{ slug: string }> };

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? "https://fityaar.com";

export function generateStaticParams() {
  return getPostSlugs().map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { slug } = await params;
  const post = getPostBySlug(slug);
  if (!post) return { title: "Article not found" };
  return {
    title: post.title,
    description: post.description,
    alternates: { canonical: `/blog/${slug}` },
    openGraph: {
      type: "article",
      title: post.title,
      description: post.description,
      publishedTime: post.date,
      url: `${siteUrl}/blog/${slug}`,
    },
  };
}

function fmtDate(iso: string): string {
  return new Date(iso).toLocaleDateString("en-IN", {
    day: "2-digit",
    month: "long",
    year: "numeric",
  });
}

export default async function Page({ params }: Params) {
  const { slug } = await params;
  const post = getPostBySlug(slug);
  if (!post) notFound();

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "BlogPosting",
    headline: post.title,
    description: post.description,
    datePublished: post.date,
    dateModified: post.date,
    author: { "@type": "Organization", name: "FitYaar" },
    publisher: { "@type": "Organization", name: "FitYaar" },
    mainEntityOfPage: `${siteUrl}/blog/${slug}`,
    keywords: post.tags.join(", "),
  };

  return (
    <Section>
      <nav className="mb-4 text-sm text-white/50">
        <Link href="/blog" className="hover:text-white">
          Blog
        </Link>
        <span className="px-2">/</span>
        <span className="text-white/70">{post.title}</span>
      </nav>

      <article className="mx-auto max-w-2xl">
        <div className="flex flex-wrap gap-2">
          {post.tags.map((t) => (
            <span
              key={t}
              className="rounded-pill border border-white/12 bg-white/5 px-2.5 py-0.5 text-xs text-brand-light/90"
            >
              {t}
            </span>
          ))}
        </div>
        <h1 className="mt-3 text-3xl font-extrabold leading-tight tracking-tight text-white sm:text-4xl">
          {post.title}
        </h1>
        <p className="mt-3 text-sm text-white/45">
          {fmtDate(post.date)} · {post.readingMinutes} min read · {post.author}
        </p>

        <div className="prose prose-invert mt-8 max-w-none prose-headings:text-white prose-a:text-brand-light prose-a:no-underline hover:prose-a:underline prose-strong:text-white prose-th:text-white/80">
          <MDXRemote
            source={post.content}
            components={mdxComponents}
            options={{ mdxOptions: { remarkPlugins: [remarkGfm] } }}
          />
        </div>
      </article>

      <div className="mx-auto max-w-2xl">
        <TrackCta />
      </div>

      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd) }}
      />
    </Section>
  );
}
