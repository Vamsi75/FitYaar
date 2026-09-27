"use client";

import { useState } from "react";
import { round, waterIntake } from "@/lib/calc/formulas";
import { NumberField, ResultBig } from "./ui";

export default function WaterCalculator() {
  const [weight, setWeight] = useState<number | "">(70);
  const [minutes, setMinutes] = useState<number | "">(30);

  const valid = typeof weight === "number" && weight > 0;
  const litres = valid ? waterIntake(weight, Number(minutes) || 0) : 0;
  const glasses = Math.round((litres * 1000) / 250);

  return (
    <div className="grid gap-5 sm:grid-cols-2">
      <div className="glass space-y-4 p-5">
        <NumberField label="Body weight" value={weight} onChange={setWeight} suffix="kg" min={20} />
        <NumberField
          label="Exercise today"
          value={minutes}
          onChange={setMinutes}
          suffix="min"
          min={0}
        />
      </div>
      {valid ? (
        <ResultBig
          value={round(litres, 1).toString()}
          unit="L/day"
          caption={`≈ ${glasses} glasses (250 ml)`}
        />
      ) : (
        <ResultBig value="—" caption="Enter your weight" />
      )}
    </div>
  );
}
