import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import Section from "@/components/ui/Section";
import TrackCta from "@/components/calculators/TrackCta";
import MuscleMap from "@/components/exercises/MuscleMap";
import { getExercise, getExercises } from "@/lib/exercises";
import { humanize } from "@/lib/muscles";

type Params = { params: Promise<{ slug: string }> };

export async function generateMetadata({ params }: Params): Promise<Metadata> {
  const { slug } = await params;
  const ex = await getExercise(slug);
  if (!ex) return { title: "Exercise not found" };
  const muscles = ex.primaryMuscles.map(humanize).join(", ");
  return {
    title: `${ex.name} — Muscles Worked & How to Train It`,
    description: `${ex.name}${muscles ? ` primarily works your ${muscles}.` : "."} Equipment, muscles worked and how to track it in FitYaar.`,
    alternates: { canonical: `/exercises/${slug}` },
  };
}

function summary(ex: {
  category: string | null;
  exerciseType: string | null;
  equipment: string | null;
  primaryMuscles: string[];
}): string {
  const type = humanize(ex.category) || "strength";
  const equip = ex.equipment ? ` using ${humanize(ex.equipment).toLowerCase()}` : "";
  const muscles = ex.primaryMuscles.map(humanize).join(", ");
  return `A ${type.toLowerCase()} exercise${equip}${
    muscles ? ` that primarily targets your ${muscles.toLowerCase()}` : ""
  }.`;
}

export default async function Page({ params }: Params) {
  const { slug } = await params;
  const ex = await getExercise(slug);
  if (!ex) notFound();

  const all = await getExercises();
  const related = all
    .filter(
      (e) =>
        e.slug !== ex.slug &&
        e.primaryMuscles.some((m) => ex.primaryMuscles.includes(m)),
    )
    .slice(0, 6);

  const badges = [
    humanize(ex.category),
    humanize(ex.equipment),
    humanize(ex.exerciseType),
  ].filter(Boolean);

  return (
    <Section>
      <nav className="mb-4 text-sm text-white/50">
        <Link href="/exercises" className="hover:text-white">
          Exercises
        </Link>
        <span className="px-2">/</span>
        <span className="text-white/70">{ex.name}</span>
      </nav>

      <h1 className="text-3xl font-extrabold tracking-tight text-white sm:text-4xl">
        {ex.name}
      </h1>

      <div className="mt-3 flex flex-wrap gap-2">
        {badges.map((b) => (
          <span
            key={b}
            className="rounded-pill border border-white/12 bg-white/5 px-3 py-1 text-sm text-white/70"
          >
            {b}
          </span>
        ))}
      </div>

      <p className="mt-4 max-w-2xl text-white/70">{summary(ex)}</p>
      {ex.description && (
        <p className="mt-2 max-w-2xl text-white/60">{ex.description}</p>
      )}

      {/* Muscles worked */}
      <div className="mt-8 grid gap-4 lg:grid-cols-[minmax(280px,1fr)_1.2fr]">
        <div className="glass p-5">
          <h2 className="mb-3 text-xs font-semibold uppercase tracking-wide text-white/50">
            Muscle map
          </h2>
          <MuscleMap
            primaryMuscles={ex.primaryMuscles}
            secondaryMuscles={ex.secondaryMuscles}
          />
        </div>
        <div className="space-y-4">
          <div className="glass p-5">
            <h2 className="text-xs font-semibold uppercase tracking-wide text-white/50">
              Primary muscles
            </h2>
          <div className="mt-3 flex flex-wrap gap-2">
            {ex.primaryMuscles.length ? (
              ex.primaryMuscles.map((m) => (
                <span
                  key={m}
                  className="rounded-pill border border-brand-orange/50 bg-brand-orange/20 px-3 py-1 text-sm font-semibold text-brand-light"
                >
                  {humanize(m)}
                </span>
              ))
            ) : (
              <span className="text-sm text-white/40">—</span>
            )}
          </div>
        </div>
        <div className="glass p-5">
          <h2 className="text-xs font-semibold uppercase tracking-wide text-white/50">
            Secondary muscles
          </h2>
          <div className="mt-3 flex flex-wrap gap-2">
            {ex.secondaryMuscles.length ? (
              ex.secondaryMuscles.map((m) => (
                <span
                  key={m}
                  className="rounded-pill border border-white/12 bg-white/5 px-3 py-1 text-sm text-white/70"
                >
                  {humanize(m)}
                </span>
              ))
            ) : (
              <span className="text-sm text-white/40">None</span>
            )}
            </div>
          </div>
        </div>
      </div>

      <TrackCta line={`Add ${ex.name} to a workout and track your sets, reps and PRs in the FitYaar app.`} />

      {related.length > 0 && (
        <div className="mt-12">
          <h2 className="text-xl font-bold text-white">Related exercises</h2>
          <div className="mt-4 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {related.map((e) => (
              <Link
                key={e.slug}
                href={`/exercises/${e.slug}`}
                className="glass p-4 transition hover:border-brand-orange/40 hover:bg-white/[0.08]"
              >
                <h3 className="font-semibold text-white">{e.name}</h3>
                <p className="mt-1 text-sm text-brand-light/90">
                  {e.primaryMuscles.map(humanize).join(" · ") || "—"}
                </p>
              </Link>
            ))}
          </div>
        </div>
      )}
    </Section>
  );
}
