"use client";

import { useState } from "react";
import { bmrMifflin, round, type Sex } from "@/lib/calc/formulas";
import { NumberField, ResultBig, Segmented } from "./ui";

export default function BmrCalculator() {
  const [sex, setSex] = useState<Sex>("male");
  const [age, setAge] = useState<number | "">(28);
  const [weight, setWeight] = useState<number | "">(70);
  const [height, setHeight] = useState<number | "">(170);

  const valid =
    typeof age === "number" &&
    typeof weight === "number" &&
    typeof height === "number" &&
    age > 0 &&
    weight > 0 &&
    height > 0;
  const value = valid ? bmrMifflin(sex, weight, height, age) : 0;

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
          value={round(value).toString()}
          unit="kcal/day"
          caption="Calories burned at complete rest"
        />
      ) : (
        <ResultBig value="—" caption="Enter your details" />
      )}
    </div>
  );
}
