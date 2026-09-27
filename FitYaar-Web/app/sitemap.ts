import type { MetadataRoute } from "next";
import { getExercises } from "@/lib/exercises";
import { CALCULATORS } from "@/lib/calc/catalog";
import { getAllPosts } from "@/lib/blog";

const base = process.env.NEXT_PUBLIC_SITE_URL ?? "https://fityaar.com";

const staticRoutes = [
  "",
  "/exercises",
  "/calculators",
  "/blog",
  "/fityaar-for-gyms",
  "/about",
];

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const entries: MetadataRoute.Sitemap = staticRoutes.map((path) => ({
    url: `${base}${path}`,
    changeFrequency: "weekly",
    priority: path === "" ? 1 : 0.7,
  }));

  // Calculator pages (from the shared catalog).
  for (const c of CALCULATORS) {
    entries.push({
      url: `${base}/calculators/${c.slug}`,
      changeFrequency: "monthly",
      priority: 0.7,
    });
  }

  // Blog posts (from local MDX).
  for (const post of getAllPosts()) {
    entries.push({
      url: `${base}/blog/${post.slug}`,
      lastModified: post.date,
      changeFrequency: "monthly",
      priority: 0.7,
    });
  }

  // Exercise library pages (resilient — empty if the backend is unreachable at build).
  const exercises = await getExercises();
  for (const e of exercises) {
    entries.push({
      url: `${base}/exercises/${e.slug}`,
      changeFrequency: "monthly",
      priority: 0.6,
    });
  }

  return entries;
}
