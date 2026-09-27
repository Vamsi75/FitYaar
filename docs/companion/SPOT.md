# Spot — the FitYaar Companion (concept + build spec)

> Spot is the **personality layer** of FitYaar: a tiny, button-sized, hand-drawn
> doodle buddy who reacts to what you do — sets goals with you, drops tips,
> celebrates PRs, and (gently) roasts you for skipping legs. He is NOT a
> full-screen mascot and NOT "an AI assistant." He's just… your yaar.

---

## 0. North star
- **Utility apps are spreadsheets with a skin. Spot is the relationship.** He's the thing users screenshot, name, quote, and miss when they stop training.
- **Proof model:** Duolingo's Duo (mascot → retention + free meme marketing), not just Miss Minutes.
- **The whole game is restraint + writing.** A clingy/unfunny Spot is an uninstall reason. A rare, well-timed, funny Spot is a moat.

---

## 1. Character bible

**Identity**
- Tiny simple **oval head**, big expressive **dot eyes**, minimal mouth/brows.
- **Skinny torso, surprisingly muscular cartoon arms**, normal athletic legs.
- Hand-drawn **imperfect line** (not clean vector). Signature = he's normally scrawny and only becomes *ridiculously jacked* for big moments.
- Recognizable as a **48px silhouette**.

**Personality**
- Clever, warm, **playfully sarcastic — never mean**. Dry humour, self-aware.
- Indian comedy **timing** (beats, pauses, quick punchlines). Humour comes from **body language** first, words second.

**Voice / modes**
| Mode | Tone |
|---|---|
| Default | friendly + clever |
| Training | motivating |
| Progress | proud |
| Mistakes | playfully sarcastic |
| Bad consistency | supportive, tiny ask |
| PR | hyped |
| Nutrition | informative |
| Goal setting | calm + analytical |

**India-first (optional locale toggle):** light **Hinglish** — "Aaj leg day, boss." / "Ek aur rep, phir chai." Never stereotyped; just native-feeling.

**Rules he lives by**
- Never shame (missed workouts = "been a minute", not "you broke your streak 😡").
- Never claim to be AI.
- Silence is a feature. He earns screen time.

---

