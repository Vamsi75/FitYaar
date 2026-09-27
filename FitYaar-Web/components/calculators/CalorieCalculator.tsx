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

const GOALS = [
  { key: "lose", label: "Lose fat", delta: -500 },
  { key: "maintain", label: "Maintain", delta: 0 },
  { key: "gain", label: "Build muscle", delta: 300 },
] as const;
type GoalKey = (typeof GOALS)[number]["key"];

export default function CalorieCalculator() {
  const [sex, setSex] = useState<Sex>("male");
  const [age, setAge] = useState<number | "">(28);
  const [weight, setWeight] = useState<number | "">(70);
  const [height, setHeight] = useState<number | "">(170);
  const [activity, setActivity] = useState<ActivityKey>("moderate");
  const [goal, setGoal] = useState<GoalKey>("lose");

  const valid =
    typeof age === "number" &&
    typeof weight === "number" &&
    typeof height === "number" &&
    age > 0 &&
    weight > 0 &&
    height > 0;

  const factor = ACTIVITY.find((a) => a.key === activity)!.factor;
  const delta = GOALS.find((g) => g.key === goal)!.delta;
  const maintenance = valid ? tdee(bmrMifflin(sex, weight, height, age), factor) : 0;
  const target = maintenance + delta;

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
        <NumberField label="Age" value={age} onChange={setAge} suffix="yrs" min={10} />
        <div className="grid grid-cols-2 gap-4">
          <NumberField label="Weight" value={weight} onChange={setWeight} suffix="kg" min={20} />
          <NumberField label="Height" value={height} onChange={setHeight} suffix="cm" min={80} />
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
        <Segmented<GoalKey>
          label="Goal"
          value={goal}
          onChange={setGoal}
          options={GOALS.map((g) => ({ key: g.key, label: g.label }))}
        />
      </div>
      {valid ? (
        <ResultBig
          value={round(target).toLocaleString()}
          unit="kcal/day"
          caption={`Maintenance ${round(maintenance).toLocaleString()} kcal`}
        />
      ) : (
        <ResultBig value="—" caption="Enter your details" />
      )}
    </div>
  );
}
