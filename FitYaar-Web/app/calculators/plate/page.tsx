import type { Metadata } from "next";
import CalcPage from "@/components/calculators/CalcPage";
import PlateCalculator from "@/components/calculators/PlateCalculator";

export const metadata: Metadata = {
  title: "Barbell Plate Calculator",
  description:
    "Work out exactly which plates to load on each side of the barbell for any target weight — standard kg plates.",
  alternates: { canonical: "/calculators/plate" },
};

export default function Page() {
  return (
    <CalcPage
      title="Plate Calculator"
      intro="Loading the bar for a big lift? Enter your target and bar weight to see the plates to put on each side."
      ctaLine="FitYaar remembers your working weights, so next time the bar's already figured out. Log a set to start."
      explainer={
        <>
          <h2>How it works</h2>
          <p>
            We subtract the bar weight, split the rest between the two sides, and
            load the heaviest plates first from a standard kg set (25, 20, 15, 10,
            5, 2.5, 1.25).
          </p>
          <h2>If it doesn&apos;t divide evenly</h2>
          <p>
            Some targets can&apos;t be matched exactly with standard plates —
            we&apos;ll show the closest loadable weight and how far short it is.
            Micro-plates (0.5 / 0.25 kg) help for small, steady progression.
          </p>
        </>
      }
    >
      <PlateCalculator />
    </CalcPage>
  );
}
