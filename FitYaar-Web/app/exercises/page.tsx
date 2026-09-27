import type { Metadata } from "next";
import Section from "@/components/ui/Section";
import ExerciseBrowser from "@/components/exercises/ExerciseBrowser";
import { getExercises } from "@/lib/exercises";

export const metadata: Metadata = {
  title: "Exercise Library",
  description:
    "Browse the FitYaar exercise library — muscles worked, equipment and movement type for every exercise. Free, no sign-up.",
  alternates: { canonical: "/exercises" },
};

export default async function Page({
  searchParams,
}: {
  searchParams: Promise<{ muscle?: string }>;
}) {
  const { muscle } = await searchParams;
  const exercises = await getExercises();

  return (
    <Section>
      <h1 className="text-3xl font-extrabold tracking-tight text-white sm:text-4xl">
        Exercise Library
      </h1>
      <p className="mt-3 max-w-2xl text-white/65">
        Every exercise in FitYaar — the muscles it works, the equipment you need
        and how it&apos;s tracked. Filter by muscle or equipment to plan your
        next session.
      </p>

      <div className="mt-8">
        {exercises.length === 0 ? (
          <div className="glass p-8 text-center text-white/60">
            The library is warming up — please check back shortly.
          </div>
        ) : (
          <ExerciseBrowser exercises={exercises} initialMuscle={muscle ?? ""} />
        )}
      </div>
    </Section>
  );
}
