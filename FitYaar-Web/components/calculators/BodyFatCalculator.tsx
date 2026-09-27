"use client";

import { useState } from "react";
import {
  bodyFatCategory,
  bodyFatNavy,
  round,
  type Sex,
} from "@/lib/calc/formulas";
import { NumberField, ResultBig, Segmented } from "./ui";

export default function BodyFatCalculator() {
  const [sex, setSex] = useState<Sex>("male");
  const [height, setHeight] = useState<number | "">(170);
  const [neck, setNeck] = useState<number | "">(38);
  const [waist, setWaist] = useState<number | "">(85);
  const [hip, setHip] = useState<number | "">(95);

  const needHip = sex === "female";
  const nums = [height, neck, waist];
  const valid =
    nums.every((v) => typeof v === "number" && v > 0) &&
    (!needHip || (typeof hip === "number" && hip > 0));

  const bf = valid
    ? bodyFatNavy(sex, Number(height), Number(neck), Number(waist), Number(hip))
    : 0;
  const ok = valid && bf > 0 && Number.isFinite(bf);
  const cat = bodyFatCategory(sex, bf);

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
        <NumberField label="Height" value={height} onChange={setHeight} suffix="cm" min={80} />
        <div className="grid grid-cols-2 gap-4">
          <NumberField label="Neck" value={neck} onChange={setNeck} suffix="cm" min={20} />
          <NumberField label="Waist" value={waist} onChange={setWaist} suffix="cm" min={40} />
        </div>
        {needHip && (
          <NumberField label="Hip" value={hip} onChange={setHip} suffix="cm" min={50} />
        )}
      </div>
      {ok ? (
        <ResultBig
          value={round(bf, 1).toString()}
          unit="%"
          caption={cat.label}
          tone={cat.tone}
        />
      ) : (
        <ResultBig value="—" caption="Enter your measurements" />
      )}
    </div>
  );
}
