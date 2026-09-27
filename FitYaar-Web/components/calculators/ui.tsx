import type { Tone } from "@/lib/calc/formulas";

const toneClass: Record<Tone, string> = {
  live: "text-status-live",
  amber: "text-status-amber",
  red: "text-status-red",
};

export function NumberField({
  label,
  value,
  onChange,
  suffix,
  min,
  max,
  step,
}: {
  label: string;
  value: number | "";
  onChange: (v: number | "") => void;
  suffix?: string;
  min?: number;
  max?: number;
  step?: number;
}) {
  return (
    <label className="block">
      <span className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-white/55">
        {label}
      </span>
      <div className="relative">
        <input
          type="number"
          inputMode="decimal"
          className="field pr-12"
          value={value}
          min={min}
          max={max}
          step={step}
          onChange={(e) =>
            onChange(e.target.value === "" ? "" : Number(e.target.value))
          }
        />
        {suffix && (
          <span className="pointer-events-none absolute right-4 top-1/2 -translate-y-1/2 text-sm text-white/40">
            {suffix}
          </span>
        )}
      </div>
    </label>
  );
}

export function Segmented<T extends string>({
  label,
  value,
  options,
  onChange,
}: {
  label: string;
  value: T;
  options: { key: T; label: string }[];
  onChange: (v: T) => void;
}) {
  return (
    <div>
      <span className="mb-1.5 block text-xs font-semibold uppercase tracking-wide text-white/55">
        {label}
      </span>
      <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
        {options.map((o) => {
          const active = o.key === value;
          return (
            <button
              key={o.key}
              type="button"
              onClick={() => onChange(o.key)}
              className={`rounded-pill border px-3 py-2 text-sm transition ${
                active
                  ? "border-brand-orange/60 bg-brand-orange/20 text-brand-light"
                  : "border-white/12 bg-white/5 text-white/70 hover:bg-white/10"
              }`}
            >
              {o.label}
            </button>
          );
        })}
      </div>
    </div>
  );
}

export function ResultBig({
  value,
  unit,
  caption,
  tone,
}: {
  value: string;
  unit?: string;
  caption?: string;
  tone?: Tone;
}) {
  return (
    <div className="glass flex flex-col items-center justify-center p-6 text-center">
      <div className="flex items-baseline gap-1">
        <span className="text-4xl font-extrabold text-white sm:text-5xl">
          {value}
        </span>
        {unit && <span className="text-lg text-white/60">{unit}</span>}
      </div>
      {caption && (
        <span
          className={`mt-2 text-sm font-semibold ${tone ? toneClass[tone] : "text-white/70"}`}
        >
          {caption}
        </span>
      )}
    </div>
  );
}
