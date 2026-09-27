"use client";

import { useState } from "react";
import { ONE_RM_PERCENTS, oneRepMaxEpley, round } from "@/lib/calc/formulas";
import { NumberField, ResultBig } from "./ui";

export default function OneRepMaxCalculator() {
  const [weight, setWeight] = useState<number | "">(60);
  const [reps, setReps] = useState<number | "">(5);

  const valid =
    typeof weight === "number" &&
    typeof reps === "number" &&
    weight > 0 &&
    reps > 0 &&
    reps <= 15;
  const orm = valid ? oneRepMaxEpley(weight, reps) : 0;

  return (
    <div className="space-y-5">
      <div className="grid gap-5 sm:grid-cols-2">
        <div className="glass space-y-4 p-5">
          <NumberField
            label="Weight lifted"
            value={weight}
            onChange={setWeight}
            suffix="kg"
            min={1}
          />
          <NumberField
            label="Reps (1–15)"
            value={reps}
            onChange={setReps}
            suffix="reps"
            min={1}
            max={15}
          />
        </div>
        {valid ? (
          <ResultBig
            value={round(orm).toString()}
            unit="kg"
            caption="Estimated 1-rep max"
          />
        ) : (
          <ResultBig value="—" caption="Enter a set of 1–15 reps" />
        )}
      </div>

      {valid && (
        <div className="glass overflow-hidden p-0">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-white/10 text-white/55">
                <th className="px-4 py-2 text-left font-semibold">% of 1RM</th>
                <th className="px-4 py-2 text-right font-semibold">Weight</th>
                <th className="px-4 py-2 text-right font-semibold">≈ Reps</th>
              </tr>
            </thead>
            <tbody>
              {ONE_RM_PERCENTS.map((pct, i) => (
                <tr key={pct} className="border-b border-white/5 last:border-0">
                  <td className="px-4 py-2 text-white/80">{pct}%</td>
                  <td className="px-4 py-2 text-right font-semibold text-white">
                    {round((orm * pct) / 100 / 2.5) * 2.5} kg
                  </td>
                  <td className="px-4 py-2 text-right text-white/50">{i * 2 + 1}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
