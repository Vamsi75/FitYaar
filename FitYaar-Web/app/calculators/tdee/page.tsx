import type { Metadata } from "next";
import CalcPage from "@/components/calculators/CalcPage";
import TdeeCalculator from "@/components/calculators/TdeeCalculator";

export const metadata: Metadata = {
  title: "TDEE Calculator — Total Daily Energy Expenditure",
  description:
    "Free TDEE calculator. Estimate your maintenance calories from BMR and activity level, with fat-loss and lean-gain targets you can act on.",
  alternates: { canonical: "/calculators/tdee" },
};

export default function Page() {
  return (
    <CalcPage
      title="TDEE Calculator"
      intro="Total Daily Energy Expenditure is roughly how many calories you burn in a day. Match your intake to it to maintain, eat below it to lose fat, above it to gain."
      ctaLine="These targets only work if you actually hit them. Track your calories and protein in FitYaar and adjust from real data."
      explainer={
        <>
          <h2>How TDEE is estimated</h2>
          <p>
            We calculate your BMR (Mifflin-St Jeor) and multiply by an activity
            factor, from 1.2 (sedentary) to 1.9 (extra active). That gives your{" "}
            <strong>maintenance</strong> calories.
          </p>
          <h2>Turning it into a plan</h2>
          <ul>
            <li>
              <strong>Fat loss:</strong> about 500 kcal below maintenance ≈ ~0.5
              kg/week.
            </li>
            <li>
              <strong>Lean gain:</strong> a smaller ~300 kcal surplus keeps fat
              gain in check.
            </li>
            <li>Keep protein high in either case to protect muscle.</li>
          </ul>
          <p>
            Activity multipliers are the biggest source of error — most people
            overestimate. If the scale isn&apos;t moving as expected after 2–3
            weeks, trust the trend and adjust rather than the formula.
          </p>
        </>
      }
    >
      <TdeeCalculator />
    </CalcPage>
  );
}
