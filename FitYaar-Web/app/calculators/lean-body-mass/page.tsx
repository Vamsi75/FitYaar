import type { Metadata } from "next";
import CalcPage from "@/components/calculators/CalcPage";
import LeanBodyMassCalculator from "@/components/calculators/LeanBodyMassCalculator";

export const metadata: Metadata = {
  title: "Lean Body Mass Calculator (Boer)",
  description:
    "Estimate your lean body mass — everything that isn't fat — using the Boer formula, and why it matters for training and nutrition.",
  alternates: { canonical: "/calculators/lean-body-mass" },
};

export default function Page() {
  return (
    <CalcPage
      title="Lean Body Mass Calculator"
      intro="Estimate your fat-free mass — muscle, bone, organs and water — from your weight and height."
      ctaLine="Losing fat while keeping lean mass is the goal. Track weight and measurements in FitYaar to protect your muscle."
      explainer={
        <>
          <h2>What lean body mass is</h2>
          <p>
            Lean body mass (LBM) is your total weight minus your fat mass. We
            estimate it with the <strong>Boer formula</strong>, which uses weight
            and height. Fat mass is simply your weight minus LBM.
          </p>
          <h2>Why it matters</h2>
          <p>
            When you diet, the aim is to lose fat while preserving LBM — that&apos;s
            what keeps you strong and keeps your metabolism up. Adequate protein
            and resistance training are the two levers that protect it. For a
            direct body-fat estimate, use the{" "}
            <a className="text-brand-light underline" href="/calculators/body-fat">
              body-fat calculator
            </a>
            .
          </p>
        </>
      }
    >
      <LeanBodyMassCalculator />
    </CalcPage>
  );
}
