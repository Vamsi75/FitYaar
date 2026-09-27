"use client";

import { useState } from "react";
import { plateLoad, round } from "@/lib/calc/formulas";
import { NumberField } from "./ui";

const BARS = [20, 15, 10];

export default function PlateCalculator() {
  const [target, setTarget] = useState<number | "">(100);
  const [bar, setBar] = useState<number>(20);

  const valid = typeof target === "number" && target >= bar;
  const load = valid ? plateLoad(target, bar) : null;

  return (
    <div className="grid gap-5 sm:grid-cols-2">
      <div className="glass space-y-4 p-5">
        <NumberField
          label="Target total"
          value={target}
          onChange={setTarget}
          suffix="kg"
          min={bar}
        />
        <label className="block">
          <span className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-white/55">
            Bar weight
          </span>
          <div className="grid grid-cols-3 gap-2">
            {BARS.map((b) => (
              <button
                key={b}
                type="button"
                onClick={() => setBar(b)}
                className={`rounded-pill border px-3 py-2 text-sm transition ${
                  bar === b
                    ? "border-brand-orange/60 bg-brand-orange/20 text-brand-light"
                    : "border-white/12 bg-white/5 text-white/70 hover:bg-white/10"
                }`}
              >
                {b} kg
              </button>
            ))}
          </div>
        </label>
      </div>

      <div className="glass flex flex-col justify-center p-5">
        {!load ? (
          <p className="text-center text-white/50">
            Target must be at least the bar weight.
          </p>
        ) : load.perSide.length === 0 ? (
          <p className="text-center text-white/60">Just the empty bar.</p>
        ) : (
          <>
            <p className="mb-3 text-center text-xs font-semibold uppercase tracking-wide text-white/55">
              Load per side
            </p>
            <div className="flex flex-wrap justify-center gap-2">
              {load.perSide.map((p) => (
                <span
                  key={p.plate}
                  className="rounded-pill border border-brand-orange/50 bg-brand-orange/20 px-3 py-1.5 text-sm font-semibold text-brand-light"
                >
                  {p.count} × {p.plate} kg
                </span>
              ))}
            </div>
            {load.leftover > 0.01 && (
              <p className="mt-3 text-center text-xs text-status-amber">
                Closest loadable: {round(load.loadable, 2)} kg (short by{" "}
                {round(load.leftover, 2)} kg)
              </p>
            )}
          </>
        )}
      </div>
    </div>
  );
}
