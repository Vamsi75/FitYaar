import {
  MALE_FRONT,
  MALE_BACK,
  FEMALE_FRONT,
  FEMALE_BACK,
  VIEWBOX,
} from "./paths.generated";

export type Sex = "male" | "female";

/** Backend Exercise.MuscleGroup (20 values) → body-path slug. */
export const MUSCLE_GROUP_TO_SLUG: Record<string, string> = {
  UPPER_CHEST: "chest",
  CHEST: "chest",
  LOWER_CHEST: "chest",
  FRONT_DELTS: "deltoids",
  SIDE_DELTS: "deltoids",
  REAR_DELTS: "deltoids",
  BICEPS: "biceps",
  TRICEPS: "triceps",
  FOREARMS: "forearm",
  LATS: "upper-back",
  UPPER_BACK: "upper-back",
  TRAPS: "trapezius",
  LOWER_BACK: "lower-back",
  ABS: "abs",
  OBLIQUES: "obliques",
  QUADRICEPS: "quadriceps",
  HAMSTRINGS: "hamstring",
  GLUTES: "gluteal",
  CALVES: "calves",
  NECK: "neck",
};

export interface Figure {
  paths: Record<string, string[]>;
  viewBox: [number, number, number, number];
}

export function figures(sex: Sex): { front: Figure; back: Figure } {
  if (sex === "female") {
    return {
      front: { paths: FEMALE_FRONT, viewBox: VIEWBOX.femaleFront },
      back: { paths: FEMALE_BACK, viewBox: VIEWBOX.femaleBack },
    };
  }
  return {
    front: { paths: MALE_FRONT, viewBox: VIEWBOX.maleFront },
    back: { paths: MALE_BACK, viewBox: VIEWBOX.maleBack },
  };
}

/** slug → intensity (0..1). Primary muscles = 1, secondary = 0.5. */
export function intensityBySlug(
  primary: string[],
  secondary: string[],
): Record<string, number> {
  const out: Record<string, number> = {};
  for (const m of secondary) {
    const slug = MUSCLE_GROUP_TO_SLUG[m];
    if (slug) out[slug] = Math.max(out[slug] ?? 0, 0.5);
  }
  for (const m of primary) {
    const slug = MUSCLE_GROUP_TO_SLUG[m];
    if (slug) out[slug] = 1;
  }
  return out;
}
