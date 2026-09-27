// One-off: transform the app's Dart muscle-path data into a TS module for the web.
// Dart map literals → TS object literals is a near-identical syntax swap.
// Run: node scripts/port-body-paths.mjs
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname } from "node:path";

const DART =
  "D:/FitYaar/FitYaar-Mobile/lib/features/insights/body_paths.dart";
const OUT = "D:/FitYaar/FitYaar-Web/lib/body/paths.generated.ts";

const src = readFileSync(DART, "utf8");

// Keep everything from the first data map onward (drops the comment header + class).
const start = src.indexOf("const Map<String, List<String>> maleFront");
if (start === -1) throw new Error("maleFront map not found");
let body = src.slice(start);

body = body
  .replace(
    /const Map<String, List<String>> maleFront =/,
    "export const MALE_FRONT: Record<string, string[]> =",
  )
  .replace(
    /const Map<String, List<String>> maleBack =/,
    "export const MALE_BACK: Record<string, string[]> =",
  )
  .replace(
    /const Map<String, List<String>> femaleFront =/,
    "export const FEMALE_FRONT: Record<string, string[]> =",
  )
  .replace(
    /const Map<String, List<String>> femaleBack =/,
    "export const FEMALE_BACK: Record<string, string[]> =",
  )
  .replace(
    /const Map<String, BodyViewBox> bodyViewBox =/,
    "export const VIEWBOX: Record<string, [number, number, number, number]> =",
  )
  .replace(/BodyViewBox\(([^)]*)\)/g, "[$1]");

const header = `// GENERATED from FitYaar-Mobile/lib/features/insights/body_paths.dart — do not edit by hand.
// Muscle SVG paths from react-native-body-highlighter (MIT, (c) 2022 ELABBASSI Hicham).
// See ./LICENSE-body-highlighter.txt. Regenerate with scripts/port-body-paths.mjs.
/* eslint-disable */

`;

mkdirSync(dirname(OUT), { recursive: true });
writeFileSync(OUT, header + body, "utf8");

// Quick sanity: count top-level slug keys per map.
const count = (name) => {
  const m = body.match(
    new RegExp(`export const ${name}[\\s\\S]*?\\n\\};`, "m"),
  );
  return m ? (m[0].match(/^ {2}'[^']+':/gm) || []).length : "??";
};
console.log("MALE_FRONT slugs:", count("MALE_FRONT"));
console.log("MALE_BACK  slugs:", count("MALE_BACK"));
console.log("FEMALE_FRONT slugs:", count("FEMALE_FRONT"));
console.log("FEMALE_BACK slugs:", count("FEMALE_BACK"));
console.log("wrote", OUT, `(${(header + body).length} bytes)`);
