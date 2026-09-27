import { API_BASE } from "./api";

export interface ExerciseSummary {
  slug: string;
  name: string;
  primaryMuscles: string[];
  equipment: string | null;
  category: string | null;
}

export interface ExerciseDetail extends ExerciseSummary {
  description: string | null;
  secondaryMuscles: string[];
  exerciseType: string | null;
}

/**
 * Server-side fetches to the public exercise API. Resilient by design: on any
 * error they return empty/null so `next build` never depends on a running
 * backend (ISR fills pages in once the backend is reachable).
 */
export async function getExercises(): Promise<ExerciseSummary[]> {
  try {
    const res = await fetch(`${API_BASE}/api/public/exercises`, {
      next: { revalidate: 3600 },
    });
    if (!res.ok) return [];
    return (await res.json()) as ExerciseSummary[];
  } catch {
    return [];
  }
}

export async function getExercise(slug: string): Promise<ExerciseDetail | null> {
  try {
    const res = await fetch(
      `${API_BASE}/api/public/exercises/${encodeURIComponent(slug)}`,
      { next: { revalidate: 3600 } },
    );
    if (!res.ok) return null;
    return (await res.json()) as ExerciseDetail;
  } catch {
    return null;
  }
}
