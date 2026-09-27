"use client";

import { useMemo, useState } from "react";
import Link from "next/link";
import type { ExerciseSummary } from "@/lib/exercises";
import { humanize, sortMuscles } from "@/lib/muscles";

export default function ExerciseBrowser({
  exercises,
  initialMuscle = "",
}: {
  exercises: ExerciseSummary[];
  initialMuscle?: string;
}) {
  const [query, setQuery] = useState("");
  const [muscle, setMuscle] = useState(initialMuscle.toUpperCase());
  const [equipment, setEquipment] = useState("");

  const muscleOptions = useMemo(
    () =>
      sortMuscles([
        ...new Set(exercises.flatMap((e) => e.primaryMuscles)),
      ]),
    [exercises],
  );
  const equipmentOptions = useMemo(
    () =>
      [...new Set(exercises.map((e) => e.equipment).filter(Boolean))].sort() as string[],
    [exercises],
  );

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return exercises.filter(
      (e) =>
        (!q || e.name.toLowerCase().includes(q)) &&
        (!muscle || e.primaryMuscles.includes(muscle)) &&
        (!equipment || e.equipment === equipment),
    );
  }, [exercises, query, muscle, equipment]);

  return (
    <div>
      <input
        type="search"
        placeholder="Search exercises…"
        className="field mb-5"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
      />

      <FilterRow label="Muscle">
        <Chip active={!muscle} onClick={() => setMuscle("")}>
          All
        </Chip>
        {muscleOptions.map((m) => (
          <Chip key={m} active={muscle === m} onClick={() => setMuscle(m)}>
            {humanize(m)}
          </Chip>
        ))}
      </FilterRow>

      <FilterRow label="Equipment">
        <Chip active={!equipment} onClick={() => setEquipment("")}>
          All
        </Chip>
        {equipmentOptions.map((eq) => (
          <Chip
            key={eq}
            active={equipment === eq}
            onClick={() => setEquipment(eq)}
          >
            {humanize(eq)}
          </Chip>
        ))}
      </FilterRow>

      <p className="mt-6 text-sm text-white/45">
        {filtered.length} exercise{filtered.length === 1 ? "" : "s"}
      </p>

      <div className="mt-3 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {filtered.map((e) => (
          <Link
            key={e.slug}
            href={`/exercises/${e.slug}`}
            className="glass p-4 transition hover:border-brand-orange/40 hover:bg-white/[0.08]"
          >
            <h3 className="font-semibold text-white">{e.name}</h3>
            <p className="mt-1 text-sm text-brand-light/90">
              {e.primaryMuscles.map(humanize).join(" · ") || "—"}
            </p>
            <p className="mt-0.5 text-xs text-white/45">
              {humanize(e.equipment)}
            </p>
          </Link>
        ))}
      </div>

      {filtered.length === 0 && (
        <p className="mt-10 text-center text-white/50">
          No exercises match — try clearing a filter.
        </p>
      )}
    </div>
  );
}

function FilterRow({
  label,
  children,
}: {
  label: string;
  children: React.ReactNode;
}) {
  return (
    <div className="mt-4">
      <span className="mb-2 block text-xs font-semibold uppercase tracking-wide text-white/45">
        {label}
      </span>
      <div className="flex flex-wrap gap-2">{children}</div>
    </div>
  );
}

function Chip({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`rounded-pill border px-3 py-1.5 text-sm transition ${
        active
          ? "border-brand-orange/60 bg-brand-orange/20 text-brand-light"
          : "border-white/12 bg-white/5 text-white/70 hover:bg-white/10"
      }`}
    >
      {children}
    </button>
  );
}
