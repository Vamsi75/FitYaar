import type { Metadata } from "next";
import CalcPage from "@/components/calculators/CalcPage";
import WaterCalculator from "@/components/calculators/WaterCalculator";

export const metadata: Metadata = {
  title: "Water Intake Calculator — Daily Hydration",
  description:
    "Estimate how much water to drink per day from your body weight and exercise — plus how the number changes in heat and training.",
  alternates: { canonical: "/calculators/water" },
};

export default function Page() {
  return (
    <CalcPage
      title="Water Intake Calculator"
      intro="A daily water target based on your body weight and how much you train today."
      ctaLine="FitYaar logs your water alongside food and workouts, so hydration is one less thing to track separately."
      explainer={
        <>
          <h2>How it&apos;s estimated</h2>
          <p>
            A common guideline is about <strong>33 ml per kg</strong> of body
            weight, plus roughly <strong>350 ml for every 30 minutes</strong> of
            exercise to replace what you sweat out.
          </p>
          <h2>Adjust for conditions</h2>
          <ul>
            <li>Hot, humid Indian summers mean you&apos;ll need more.</li>
            <li>Food (fruit, dal, curd, chai) also contributes fluid.</li>
            <li>
              Pale-yellow urine is a simple, reliable signal you&apos;re on track.
            </li>
          </ul>
        </>
      }
    >
      <WaterCalculator />
    </CalcPage>
  );
}
