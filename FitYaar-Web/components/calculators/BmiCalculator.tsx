"use client";

import { useState } from "react";
import { bmi, bmiCategory, round } from "@/lib/calc/formulas";
import { NumberField, ResultBig } from "./ui";

export default function BmiCalculator() {
  const [weight, setWeight] = useState<number | "">(70);
  const [height, setHeight] = useState<number | "">(170);

  const valid =
    typeof weight === "number" &&
    typeof height === "number" &&
    weight > 0 &&
    height > 0;
  const value = valid ? bmi(weight, height) : 0;
  const cat = bmiCategory(value);

  return (
    <div className="grid gap-5 sm:grid-cols-2">
      <div className="glass space-y-4 p-5">
        <NumberField
          label="Weight"
          value={weight}
          onChange={setWeight}
          suffix="kg"
          min={20}
        />
        <NumberField
          label="Height"
          value={height}
          onChange={setHeight}
          suffix="cm"
          min={80}
        />
      </div>
      {valid ? (
        <ResultBig
          value={round(value, 1).toString()}
          caption={cat.label}
          tone={cat.tone}
        />
      ) : (
        <ResultBig value="—" caption="Enter your details" />
      )}
    </div>
  );
}
