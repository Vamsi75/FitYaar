import {
  figures,
  intensityBySlug,
  type Figure,
  type Sex,
} from "@/lib/body/muscle-map";

/**
 * Server-rendered muscle heatmap (front + back silhouette) — worked muscles glow
 * orange by intensity. SVG lands in the SSR HTML (good for SEO, no client JS from
 * the 94 KB path data). Muscle paths © react-native-body-highlighter (MIT).
 */
export default function MuscleMap({
  primaryMuscles,
  secondaryMuscles,
  sex = "male",
}: {
  primaryMuscles: string[];
  secondaryMuscles: string[];
  sex?: Sex;
}) {
  const intensity = intensityBySlug(primaryMuscles, secondaryMuscles);
  const { front, back } = figures(sex);
  return (
    <div className="grid grid-cols-2 gap-3">
      <FigureSvg figure={front} intensity={intensity} label="Front" />
      <FigureSvg figure={back} intensity={intensity} label="Back" />
    </div>
  );
}

function FigureSvg({
  figure,
  intensity,
  label,
}: {
  figure: Figure;
  intensity: Record<string, number>;
  label: string;
}) {
  const [minX, minY, w, h] = figure.viewBox;
  return (
    <figure>
      <svg
        viewBox={`${minX} ${minY} ${w} ${h}`}
        role="img"
        aria-label={`Muscles worked — ${label.toLowerCase()} view`}
        className="mx-auto h-auto w-full max-h-[340px]"
      >
        {Object.entries(figure.paths).map(([slug, paths]) => {
          const t = intensity[slug] ?? 0;
          const worked = t > 0;
          const fill = worked ? "#FF6F00" : "#FFFFFF";
          // Mirror the app: 0.28 + 0.62·t for worked muscles, faint white otherwise.
          const opacity = worked
            ? Math.round((0.28 + 0.62 * t) * 100) / 100
            : 0.06;
          return paths.map((d, i) => (
            <path key={`${slug}-${i}`} d={d} fill={fill} fillOpacity={opacity} />
          ));
        })}
      </svg>
      <figcaption className="mt-1 text-center text-xs text-white/40">
        {label}
      </figcaption>
    </figure>
  );
}
