"use client";

import { useState } from "react";
import {
  PROTEIN_GOALS,
  proteinGrams,
  round,
  type ProteinGoalKey,
} from "@/lib/calc/formulas";
import { NumberField, ResultBig, Segmented } from "./ui";

export default function ProteinCalculator() {
  const [weight, setWeight] = useState<number | "">(70);
  const [goal, setGoal] = useState<ProteinGoalKey>("muscle");

  const valid = typeof weight === "number" && weight > 0;
  const gPerKg = PROTEIN_GOALS.find((g) => g.key === goal)!.gPerKg;
  const grams = valid ? proteinGrams(weight, gPerKg) : 0;

  return (
    <div className="grid gap-5 sm:grid-cols-2">
      <div className="glass space-y-4 p-5">
        <NumberField
          label="Body weight"
          value={weight}
          onChange={setWeight}
          suffix="kg"
          min={20}
        />
        <Segmented<ProteinGoalKey>
          label="Goal"
          value={goal}
          onChange={setGoal}
          options={PROTEIN_GOALS.map((g) => ({ key: g.key, label: g.label }))}
        />
      </div>
      {valid ? (
        <ResultBig
          value={round(grams).toString()}
          unit="g/day"
          caption={`${gPerKg} g per kg of body weight`}
        />
      ) : (
        <ResultBig value="—" caption="Enter your weight" />
      )}
    </div>
  );
}
