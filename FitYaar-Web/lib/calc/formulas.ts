export type Sex = "male" | "female";
export type Tone = "live" | "amber" | "red";

/** Body Mass Index (kg/m²). */
export function bmi(weightKg: number, heightCm: number): number {
  const m = heightCm / 100;
  if (m <= 0) return 0;
  return weightKg / (m * m);
}

export function bmiCategory(value: number): { label: string; tone: Tone } {
  if (value < 18.5) return { label: "Underweight", tone: "amber" };
  if (value < 25) return { label: "Healthy weight", tone: "live" };
  if (value < 30) return { label: "Overweight", tone: "amber" };
  return { label: "Obese", tone: "red" };
}

/** Basal Metabolic Rate — Mifflin-St Jeor (the current standard estimate). */
export function bmrMifflin(
  sex: Sex,
  weightKg: number,
  heightCm: number,
  age: number,
): number {
  const base = 10 * weightKg + 6.25 * heightCm - 5 * age;
  return sex === "male" ? base + 5 : base - 161;
}

export const ACTIVITY = [
  { key: "sedentary", label: "Sedentary — little or no exercise", factor: 1.2 },
  { key: "light", label: "Lightly active — 1–3 days/week", factor: 1.375 },
  { key: "moderate", label: "Moderately active — 3–5 days/week", factor: 1.55 },
  { key: "active", label: "Very active — 6–7 days/week", factor: 1.725 },
  { key: "athlete", label: "Extra active — hard training / physical job", factor: 1.9 },
] as const;

export type ActivityKey = (typeof ACTIVITY)[number]["key"];

/** Total Daily Energy Expenditure. */
export function tdee(bmrValue: number, factor: number): number {
  return bmrValue * factor;
}

export const PROTEIN_GOALS = [
  { key: "maintain", label: "General health & maintenance", gPerKg: 1.6 },
  { key: "muscle", label: "Build muscle", gPerKg: 2.0 },
  { key: "cut", label: "Fat loss (preserve muscle)", gPerKg: 2.2 },
] as const;

export type ProteinGoalKey = (typeof PROTEIN_GOALS)[number]["key"];

export function proteinGrams(weightKg: number, gPerKg: number): number {
  return weightKg * gPerKg;
}

export function round(value: number, dp = 0): number {
  const f = 10 ** dp;
  return Math.round(value * f) / f;
}

// ── Body fat (U.S. Navy tape method) ─────────────────────────────────────────
/** Returns body-fat %. Measurements in cm. Hip is required for women, ignored for men. */
export function bodyFatNavy(
  sex: Sex,
  heightCm: number,
  neckCm: number,
  waistCm: number,
  hipCm = 0,
): number {
  if (sex === "male") {
    const d = waistCm - neckCm;
    if (d <= 0 || heightCm <= 0) return 0;
    return 495 / (1.0324 - 0.19077 * Math.log10(d) + 0.15456 * Math.log10(heightCm)) - 450;
  }
  const d = waistCm + hipCm - neckCm;
  if (d <= 0 || heightCm <= 0) return 0;
  return 495 / (1.29579 - 0.35004 * Math.log10(d) + 0.221 * Math.log10(heightCm)) - 450;
}

export function bodyFatCategory(sex: Sex, bf: number): { label: string; tone: Tone } {
  // Rough ACE ranges.
  const t = sex === "male"
    ? [{ max: 6, l: "Essential" }, { max: 14, l: "Athlete" }, { max: 18, l: "Fitness" }, { max: 25, l: "Average" }]
    : [{ max: 14, l: "Essential" }, { max: 21, l: "Athlete" }, { max: 25, l: "Fitness" }, { max: 32, l: "Average" }];
  for (const r of t) if (bf <= r.max) return { label: r.l, tone: r.l === "Average" ? "amber" : "live" };
  return { label: "Above average", tone: "amber" };
}

// ── Macros ───────────────────────────────────────────────────────────────────
export interface Macros {
  proteinG: number;
  fatG: number;
  carbG: number;
}
/** Split total daily calories into grams: protein from g/kg, fat at 25% of calories, carbs the remainder. */
export function macros(calories: number, weightKg: number, proteinPerKg: number): Macros {
  const proteinG = weightKg * proteinPerKg;
  const fatG = (calories * 0.25) / 9;
  const carbG = Math.max(0, (calories - proteinG * 4 - fatG * 9) / 4);
  return { proteinG, fatG, carbG };
}

// ── One-rep max (Epley) ──────────────────────────────────────────────────────
export function oneRepMaxEpley(weight: number, reps: number): number {
  if (reps <= 0) return 0;
  return reps === 1 ? weight : weight * (1 + reps / 30);
}
export const ONE_RM_PERCENTS = [100, 95, 90, 85, 80, 75, 70, 65, 60] as const;

// ── Ideal weight (kg) ────────────────────────────────────────────────────────
export interface IdealWeights {
  devine: number;
  robinson: number;
  hamwi: number;
}
export function idealWeight(sex: Sex, heightCm: number): IdealWeights {
  const over60 = Math.max(0, heightCm / 2.54 - 60); // inches over 5 ft
  return sex === "male"
    ? { devine: 50 + 2.3 * over60, robinson: 52 + 1.9 * over60, hamwi: 48 + 2.7 * over60 }
    : { devine: 45.5 + 2.3 * over60, robinson: 49 + 1.7 * over60, hamwi: 45.5 + 2.2 * over60 };
}

// ── Water intake (litres/day) ────────────────────────────────────────────────
export function waterIntake(weightKg: number, exerciseMinutes = 0): number {
  return weightKg * 0.033 + (exerciseMinutes / 30) * 0.35;
}

// ── Lean body mass (Boer, kg) ────────────────────────────────────────────────
export function leanBodyMassBoer(sex: Sex, weightKg: number, heightCm: number): number {
  return sex === "male"
    ? 0.407 * weightKg + 0.267 * heightCm - 19.2
    : 0.252 * weightKg + 0.473 * heightCm - 48.3;
}

// ── Barbell plate loading ────────────────────────────────────────────────────
export const PLATES_KG = [25, 20, 15, 10, 5, 2.5, 1.25] as const;
export interface PlateLoad {
  perSide: { plate: number; count: number }[];
  loadable: number; // total weight actually loaded (bar + plates)
  leftover: number; // weight that couldn't be matched with available plates
}
/** Greedily load plates per side for a target total, given the bar weight. */
export function plateLoad(target: number, bar: number): PlateLoad {
  const perSideWeight = Math.max(0, (target - bar) / 2);
  let remaining = perSideWeight;
  const perSide: { plate: number; count: number }[] = [];
  for (const p of PLATES_KG) {
    const count = Math.floor(remaining / p + 1e-9);
    if (count > 0) {
      perSide.push({ plate: p, count });
      remaining -= count * p;
    }
  }
  const loadedPerSide = perSideWeight - remaining;
  return {
    perSide,
    loadable: bar + loadedPerSide * 2,
    leftover: remaining * 2,
  };
}