## 2. Visual + animation style
- **Chalk off-white lines (#F2F2F2) on transparent** — sits on FitYaar's dark glass gradient.
- One accent only: **deep-orange #FF5722** for effects (sweat, spark, fire, confetti).
- **"Boil":** outline redraws slightly every few frames (2–4 fps jitter) so he feels alive even idle. This is cheaper AND more charming than smooth 60fps.
- Sizes: **idle ~48px inline**; **reaction ~120–160px transient** (auto-dismiss 2–3s); tap → small "Spot's corner" stats popover (later).

---

## 3. Why Rive (one puppet, not 50 characters)
Build ONE rigged puppet; a state machine drives all reactions. No 3D / Blender / GIFs / sprite sheets. Output is a tiny `.riv` (target <150 KB).

**Rig hierarchy**
```
SPOT
├── Head (eyes, brows, mouth)
├── Body (torso)
├── Left Arm → Left Hand
├── Right Arm → Right Hand
└── Pelvis
    ├── Left Leg
    └── Right Leg
+ Effects layer (sweat, spark, confetti, fire, water bottle prop)
```

---

## 4. State machine contract (EXACT names — the app calls these)
State machine name: **`Spot`**

**Inputs**
- Number **`mood`**: `0` idle · `1` excited · `2` flex · `3` tired · `4` confused · `5` proud · `6` sad · `7` sideEye
- Number **`energy`** (0–100): subtly drives idle liveliness
- Triggers (one-shots, auto-return to current `mood`):
  `pr`, `celebrate`, `facepalm`, `point`, `wave`, `walkIn`, `knuckles`, `nod`,
  `armShake`, `dance`, `thumbsUp`, `waterBottle`, `lieDown`, `sitDown`,
  `shrug`, `lookAtCalendar`

**States/animations**
- **IDLE** (loop, seamless): breathing + blink + tiny head sway.
- **EXCITED / CELEBRATE:** jump → arms up → landing bounce.
- **FLEX:** arms bend, chest expands, brows change.
- **TIRED:** shoulders drop, head down, knees bend.
- **CONFUSED:** head tilt, one brow up.
- **FACEPALM / POINT / WAVE / THUMBS-UP / SHRUG / KNUCKLES / DANCE / SIT-DOWN / LIE-DOWN / WATER-BOTTLE / LOOK-AT-CALENDAR.**

**⭐ Signature PR gag (`pr` trigger, ~1.5s):**
`0.0s normal → 0.3s eyes widen → 0.5s muscles inflate → 0.8s giant flex → 1.2s hold → 1.5s snap back to idle.`

---

## 5. Event → reaction mapping
| App event | Spot call | Duration | CTA | Example line |
|---|---|---|---|---|
| Open app | `walkIn` | 1.2s | — | "Back for more? Good." |
| Workout starts | `knuckles` | 0.8s | — | "Let's cook." |
| Set completed | `nod` | 0.4s | — | (silent nod) |
| Heavy set | `armShake` | 0.6s | — | "One more. You've got this." |
| **NEW_PR** | `pr` | 2.4s | View PR | "Okay… WHO ARE YOU?" |
| Workout completed | `celebrate` | 2.0s | Summary | "That's the one." |
| 3-day streak | `dance` | 1.5s | — | "Three in a row. Momentum." |
| 7-day streak | `celebrate`+confetti | 2.5s | — | "A whole week. Respect." |
| Missed 1 day | `shrug` | 0.8s | — | "Rest day? Allowed. Once." |
| Missed 3 days | `lookAtCalendar` | 1.2s | Quick workout | "The calendar and I have concerns." |
| Missed 7 days | `sitDown` | 1.5s | Easy workout | "Been a minute. Let's just get one in." |
| Goal 50% | `point` | 1.0s | — | "Halfway. Don't blink." |
| Goal 100% | `celebrate` | 2.5s | Set new goal | "Target down. Next?" |
| Bad consistency | `mood=7` sideEye | 0.8s | — | "Interesting choices lately." |
| Great consistency | `mood=5` proud | 1.0s | — | "You've become dangerous." |
| Protein hit | `thumbsUp` | 0.6s | — | "Recovery dept. is fed." |
| Hydration low | `waterBottle` | 0.8s | — | "Water. Now. Boss." |
| Poor recovery | `lieDown` | 1.0s | — | "Sleep is a lift too." |
| Muscle imbalance | `point` (at map) | 1.2s | View map | "Chest is loved. Rear delts filed a complaint." |

---

## 6. Line bank (write MANY per event; rotate so regulars never repeat)
Keep 5–10 variants each; mix a neutral + a funny + a Hinglish option.

**NEW_PR:** "Okay… WHO ARE YOU?" · "THAT was heavy." · "New personal best. Casually elite." · "Arre, kya baat hai!"
**Missed 7 days:** "Been a minute. One workout, that's all." · "No perfect comeback needed. Just show up." · "Wapas aaja, ek set se shuru."
**Skipped legs:** "The legs appear to have left the program." · "Leg day is a rumour at this point." · "Squat rack misses you."
**Goal onboarding (Build muscle):** "Ah. Building the physique now?" then "Weight alone won't tell us if it's muscle — I'll watch strength, volume, weight trend & consistency and put it together."
**Comeback CTA:** "Start easy — 20 minutes." 
(Expand this into a full sheet before art.)

---

## 7. Interaction budget (do NOT skip)
- Normal session: **0–2 appearances**. Milestone: 1 animation. Achievement: bigger. Error: tiny.
- **Frequency caps** per event; never talk every set.
- **Adaptive backoff:** dismissed N times → quieter.
- **Settings toggle:** Chatty / Balanced / Silent (must be mutable).
- **Accessibility:** respect reduce-motion; never hide info behind him; every line has a text form.

---

## 8. Deliverables from the artist (put in the contract)
- **`Spot.riv`** + editable **`.rev`** source.
- Artboard ~512×512, **transparent**, state machine **`Spot`** with the inputs/triggers above.
- Total **< ~150 KB**.
- Demo GIF/MP4 of every state + a one-page **naming sheet**.
- **Full commercial buyout**, no attribution, source included.

**Where:** Fiverr ("hand drawn Lottie/Rive doodle character", ~$50–250) · Upwork/Dribbble/Behance (~$300–800) · Rive community. Pick on **portfolio match to the doodle/boil style** + a transparent sample shrunk to 48px.

---

## 9. AI concept-art prompt (vibe only — don't ship AI frames)
```
minimalist hand-drawn doodle character, single rough ink line with wobble/boil,
chalk-white lines on transparent dark background, tiny simple oval head with two
big dot eyes, skinny torso but exaggeratedly muscular cartoon arms, athletic legs,
friendly cheeky expression, dynamic flex pose, sketchbook animation style,
no colour except one orange spark accent, fitness app mascot, character turnaround sheet
```

---

## 10. App integration (how FitYaar will drive it — no code)
- App loads `assets/companion/Spot.riv`, binds the `Spot` state machine.
- A **Companion Engine** maps events → `{trigger/mood, line, duration, CTA}` (deterministic rules; NOT AI). Optional small LLM later for *tip text only*, server-side, cached — never his voice.
- Backend emits events: `WORKOUT_COMPLETED, NEW_PR, GOAL_MILESTONE, STREAK_REACHED, MISSED_WORKOUT, LOW_CONSISTENCY, MUSCLE_IMBALANCE, PROTEIN_TARGET_HIT, GOAL_AT_RISK, GOAL_COMPLETED`.
- Placeholder art can stand in first; swapping `Spot.riv` in is a drop-in.

---

## 11. Legal
Distinct from Miss Minutes: no clock face, no Southern drawl, own palette/silhouette/voice. Inspiration, not imitation.

---

## 12. Phased plan
0. **Cardboard test:** placeholder art + engine + trigger harness → validate writing/timing.
1. `Spot.riv` (idle + ~6 core states) → wire real puppet.
2. Memory callbacks ("Remember 100 kg? Look at you now."), muscle-map narration, shareable PR cards.
3. Premium: deeper coaching, Hinglish pack, evolving "Spot's corner", adaptive personality.

---

### Folder convention for this lab
```
fityaar_companion_lab/
  assets/companion/
    Spot.riv            <- drop the rig here
    placeholder/*.png   <- optional stick/doodle stand-ins for early tests
```
When ready, tell me and I'll wire the Companion Engine + a trigger harness (buttons to fire every event) so you can play with Spot's reactions live.
