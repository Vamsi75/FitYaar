import Link from "next/link";
import Wordmark from "./Wordmark";

const cols: { title: string; links: { label: string; href: string }[] }[] = [
  {
    title: "Tools",
    links: [
      { label: "TDEE Calculator", href: "/calculators/tdee" },
      { label: "Calorie Calculator", href: "/calculators/calorie" },
      { label: "Macro Calculator", href: "/calculators/macros" },
      { label: "Body Fat Calculator", href: "/calculators/body-fat" },
    ],
  },
  {
    title: "Explore",
    links: [
      { label: "All calculators", href: "/calculators" },
      { label: "Exercise library", href: "/exercises" },
      { label: "Blog", href: "/blog" },
      { label: "For gyms", href: "/fityaar-for-gyms" },
    ],
  },
  {
    title: "FitYaar",
    links: [
      { label: "About", href: "/about" },
      { label: "Log in", href: "/login" },
      { label: "Create account", href: "/register" },
    ],
  },
];

export default function Footer() {
  return (
    <footer className="mt-8 border-t border-white/10">
      <div className="section grid gap-8 py-10 sm:grid-cols-2 lg:grid-cols-[1.6fr_1fr_1fr_1fr]">
        <div>
          <Wordmark />
          <p className="mt-3 max-w-xs text-sm text-white/60">
            Better you, together. Train, track, eat and understand your body —
            powered by the FitYaar app.
          </p>
        </div>
        {cols.map((col) => (
          <div key={col.title}>
            <h4 className="text-xs font-semibold uppercase tracking-wider text-white/50">
              {col.title}
            </h4>
            <ul className="mt-3 space-y-2">
              {col.links.map((l) => (
                <li key={l.href}>
                  <Link
                    href={l.href}
                    className="text-sm text-white/70 transition hover:text-white"
                  >
                    {l.label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>
        ))}
      </div>
      <div className="section pb-8 text-xs text-white/40">
        <p>© {new Date().getFullYear()} FitYaar. All rights reserved.</p>
        <p className="mt-1 text-white/30">
          Muscle map based on react-native-body-highlighter (MIT, © 2022 ELABBASSI
          Hicham). Exercise data from free-exercise-db (public domain).
        </p>
      </div>
    </footer>
  );
}
