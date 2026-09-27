import type { Metadata } from "next";
import CalcPage from "@/components/calculators/CalcPage";
import BmiCalculator from "@/components/calculators/BmiCalculator";

export const metadata: Metadata = {
  title: "BMI Calculator — Body Mass Index",
  description:
    "Free BMI calculator. Enter your height and weight to find your Body Mass Index and category, plus what BMI does and doesn't tell you.",
  alternates: { canonical: "/calculators/bmi" },
};

export default function Page() {
  return (
    <CalcPage
      title="BMI Calculator"
      intro="Body Mass Index is a quick screen that relates your weight to your height. Enter your numbers to see your BMI and category."
      ctaLine="BMI can't see muscle. Track your weight, waist and lifts in FitYaar for a picture that actually reflects your training."
      explainer={
        <>
          <h2>How BMI is calculated</h2>
          <p>
            BMI is your weight in kilograms divided by your height in metres
            squared (kg/m²). The standard categories are: under 18.5
            underweight, 18.5–24.9 healthy, 25–29.9 overweight, and 30+ obese.
          </p>
          <h2>What BMI doesn&apos;t tell you</h2>
          <p>
            BMI knows nothing about body composition. A muscular lifter and an
            untrained person of the same height and weight get the same BMI,
            even though their bodies are very different. It also doesn&apos;t
            account for where you carry fat.
          </p>
          <ul>
            <li>Treat it as one rough signal, not a verdict.</li>
            <li>
              Waist measurement and body-fat percentage tell you more about
              health.
            </li>
            <li>Trends over time matter more than a single reading.</li>
          </ul>
        </>
      }
    >
      <BmiCalculator />
    </CalcPage>
  );
}
