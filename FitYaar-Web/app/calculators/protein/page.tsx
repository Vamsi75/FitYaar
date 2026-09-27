import type { Metadata } from "next";
import CalcPage from "@/components/calculators/CalcPage";
import ProteinCalculator from "@/components/calculators/ProteinCalculator";

export const metadata: Metadata = {
  title: "Protein Calculator — Daily Protein Intake",
  description:
    "Free protein calculator. Find how much protein to eat per day for muscle gain, fat loss or general health — with practical Indian-friendly tips.",
  alternates: { canonical: "/calculators/protein" },
};

export default function Page() {
  return (
    <CalcPage
      title="Protein Calculator"
      intro="Protein builds and repairs muscle and keeps you full while dieting. Enter your weight and goal to get a daily target."
      ctaLine="Hitting protein daily is the hard part. FitYaar's India-first food log makes dal, paneer and curd add up without the guesswork."
      explainer={
        <>
          <h2>How much protein do you need?</h2>
          <p>
            For active people, research supports roughly 1.6–2.2 g of protein per
            kg of body weight per day:
          </p>
          <ul>
            <li>
              <strong>1.6 g/kg</strong> — general health and maintenance.
            </li>
            <li>
              <strong>2.0 g/kg</strong> — building muscle.
            </li>
            <li>
              <strong>2.2 g/kg</strong> — fat loss, to preserve muscle in a
              deficit.
            </li>
          </ul>
          <h2>Hitting it on an Indian diet</h2>
          <p>
            It&apos;s very doable: eggs, curd, paneer, dal, rajma, chole, soya,
            milk and whey stack up fast. Spread protein across 3–4 meals rather
            than one big hit for better use.
          </p>
          <p>
            Very high intakes are safe for healthy kidneys, but there&apos;s
            little extra benefit past ~2.2 g/kg — put the rest of your calories
            into carbs and fats to fuel training.
          </p>
        </>
      }
    >
      <ProteinCalculator />
    </CalcPage>
  );
}
