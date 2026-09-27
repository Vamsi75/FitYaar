import type { Metadata } from "next";
import CalcPage from "@/components/calculators/CalcPage";
import BmrCalculator from "@/components/calculators/BmrCalculator";

export const metadata: Metadata = {
  title: "BMR Calculator — Basal Metabolic Rate",
  description:
    "Free BMR calculator using the Mifflin-St Jeor equation. Estimate the calories your body burns at complete rest, and how to use that number.",
  alternates: { canonical: "/calculators/bmr" },
};

export default function Page() {
  return (
    <CalcPage
      title="BMR Calculator"
      intro="Your Basal Metabolic Rate is the energy your body uses just to stay alive at rest — breathing, circulation, keeping warm. It's the floor your daily calories are built on."
      ctaLine="Your BMR is the baseline. Log your food in FitYaar to see how your real intake compares."
      explainer={
        <>
          <h2>The Mifflin-St Jeor equation</h2>
          <p>
            We use Mifflin-St Jeor, the estimate most dietitians reach for
            today:
          </p>
          <ul>
            <li>
              <strong>Men:</strong> 10 × weight(kg) + 6.25 × height(cm) − 5 × age
              + 5
            </li>
            <li>
              <strong>Women:</strong> 10 × weight(kg) + 6.25 × height(cm) − 5 ×
              age − 161
            </li>
          </ul>
          <h2>BMR vs TDEE</h2>
          <p>
            BMR is calories at rest. Once you add daily movement and training you
            get your <strong>TDEE</strong> — the number that actually drives fat
            loss or gain. Use the{" "}
            <a className="text-brand-light underline" href="/calculators/tdee">
              TDEE calculator
            </a>{" "}
            for that.
          </p>
          <p>
            All formulas are population estimates — your true metabolism can vary
            by 5–10%. Track real intake and weight over a few weeks to dial it
            in.
          </p>
        </>
      }
    >
      <BmrCalculator />
    </CalcPage>
  );
}
