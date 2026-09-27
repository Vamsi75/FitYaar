import type { Metadata } from "next";
import CalcPage from "@/components/calculators/CalcPage";
import IdealWeightCalculator from "@/components/calculators/IdealWeightCalculator";

export const metadata: Metadata = {
  title: "Ideal Weight Calculator",
  description:
    "Find a healthy weight range for your height using the Devine, Robinson and Hamwi formulas — and why it's a range, not a single number.",
  alternates: { canonical: "/calculators/ideal-weight" },
};

export default function Page() {
  return (
    <CalcPage
      title="Ideal Weight Calculator"
      intro="A healthy-weight range for your height, from three classic clinical formulas."
      ctaLine="Bodyweight is one signal. Track it alongside your lifts and measurements in FitYaar for the full picture."
      explainer={
        <>
          <h2>Three formulas, one range</h2>
          <p>
            The Devine, Robinson and Hamwi equations each estimate a healthy
            weight from height and sex. They disagree slightly, so we show the
            span between them as a range rather than pretending there&apos;s one
            perfect number.
          </p>
          <h2>Big caveat: muscle</h2>
          <p>
            These formulas don&apos;t know your body composition. A trained,
            muscular person can sit above their &quot;ideal&quot; weight and be
            perfectly healthy. Pair this with the{" "}
            <a className="text-brand-light underline" href="/calculators/body-fat">
              body-fat
            </a>{" "}
            and{" "}
            <a className="text-brand-light underline" href="/calculators/bmi">
              BMI
            </a>{" "}
            tools for context.
          </p>
        </>
      }
    >
      <IdealWeightCalculator />
    </CalcPage>
  );
}
