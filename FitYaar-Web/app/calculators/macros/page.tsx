import type { Metadata } from "next";
import CalcPage from "@/components/calculators/CalcPage";
import MacrosCalculator from "@/components/calculators/MacrosCalculator";

export const metadata: Metadata = {
  title: "Macro Calculator — Protein, Carbs & Fat",
  description:
    "Split your daily calories into protein, carbs and fat in grams, based on your goal. Simple, evidence-based macro targets.",
  alternates: { canonical: "/calculators/macros" },
};

export default function Page() {
  return (
    <CalcPage
      title="Macro Calculator"
      intro="Turn a calorie target into daily grams of protein, carbs and fat. Set your calories and goal to get your split."
      ctaLine="Hitting macros daily is the hard part. FitYaar's food log adds up dal, paneer, curd and roti so you don't have to guess."
      explainer={
        <>
          <h2>How we split your macros</h2>
          <ul>
            <li>
              <strong>Protein</strong> is set from your body weight (1.6–2.2 g/kg
              depending on goal) — the anchor of the plan.
            </li>
            <li>
              <strong>Fat</strong> is set at ~25% of calories to support
              hormones.
            </li>
            <li>
              <strong>Carbs</strong> fill the remaining calories to fuel
              training.
            </li>
          </ul>
          <p>
            These are sensible defaults, not rules. Carbs and fats are flexible —
            shift them to fit your appetite and the foods you enjoy, as long as
            protein and total calories stay on target.
          </p>
        </>
      }
    >
      <MacrosCalculator />
    </CalcPage>
  );
}
