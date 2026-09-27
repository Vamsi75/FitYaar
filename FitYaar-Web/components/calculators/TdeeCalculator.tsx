"use client";

import { useState } from "react";
import {
  ACTIVITY,
  bmrMifflin,
  round,
  tdee,
  type ActivityKey,
  type Sex,
} from "@/lib/calc/formulas";
import { NumberField, ResultBig, Segmented } from "./ui";

export default function TdeeCalculator() {
  const [sex, setSex] = useState<Sex>("male");
  const [age, setAge] = useState<number | "">(28);
  const [weight, setWeight] = useState<number | "">(70);
  const [height, setHeight] = useState<number | "">(170);
  const [activity, setActivity] = useState<ActivityKey>("moderate");

  const valid =
    typeof age === "number" &&
    typeof weight === "number" &&
    typeof height === "number" &&
    age > 0 &&
    weight > 0 &&
    height > 0;

  const factor = ACTIVITY.find((a) => a.key === activity)!.factor;
  const maintenance = valid
    ? tdee(bmrMifflin(sex, weight, height, age), factor)
    : 0;

  return (
    <div className="space-y-5">
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
          <NumberField label="Age" value={age} onChange={setAge} suffix="yrs" min={10} />
          <div className="grid grid-cols-2 gap-4">
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
          <label className="block">
            <span className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-white/55">
              Activity level
            </span>
            <select
              className="field"
              value={activity}
              onChange={(e) => setActivity(e.target.value as ActivityKey)}
            >
              {ACTIVITY.map((a) => (
                <option key={a.key} value={a.key} className="bg-bg-mid">
                  {a.label}
                </option>
              ))}
            </select>
          </label>
        </div>

        {valid ? (
          <ResultBig
            value={round(maintenance).toLocaleString()}
            unit="kcal/day"
            caption="Maintenance calories"
          />
        ) : (
          <ResultBig value="—" caption="Enter your details" />
        )}
      </div>

      {valid && (
        <div className="grid grid-cols-3 gap-3">
          <Target label="Fat loss" value={round(maintenance - 500)} note="−500 kcal" />
          <Target label="Maintain" value={round(maintenance)} note="±0 kcal" />
          <Target label="Lean gain" value={round(maintenance + 300)} note="+300 kcal" />
        </div>
      )}
    </div>
  );
}

function Target({
  label,
  value,
  note,
}: {
  label: string;
  value: number;
  note: string;
}) {
  return (
    <div className="glass p-4 text-center">
      <div className="text-xs font-semibold uppercase tracking-wide text-white/55">
        {label}
      </div>
      <div className="mt-1 text-xl font-extrabold text-white">
        {value.toLocaleString()}
      </div>
      <div className="text-xs text-white/45">{note}</div>
    </div>
  );
}
