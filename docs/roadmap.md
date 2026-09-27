# FitYaar Roadmap & Status

> Single source of truth for *what we're building, in what order, and where we are*.
> Designed to be read by multiple contributors/agents across devices. Keep it current.

_Last updated: 2026-09-08_

## Vision

FitYaar is an **India-focused fitness app** — "Hevy, but more Indian" — with **one backend** serving
**Android, iOS, and Web**. Build order: **backend first**, then Android, then Web.

### Consumer product
- Log all exercise types (workout tracking core).
- Follow / followers, with **private accounts**.
- Compare your workouts against any **public** profile.
- **Premium** tier.
- Integrations: **Fitbit, Strava** (later phase).

### Gym B2B (sell the app to gyms; their members get the full app + gym features)
- Live **gym crowding**.
- Trainer-assigned **workout plans**.
- Compare **gymmates**; healthy **competitions/challenges**.
- Owner **announcements** via banner/push (e.g. "gym closed").

### Hard constraints
- **Low cost + low maintenance.**
- Must support **multiple contributors/agents working in parallel**.
- Must serve **multiple device types** from one API.

See [architecture.md](architecture.md) for how the tech choices satisfy these.

## Phased plan

| Phase | Scope | Status |
|------|-------|--------|
| **0. Foundation — Auth & Security** | JWT + BCrypt, stateless Spring Security, `@AuthenticationPrincipal`, global exceptions, validation, Google OAuth, refresh tokens, Flyway, Docker/CI | ✅ **Done** |
| **1. Workout Tracking (Core Engine)** | Exercises, routines, sessions, sets, PRs, seeding | ✅ **Done** |
| **2. Social & Community** | Follow/followers, private accounts, follow requests, public-profile compare | ✅ **Done** |
| **3. Nutrition + Premium** | Food logging, water, daily summaries, subscription + premium gating | 🟡 **Partial** — **subscription/entitlement + gym seat-billing done** (`V15`; Pro via personal grant/promo or gym-sponsored, surfaced on login + `/api/me/entitlements`; Razorpay web checkout dormant behind a flag); **nutrition** still gated off + on a mock user |
| **4. Gym B2B** | Organization/gym tenancy, trainer role & plans, crowding, banners, challenges | ✅ **Done** — incl. live crowding/zones/trends, personal training, classes, leaderboard, gym-live hologram UI |
| **5. Integrations, Notifications, Deploy** | FCM push, Strava/Fitbit import, analytics, India-region deploy | 🟡 **In progress** — **FCM push done & verified** (owner announcements → members; device tokens `V14`); scheduled density-alert push, Strava/Fitbit + deploy pending |
| **6. Super-Admin Management Portal** | React-Admin web console: metrics dashboard, gyms, users, subscriptions/payments, plans, audit | 📐 **Designed** ([management-portal.md](management-portal.md)) — not started; needs an admin read-API (metrics/users/subscriptions) + RBAC Phase 2/4 |

Granular checklist lives in [milestones.md](milestones.md).

## Where we are now (2026-09-08)

**Phases 0, 1, 2 and 4 are implemented and runtime-verified.** Schema is Flyway-owned through
**V16** (`ddl-auto: validate`). Backend runs on the dev profile (:2098); the mobile app is verified
on the Android emulator and drives the full flow.

**Multi-tenant RBAC hardening (in progress):** Phase 1 done (`V16`) — gym roles are now
`{OWNER, TRAINER, MEMBER}` (renamed from ADMIN), a central `AuthorizationService` fixes the
privilege-escalation bugs (trainer→admin, owner→owner now 403), `User.status`
(INVITED/ACTIVE/SUSPENDED/DEACTIVATED) gates login, and super-admin can suspend/reactivate users.
Remaining phases: plan-catalog limits, invitation/activation, audit log, console. See the plan file.
The super-admin **web management portal** (metrics, gyms, users, subscriptions/payments, audit) is
designed in [management-portal.md](management-portal.md) — a React-Admin SPA that supersedes the lite
`superadmin.html`; it consumes RBAC Phase 2/4 plus a small new admin read-API (metrics/users/subscriptions).

Delivered:
- **Phase 0** — JWT access + rotating refresh tokens (`V7`), Google OAuth (`/api/auth/google`),
  BCrypt, stateless `SecurityConfig`, global exceptions + `@Valid`, Flyway, Docker + CI + Testcontainers.
- **Phase 1** — exercises/routines/sessions/sets, PRs, seeding; workout edit/delete.
- **Phase 2** — follow graph + private accounts + requests (`V6`, `/api/social/**`), compare stats,
  discovery/feed.
- **Phase 4 (Gym B2B)** — gym tenancy + membership workflow (`V4`), events/banners (`V5`),
  trainer-assigned plans + personal training (`V10`/`V11`), gym v4 member records (`V12`), and the
  **gym-live** layer (`V13`): live crowding, **zone occupancy** + **hour-of-day trends**
  (`/gyms/{id}/zones`, `/trends`), gymmates-active-now, weekly leaderboard, classes. Mobile shows a
  swipeable **Live** section (orbit-dial occupancy · zone rings · 24h rhythm dial) with a **local**
  density-alert toggle.
- **Phase 5 (started)** — **FCM push** live & verified: device-token table (`V14`),
  `POST/DELETE /api/devices/token`, `PushService` (fail-soft, prunes dead tokens); **gym-owner
  announcements push to active members** — tested end-to-end on the Android emulator (Firebase
  `fityaar-bc262`; mobile `PushMessaging` guards init so the app builds without Firebase, registers
  the token on login, shows foreground pushes via `GymNotifications`). Density alerts still local-only.
  Setup/go-live in [fcm-setup.md](fcm-setup.md).
- **Phase 3 (Premium half) — done:** `com.fityaar.subscription` computes **Pro as an entitlement**
  (personal grant/promo **or** gym-sponsored seat plan), surfaced on the login response +
  `GET /api/me/entitlements` (`V15`). Super-admin console grants Pro and sets a gym's seat plan;
  mobile gates (chart ranges, premium goals, GoPro) read it live; "Go Pro" opens a **web checkout**
  (Razorpay) to dodge store fees. **Razorpay is scaffolded dormant** behind `app.payment.enabled`
  (webhook is HMAC-verified, public route, `@ConditionalOnProperty`). Verified end-to-end on-device.
  Go-live in [premium-setup.md](premium-setup.md).
- **Mobile UX** — Milestones A/B/C done; a glass design system (`AppColors`, `GlassButton`/
  `AccentButton`, `GlowAvatar`, `StatPill`) and polish passes across Home, Insights, Workout, Profile;
  `lottie` wired for animated icons (drop-in).

### Active gap — Phase 3 (Nutrition)
1. **Nutrition** is coded (`com.fityaar.nutrition`, tables in `V1`) but **gated off**
   (`fityaar.features.nutrition=false` → 404) and still uses a hardcoded **mock user (`id 1L`)** —
   must move to `@AuthenticationPrincipal` before re-enabling. This is the last incomplete core slice.
   (`com.fityaar.analytics` remains an empty placeholder.)

## Next step

**Premium (Phase 3) and FCM (Phase 5) are done.** Pro entitlement + gym seat-billing ship (Razorpay
web checkout dormant until keys land); owner announcements push for real. The **last core gap** is
**nutrition** — move it off the mock user to `@AuthenticationPrincipal` and re-enable it. After that:
turn on Razorpay (Phase 2 of premium), then Strava/Fitbit import + India-region deploy. **Health
Connect / Apple Health** sync is a later integrations slice (deferred 2026-09-08).
