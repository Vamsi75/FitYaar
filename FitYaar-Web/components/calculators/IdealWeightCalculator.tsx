"use client";

import { useState } from "react";
import { idealWeight, round, type Sex } from "@/lib/calc/formulas";
import { NumberField, ResultBig, Segmented } from "./ui";

export default function IdealWeightCalculator() {
  const [sex, setSex] = useState<Sex>("male");
  const [height, setHeight] = useState<number | "">(170);

  const valid = typeof height === "number" && height > 120;
  const w = valid ? idealWeight(sex, height) : null;
  const sorted = w ? [w.robinson, w.devine, w.hamwi].sort((a, b) => a - b) : null;

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
        <NumberField label="Height" value={height} onChange={setHeight} suffix="cm" min={120} />
        {w && (
          <div className="space-y-1 pt-1 text-sm text-white/60">
            <Row label="Devine" value={w.devine} />
            <Row label="Robinson" value={w.robinson} />
            <Row label="Hamwi" value={w.hamwi} />
          </div>
        )}
      </div>
      {sorted ? (
        <ResultBig
          value={`${round(sorted[0])}–${round(sorted[2])}`}
          unit="kg"
          caption="Healthy weight range"
        />
      ) : (
        <ResultBig value="—" caption="Enter your height" />
      )}
    </div>
  );
}

function Row({ label, value }: { label: string; value: number }) {
  return (
    <div className="flex justify-between">
      <span>{label} formula</span>
      <span className="font-semibold text-white/80">{round(value, 1)} kg</span>
    </div>
  );
}
