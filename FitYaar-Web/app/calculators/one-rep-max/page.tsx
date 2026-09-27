import type { Metadata } from "next";
import CalcPage from "@/components/calculators/CalcPage";
import OneRepMaxCalculator from "@/components/calculators/OneRepMaxCalculator";

export const metadata: Metadata = {
  title: "1RM Calculator — One-Rep Max Estimator",
  description:
    "Estimate your one-rep max from a set you actually did, and get a full percentage-of-1RM table to program your training.",
  alternates: { canonical: "/calculators/one-rep-max" },
};

export default function Page() {
  return (
    <CalcPage
      title="1RM Calculator"
      intro="Estimate your one-rep max from any set of 1–15 reps — then use the percentage table to pick working weights."
      ctaLine="FitYaar tracks your estimated 1RM every session and flags new PRs automatically. Log a lift and watch it climb."
      explainer={
        <>
          <h2>How it&apos;s estimated</h2>
          <p>
            We use the Epley formula: <strong>1RM = weight × (1 + reps ⁄ 30)</strong>.
            It&apos;s most accurate at lower rep ranges (1–5) and drifts a little
            as reps get high, since endurance starts to matter more than strength.
          </p>
          <h2>Using the percentages</h2>
          <p>
            The table shows common training intensities. Working weights are
            rounded to the nearest 2.5 kg so they&apos;re actually loadable.
            Don&apos;t chase a true 1-rep max often — estimates from your normal
            working sets are safer and update every session.
          </p>
        </>
      }
    >
      <OneRepMaxCalculator />
    </CalcPage>
  );
}
