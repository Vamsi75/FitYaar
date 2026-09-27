/** Humanize a backend enum token: FRONT_DELTS → "Front Delts", NO_EQUIPMENT → "No Equipment". */
export function humanize(value?: string | null): string {
  if (!value) return "";
  return value
    .split("_")
    .map((w) => w.charAt(0) + w.slice(1).toLowerCase())
    .join(" ");
}

/** Display order for muscle filter chips (major groups first). Others append if present. */
export const MUSCLE_ORDER = [
  "CHEST",
  "LATS",
  "UPPER_BACK",
  "TRAPS",
  "SIDE_DELTS",
  "FRONT_DELTS",
  "REAR_DELTS",
  "BICEPS",
  "TRICEPS",
  "FOREARMS",
  "ABS",
  "OBLIQUES",
  "QUADRICEPS",
  "HAMSTRINGS",
  "GLUTES",
  "CALVES",
];

export function sortMuscles(muscles: string[]): string[] {
  return [...muscles].sort((a, b) => {
    const ia = MUSCLE_ORDER.indexOf(a);
    const ib = MUSCLE_ORDER.indexOf(b);
    if (ia === -1 && ib === -1) return a.localeCompare(b);
    if (ia === -1) return 1;
    if (ib === -1) return -1;
    return ia - ib;
  });
}
