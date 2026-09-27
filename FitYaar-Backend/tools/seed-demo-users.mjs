// Seeds two demo users (male + female) with ~3 months of backdated workouts via the
// real API — so the muscle map, PRs and trends populate. Idempotent-ish: re-running
// adds more sessions. Run: node tools/seed-demo-users.mjs
const BASE = process.env.API_BASE_URL ?? "http://localhost:2098";

const pad = (n) => String(n).padStart(2, "0");
const fmt = (d) =>
  `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}:00`;
const r25 = (x) => Math.round(x / 2.5) * 2.5;

async function api(path, { method = "GET", token, body } = {}) {
  const res = await fetch(`${BASE}${path}`, {
    method,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  const data = text ? JSON.parse(text) : null;
  if (!res.ok) throw new Error(`${method} ${path} -> ${res.status} ${text.slice(0, 120)}`);
  return data;
}

async function registerOrLogin(email, password, displayName) {
  try {
    return await api("/api/auth/register", { method: "POST", body: { email, password, displayName } });
  } catch {
    return await api("/api/auth/login", { method: "POST", body: { email, password } });
  }
}

// Pick one exercise id per muscle (compound/weighted preferred). Cached per muscle+equip.
const pickCache = {};
async function pick(token, muscle, prefEquip) {
  const key = `${muscle}:${prefEquip ?? ""}`;
  if (pickCache[key]) return pickCache[key];
  const q = prefEquip ? `?muscle=${muscle}&equipment=${prefEquip}` : `?muscle=${muscle}`;
  let list = await api(`/api/workout/exercises${q}`, { token });
  if (!list.length && prefEquip) list = await api(`/api/workout/exercises?muscle=${muscle}`, { token });
  const weighted = list.find((e) => e.exerciseType === "WEIGHT_REPS") ?? list[0];
  pickCache[key] = weighted;
  return weighted;
}

// slot = [muscle, prefEquip, baseKg(male), reps]
const PUSH = [
  ["CHEST", "BARBELL", 60, 8],
  ["UPPER_CHEST", "DUMBBELL", 24, 10],
  ["FRONT_DELTS", "BARBELL", 40, 8],
  ["SIDE_DELTS", "DUMBBELL", 10, 14],
  ["TRICEPS", "CABLE", 25, 12],
];
const PULL = [
  ["LATS", "MACHINE", 50, 10],
  ["UPPER_BACK", "BARBELL", 60, 8],
  ["REAR_DELTS", "DUMBBELL", 12, 15],
  ["BICEPS", "BARBELL", 25, 10],
  ["FOREARMS", "DUMBBELL", 15, 12],
];
const LEGS = [
  ["QUADRICEPS", "BARBELL", 80, 6],
  ["HAMSTRINGS", "BARBELL", 70, 8],
  ["GLUTES", "BARBELL", 70, 10],
  ["HAMSTRINGS", "MACHINE", 40, 12],
  ["CALVES", "MACHINE", 60, 15],
  ["ABS", null, 0, 15],
];
const DAYS = [
  { name: "Push", slots: PUSH },
  { name: "Pull", slots: PULL },
  { name: "Legs", slots: LEGS },
];

async function buildDay(token, slots) {
  const out = [];
  for (const [muscle, equip, base, reps] of slots) {
    const ex = await pick(token, muscle, equip);
    if (ex) out.push({ ex, base, reps });
  }
  return out;
}

async function seedUser({ email, password, displayName, gender, weight, height, birthday, goal, factor }) {
  const auth = await registerOrLogin(email, password, displayName);
  const token = auth.accessToken;
  await api("/api/users/profile", {
    method: "PUT",
    token,
    body: {
      displayName,
      gender,
      currentWeight: weight,
      targetWeight: gender === "FEMALE" ? weight - 3 : weight + 4,
      height,
      birthday,
      fitnessGoal: goal,
      isPublic: true,
    },
  });

  // Resolve exercises for the 3 day-templates once.
  const days = [];
  for (const d of DAYS) days.push({ name: d.name, exs: await buildDay(token, d.slots) });

  const now = new Date();
  const TOTAL = 51; // ~4/week over ~13 weeks
  let posted = 0;
  for (let i = 0; i < TOTAL; i++) {
    const dayOffset = 90 - Math.round(i * 1.75); // 90d ago -> ~today
    const start = new Date(now);
    start.setDate(start.getDate() - dayOffset);
    start.setHours(8 + (i % 3), 0, 0, 0);
    const end = new Date(start.getTime() + 55 * 60000);
    const week = Math.floor((90 - dayOffset) / 7);
    const prog = 1 + 0.012 * week; // progressive overload

    const day = days[i % 3];
    const exercises = day.exs.map(({ ex, base, reps }, idx) => {
      const w = base > 0 ? r25(base * factor * prog) : 0;
      const sets = [];
      let order = 0;
      if (w > 0) {
        sets.push({ orderIndex: order++, weight: r25(w * 0.5), reps: 10, type: "WARMUP", isCompleted: true });
      }
      for (let s = 0; s < 3; s++) {
        sets.push({ orderIndex: order++, weight: w > 0 ? w : null, reps, rpe: 8, type: "NORMAL", isCompleted: true });
      }
      return { exerciseId: ex.id, orderIndex: idx, sets };
    });

    try {
      await api("/api/workout/sessions", {
        method: "POST",
        token,
        body: { name: `${day.name} Day`, startTime: fmt(start), endTime: fmt(end), exercises },
      });
      posted++;
    } catch (e) {
      console.log("  session failed:", e.message);
    }
  }
  console.log(`${displayName}: ${posted}/${TOTAL} sessions seeded (${email})`);
}

await seedUser({
  email: "demo.male@fityaar.test", password: "Password123", displayName: "Arjun (Demo)",
  gender: "MALE", weight: 78, height: 178, birthday: "1996-05-10", goal: "Build muscle", factor: 1.0,
});
await seedUser({
  email: "demo.female@fityaar.test", password: "Password123", displayName: "Priya (Demo)",
  gender: "FEMALE", weight: 62, height: 165, birthday: "1998-08-22", goal: "Get stronger", factor: 0.55,
});
console.log("Done. Log in as demo.male@fityaar.test / demo.female@fityaar.test (Password123).");
