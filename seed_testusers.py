import json, urllib.request, urllib.error
from datetime import datetime, timedelta

BASE = "http://localhost:2098/api"

def call(method, path, token=None, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if token: req.add_header("Authorization", "Bearer " + token)
    try:
        with urllib.request.urlopen(req) as r:
            t = r.read().decode()
            return r.status, (json.loads(t) if t else None)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()

def auth(email, name):
    st, res = call("POST", "/auth/register", body={"email": email, "password": "Test@123", "displayName": name})
    if st >= 400:
        st, res = call("POST", "/auth/login", body={"email": email, "password": "Test@123"})
    if isinstance(res, dict) and res.get("accessToken"):
        return res["accessToken"], res["user"]["id"]
    raise SystemExit(f"auth failed for {email}: {st} {res}")

# exercise catalog (from any token)
def catalog(token):
    _, exs = call("GET", "/workout/exercises", token=token)
    return exs

def find(exs, *subs):
    for s in exs:
        n = s["name"].lower()
        if all(x in n for x in subs):
            return s["id"]
    return None

def sets(w, r, n=4, warmup=True):
    out = []
    if warmup:
        out.append({"orderIndex": 0, "weight": round(w*0.5, 1), "reps": r, "rpe": None, "type": "WARMUP", "isCompleted": True})
    for i in range(n):
        out.append({"orderIndex": len(out), "weight": w, "reps": r, "rpe": None, "type": "NORMAL", "isCompleted": True})
    return out

def session(token, name, when, items):
    start = when
    end = start + timedelta(minutes=55)
    ex = []
    oi = 0
    for (eid, w, r) in items:
        if eid is None: continue
        ex.append({"exerciseId": eid, "orderIndex": oi, "notes": None, "sets": sets(w, r)})
        oi += 1
    if not ex: return
    body = {"name": name, "startTime": start.strftime("%Y-%m-%dT%H:%M:%S"),
            "endTime": end.strftime("%Y-%m-%dT%H:%M:%S"), "notes": None, "exercises": ex}
    call("POST", "/workout/sessions", token=token, body=body)

def measure(token, days_ago, weight=None, waist=None, bf=None):
    date = (datetime.now() - timedelta(days=days_ago)).strftime("%Y-%m-%d")
    b = {"date": date}
    if weight is not None: b["weightKg"] = round(weight, 1)
    if waist is not None: b["waistCm"] = round(waist, 1)
    if bf is not None: b["bodyFatPct"] = round(bf, 1)
    call("POST", "/measurements", token=token, body=b)

now = datetime.now()

# ---------------- users ----------------
rahul_t, rahul_id = auth("rahul@fityaar.com", "Rahul Verma")
sneha_t, sneha_id = auth("sneha@fityaar.com", "Sneha Rao")
trainer_t, trainer_id = auth("trainer@fityaar.com", "Coach Vikram")
print("users:", {"rahul": rahul_id, "sneha": sneha_id, "trainer": trainer_id})

exs = catalog(rahul_t)
bench = find(exs, "bench", "press") or find(exs, "bench")
squat = find(exs, "squat")
dead = find(exs, "deadlift")
ohp = find(exs, "overhead", "press") or find(exs, "shoulder", "press")
row = find(exs, "row")
pull = find(exs, "pull", "up") or find(exs, "lat", "pulldown")
curl = find(exs, "bicep", "curl") or find(exs, "curl")
legpress = find(exs, "leg", "press") or squat
latpd = find(exs, "lat", "pulldown") or row
crunch = find(exs, "crunch") or find(exs, "plank")

# profiles
call("PUT", "/users/profile", token=rahul_t, body={
    "gender": "Male", "fitnessGoal": "Get stronger", "currentWeight": 78, "height": 180, "dailyCalorieGoal": 2800})
call("PUT", "/users/profile", token=sneha_t, body={
    "gender": "Female", "fitnessGoal": "Lose weight", "currentWeight": 72, "targetWeight": 62,
    "height": 165, "dailyCalorieGoal": 1700})
call("PUT", "/users/profile", token=trainer_t, body={
    "gender": "Male", "fitnessGoal": "Stay fit", "currentWeight": 75, "height": 178})

# ---------------- 12 weeks of workouts ----------------
for w in range(12):  # w=0 oldest, 11 = this week
    base = now - timedelta(weeks=(11 - w))
    # Rahul — strength, progressive overload, 3x/week
    session(rahul_t, "Push Day", base.replace(hour=7),
            [(bench, 60 + 1.25*w, 5), (ohp, 40 + 0.75*w, 5), (row, 50 + 1.0*w, 6)])
    session(rahul_t, "Leg Day", (base + timedelta(days=2)).replace(hour=7),
            [(squat, 80 + 1.5*w, 5), (dead, 100 + 2.0*w, 4)])
    session(rahul_t, "Pull Day", (base + timedelta(days=4)).replace(hour=7),
            [(bench, 62 + 1.25*w, 5), (pull, 0, 8), (curl, 15 + 0.5*w, 10)])
    # Sneha — weight loss, moderate full-body, 3x/week
    session(sneha_t, "Full Body A", (base + timedelta(days=1)).replace(hour=18),
            [(squat, 30 + 0.5*w, 12), (bench, 25 + 0.4*w, 12), (latpd, 25 + 0.4*w, 12)])
    session(sneha_t, "Full Body B", (base + timedelta(days=3)).replace(hour=18),
            [(legpress, 50 + 1.0*w, 12), (row, 22 + 0.4*w, 12), (crunch, 0, 20)])
    session(sneha_t, "Full Body C", (base + timedelta(days=5)).replace(hour=18),
            [(squat, 32 + 0.5*w, 12), (ohp, 15 + 0.3*w, 12), (curl, 8 + 0.2*w, 12)])
    # Trainer — a couple of maintenance sessions
    if w % 2 == 0:
        session(trainer_t, "Maintenance", (base + timedelta(days=2)).replace(hour=6),
                [(bench, 70, 5), (squat, 90, 5)])

# ---------------- weekly measurements ----------------
for w in range(12):
    d = (11 - w) * 7  # days ago
    measure(rahul_t, d, weight=78 + 0.2*w, waist=82, bf=15.5 - 0.1*w)          # slight lean gain
    measure(sneha_t, d, weight=72 - 0.5*w, waist=80 - 0.5*w, bf=30 - 0.35*w)   # steady loss

# ---------------- gym: trainer owns, trains both ----------------
st, g = call("POST", "/gyms/join", token=trainer_t, body={"code": "OWNER123"})  # trainer -> ADMIN of Iron Temple
gid = g["gymId"] if isinstance(g, dict) else 1
print("trainer gym:", gid)
for tok, who in [(rahul_t, "Rahul"), (sneha_t, "Sneha")]:
    call("POST", "/gyms/join", token=tok, body={"code": "IRON123"})  # -> PENDING
# approve pending
_, pend = call("GET", f"/gyms/{gid}/requests", token=trainer_t)
if isinstance(pend, list):
    for m in pend:
        if m["userId"] in (rahul_id, sneha_id):
            call("POST", f"/gyms/memberships/{m['membershipId']}/approve", token=trainer_t)
# assign personal plans + a class
call("POST", f"/gyms/{gid}/plan", token=trainer_t, body={"clientId": rahul_id, "title": "Strength Block — Week", "body": "Heavy bench/squat/deadlift, 4x5, add 2.5kg weekly."})
call("POST", f"/gyms/{gid}/plan", token=trainer_t, body={"clientId": sneha_id, "title": "Fat-loss Circuit", "body": "Full-body 3x/week, 12 reps, 45s rest + 20 min brisk walk."})
call("POST", f"/gyms/{gid}/classes", token=trainer_t, body={"title": "HIIT Blast", "schedule": "Mon & Wed 7 PM", "description": "30-min high-intensity circuit"})
call("POST", f"/gyms/{gid}/classes", token=trainer_t, body={"title": "Strength 101", "schedule": "Sat 9 AM", "description": "Barbell basics"})

print("\nSEEDED. Login (pwd Test@123):")
print("  rahul@fityaar.com   — Male, strength")
print("  sneha@fityaar.com   — Female, weight loss")
print("  trainer@fityaar.com — Coach/Admin @ Iron Temple")
