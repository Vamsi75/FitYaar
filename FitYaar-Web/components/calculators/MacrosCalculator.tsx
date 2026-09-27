"use client";

import { useState } from "react";
import {
  PROTEIN_GOALS,
  macros,
  round,
  type ProteinGoalKey,
} from "@/lib/calc/formulas";
import { NumberField, Segmented } from "./ui";

export default function MacrosCalculator() {
  const [calories, setCalories] = useState<number | "">(2200);
  const [weight, setWeight] = useState<number | "">(70);
  const [goal, setGoal] = useState<ProteinGoalKey>("muscle");

  const valid =
    typeof calories === "number" &&
    typeof weight === "number" &&
    calories > 0 &&
    weight > 0;
  const gPerKg = PROTEIN_GOALS.find((g) => g.key === goal)!.gPerKg;
  const m = valid ? macros(calories, weight, gPerKg) : null;

  return (
    <div className="space-y-5">
      <div className="glass grid gap-4 p-5 sm:grid-cols-2">
        <NumberField
          label="Daily calories"
          value={calories}
          onChange={setCalories}
          suffix="kcal"
          min={800}
        />
        <NumberField label="Body weight" value={weight} onChange={setWeight} suffix="kg" min={20} />
        <div className="sm:col-span-2">
          <Segmented<ProteinGoalKey>
            label="Goal"
            value={goal}
            onChange={setGoal}
            options={PROTEIN_GOALS.map((g) => ({ key: g.key, label: g.label }))}
          />
        </div>
      </div>

      <div className="grid grid-cols-3 gap-3">
        <MacroCard label="Protein" grams={m ? m.proteinG : null} tint="text-brand-light" />
        <MacroCard label="Carbs" grams={m ? m.carbG : null} tint="text-status-live" />
        <MacroCard label="Fat" grams={m ? m.fatG : null} tint="text-brand-gold" />
      </div>
    </div>
  );
}

function MacroCard({
  label,
  grams,
  tint,
}: {
  label: string;
  grams: number | null;
  tint: string;
}) {
  return (
    <div className="glass p-5 text-center">
      <div className="text-xs font-semibold uppercase tracking-wide text-white/55">
        {label}
      </div>
      <div className={`mt-1 text-2xl font-extrabold ${tint}`}>
        {grams === null ? "—" : round(grams)}
        {grams !== null && <span className="text-base text-white/50"> g</span>}
      </div>
    </div>
  );
}
