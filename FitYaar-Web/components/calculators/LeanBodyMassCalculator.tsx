"use client";

import { useState } from "react";
import { leanBodyMassBoer, round, type Sex } from "@/lib/calc/formulas";
import { NumberField, ResultBig, Segmented } from "./ui";

export default function LeanBodyMassCalculator() {
  const [sex, setSex] = useState<Sex>("male");
  const [weight, setWeight] = useState<number | "">(70);
  const [height, setHeight] = useState<number | "">(170);

  const valid =
    typeof weight === "number" &&
    typeof height === "number" &&
    weight > 0 &&
    height > 0;
  const lbm = valid ? leanBodyMassBoer(sex, weight, height) : 0;
  const ok = valid && lbm > 0;
  const fatMass = ok ? Number(weight) - lbm : 0;

  return (
    <div className="grid gap-5 sm:grid-cols-2">
      <div className="glass space-y-4 p-5">
        <Segmented<Sex>
          label="Sex"
          value={sex}
          onChange={setSex}
          options={[
            { key: "male", label: "Male" },
            { key: "female", label: "Female" },
          ]}
        />
        <div className="grid grid-cols-2 gap-4">
          <NumberField label="Weight" value={weight} onChange={setWeight} suffix="kg" min={20} />
          <NumberField label="Height" value={height} onChange={setHeight} suffix="cm" min={80} />
        </div>
      </div>
      {ok ? (
        <ResultBig
          value={round(lbm, 1).toString()}
          unit="kg"
          caption={`Fat mass ≈ ${round(fatMass, 1)} kg`}
        />
      ) : (
        <ResultBig value="—" caption="Enter your details" />
      )}
    </div>
  );
}
