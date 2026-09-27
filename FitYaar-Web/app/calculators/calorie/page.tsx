import type { Metadata } from "next";
import CalcPage from "@/components/calculators/CalcPage";
import CalorieCalculator from "@/components/calculators/CalorieCalculator";

export const metadata: Metadata = {
  title: "Calorie Calculator — Daily Calorie Target",
  description:
    "Work out how many calories to eat per day to lose fat, maintain or build muscle — based on your BMR, activity and goal.",
  alternates: { canonical: "/calculators/calorie" },
};

export default function Page() {
  return (
    <CalcPage
      title="Calorie Calculator"
      intro="How many calories should you eat? Enter your details and goal to get a daily target built from your maintenance calories."
      ctaLine="A target is only useful if you hit it. Log your meals in FitYaar's India-first food diary and adjust from real data."
      explainer={
        <>
          <h2>How your target is built</h2>
          <p>
            We estimate your maintenance calories (BMR × activity) and then apply
            a goal adjustment: about <strong>−500 kcal</strong> for fat loss
            (~0.5 kg/week) or a modest <strong>+300 kcal</strong> for lean
            muscle gain.
          </p>
          <h2>Make it work</h2>
          <ul>
            <li>Keep protein high in a deficit to hold onto muscle.</li>
            <li>
              Weigh yourself over 1–2 weeks — if the trend isn&apos;t moving as
              expected, adjust by ~150–200 kcal.
            </li>
            <li>Activity multipliers are the biggest source of error.</li>
          </ul>
        </>
      }
    >
      <CalorieCalculator />
    </CalcPage>
  );
}
