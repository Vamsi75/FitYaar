export interface CalcMeta {
  slug: string;
  title: string;
  blurb: string;
  emoji: string;
}

/** Live calculators. Reused by the hub and the home "Popular Tools". */
export const CALCULATORS: CalcMeta[] = [
  {
    slug: "tdee",
    title: "TDEE Calculator",
    blurb: "Maintenance calories + fat-loss / lean-gain targets",
    emoji: "🔥",
  },
  {
    slug: "calorie",
    title: "Calorie Calculator",
    blurb: "Daily calorie target for your goal",
    emoji: "🍽️",
  },
  {
    slug: "macros",
    title: "Macro Calculator",
    blurb: "Protein, carbs and fat in grams",
    emoji: "🥘",
  },
  {
    slug: "protein",
    title: "Protein Calculator",
    blurb: "Daily protein for your goal, Indian-diet friendly",
    emoji: "🥚",
  },
  {
    slug: "body-fat",
    title: "Body Fat Calculator",
    blurb: "Estimate body-fat % (U.S. Navy method)",
    emoji: "📏",
  },
  {
    slug: "bmr",
    title: "BMR Calculator",
    blurb: "Calories your body burns at complete rest",
    emoji: "🛌",
  },
  {
    slug: "bmi",
    title: "BMI Calculator",
    blurb: "Body Mass Index and category",
    emoji: "⚖️",
  },
  {
    slug: "one-rep-max",
    title: "1RM Calculator",
    blurb: "One-rep max + training % table",
    emoji: "🏋️",
  },
  {
    slug: "ideal-weight",
    title: "Ideal Weight Calculator",
    blurb: "Healthy weight range for your height",
    emoji: "🎯",
  },
  {
    slug: "water",
    title: "Water Intake Calculator",
    blurb: "How much water to drink per day",
    emoji: "💧",
  },
  {
    slug: "lean-body-mass",
    title: "Lean Body Mass Calculator",
    blurb: "Estimate your fat-free mass (Boer)",
    emoji: "💪",
  },
  {
    slug: "plate",
    title: "Plate Calculator",
    blurb: "What plates to load on the barbell",
    emoji: "🔩",
  },
];

/** Still to come — kept short so the hub's "coming soon" row stays meaningful. */
export const CALCULATORS_SOON: string[] = ["Running Pace", "Calories Burned"];
