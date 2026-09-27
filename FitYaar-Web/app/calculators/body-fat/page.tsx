import type { Metadata } from "next";
import CalcPage from "@/components/calculators/CalcPage";
import BodyFatCalculator from "@/components/calculators/BodyFatCalculator";

export const metadata: Metadata = {
  title: "Body Fat Calculator — U.S. Navy Method",
  description:
    "Estimate your body-fat percentage from simple tape measurements using the U.S. Navy method — with what the number means and how accurate it is.",
  alternates: { canonical: "/calculators/body-fat" },
};

export default function Page() {
  return (
    <CalcPage
      title="Body Fat Calculator"
      intro="Estimate your body-fat percentage from a few tape measurements using the U.S. Navy method — no calipers or scales needed."
      ctaLine="Body-fat % moves slowly. Track your weight and waist in FitYaar to see the real trend over weeks, not days."
      explainer={
        <>
          <h2>How it works</h2>
          <p>
            The U.S. Navy method estimates body fat from your height, neck and
            waist (plus hips for women). Measure relaxed, at the widest point of
            the waist and the narrowest of the neck, in centimetres.
          </p>
          <h2>How accurate is it?</h2>
          <p>
            It&apos;s a solid estimate — typically within 3–4% of a DEXA scan for
            most people — but tape placement matters and it&apos;s less reliable
            at the extremes. Use the <strong>trend</strong> over time, measured
            the same way each time, rather than obsessing over a single number.
          </p>
        </>
      }
    >
      <BodyFatCalculator />
    </CalcPage>
  );
}
