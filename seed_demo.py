import json, urllib.request, urllib.error
from datetime import datetime, timedelta

BASE = "http://localhost:2098/api"

def call(method, path, token=None, body=None):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE+path, data=data, method=method)
    req.add_header("Content-Type","application/json")
    if token: req.add_header("Authorization","Bearer "+token)
    try:
        with urllib.request.urlopen(req) as r:
            t = r.read().decode()
            return r.status, (json.loads(t) if t else None)
    except urllib.error.HTTPError as e:
        return e.code, e.read().decode()

EMAIL="demo@fityaar.com"; PW="password123"
st, res = call("POST","/auth/register",body={"email":EMAIL,"password":PW,"displayName":"Demo Athlete"})
if st>=400:
    st, res = call("POST","/auth/login",body={"email":EMAIL,"password":PW})
tok = res["accessToken"]
print("auth ok, token len", len(tok))

# map exercise names -> id
_, exs = call("GET","/workout/exercises",token=tok)
byname = {}
for e in exs:
    byname[e["name"].lower()] = e["id"]
def find(*subs):
    for s in exs:
        n = s["name"].lower()
        if all(x in n for x in subs): return s["id"]
    return None

bench = find("bench","press") or find("bench")
squat = find("squat") or find("back squat")
dead  = find("deadlift")
ohp   = find("overhead","press") or find("shoulder","press")
row   = find("row")
curl  = find("bicep","curl") or find("curl")
push  = find("push","up") or find("tricep")
crunch= find("crunch") or find("sit","up") or find("plank")
pull  = find("pull","up") or find("lat","pulldown") or find("pulldown")
print("ids:", {"bench":bench,"squat":squat,"dead":dead,"ohp":ohp,"row":row,"curl":curl,"push":push,"crunch":crunch,"pull":pull})

def sets(w,r,n=3):
    return [{"orderIndex":i,"weight":w,"reps":r,"rpe":None,"type":"NORMAL","isCompleted":True} for i in range(n)]

def session(name, days_ago, items):
    start = datetime.now() - timedelta(days=days_ago, hours=1)
    end = start + timedelta(minutes=55)
    ex = []
    for oi,(eid,w,r) in enumerate(items):
        if eid is None: continue
        ex.append({"exerciseId":eid,"orderIndex":oi,"notes":None,"sets":sets(w,r)})
    body={"name":name,"startTime":start.strftime("%Y-%m-%dT%H:%M:%S"),
          "endTime":end.strftime("%Y-%m-%dT%H:%M:%S"),"notes":None,"exercises":ex}
    s,_=call("POST","/workout/sessions",token=tok,body=body)
    print(name, days_ago,"d ago ->", s)

# Chest/shoulders, legs, back (bench trends up for PR), arms/core, recent chest PR
session("Push Day",   20, [(bench,60,8),(ohp,35,8),(push,0,12)])
session("Leg Day",    16, [(squat,80,6),(dead,90,5)])
session("Pull Day",   12, [(dead,100,5),(row,60,8),(pull,0,8)])
session("Push Day",    8, [(bench,65,7),(ohp,37.5,8)])
session("Arms & Core", 5, [(curl,15,10),(push,0,15),(crunch,0,20)])
session("Push Day",    2, [(bench,72.5,6),(ohp,40,7)])
session("Leg Day",     1, [(squat,90,5),(curl,17.5,10)])

# Body weight trend (losing) + a waist/bodyfat sample
for d,w in [(28,74.0),(21,73.4),(14,72.9),(7,72.2),(0,71.6)]:
    date=(datetime.now()-timedelta(days=d)).strftime("%Y-%m-%d")
    call("POST","/measurements",token=tok,body={"date":date,"weightKg":w,
        "waistCm":(82 if d==28 else 80 if d==0 else None),
        "bodyFatPct":(16.5 if d==28 else 15.0 if d==0 else None)})
print("measurements seeded")
print("\nLOGIN:", EMAIL, "/", PW)
