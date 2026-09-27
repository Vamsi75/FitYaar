import fs from "node:fs";
import path from "node:path";
import matter from "gray-matter";

const BLOG_DIR = path.join(process.cwd(), "content", "blog");

export interface PostMeta {
  slug: string;
  title: string;
  description: string;
  date: string; // ISO
  excerpt: string;
  author: string;
  tags: string[];
  readingMinutes: number;
}

export interface Post extends PostMeta {
  content: string;
}

function readingMinutes(text: string): number {
  const words = text.trim().split(/\s+/).filter(Boolean).length;
  return Math.max(1, Math.round(words / 200));
}

export function getPostSlugs(): string[] {
  if (!fs.existsSync(BLOG_DIR)) return [];
  return fs
    .readdirSync(BLOG_DIR)
    .filter((f) => f.endsWith(".mdx"))
    .map((f) => f.replace(/\.mdx$/, ""));
}

export function getPostBySlug(slug: string): Post | null {
  const file = path.join(BLOG_DIR, `${slug}.mdx`);
  if (!fs.existsSync(file)) return null;
  const { data, content } = matter(fs.readFileSync(file, "utf8"));
  return {
    slug,
    title: data.title ?? slug,
    description: data.description ?? "",
    date: data.date
      ? new Date(data.date).toISOString()
      : new Date(0).toISOString(),
    excerpt: data.excerpt ?? data.description ?? "",
    author: data.author ?? "FitYaar",
    tags: Array.isArray(data.tags) ? data.tags : [],
    readingMinutes: readingMinutes(content),
    content,
  };
}

export function getAllPosts(): PostMeta[] {
  return getPostSlugs()
    .map(getPostBySlug)
    .filter((p): p is Post => p !== null)
    .sort((a, b) => (a.date < b.date ? 1 : -1))
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    .map(({ content, ...meta }) => meta);
}
