# FitYaar Roadmap & Status

> Single source of truth for *what we're building, in what order, and where we are*.
> Designed to be read by multiple contributors/agents across devices. Keep it current.

_Last updated: 2026-08-28_

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
| **0. Foundation — Auth & Security** | JWT + BCrypt, stateless Spring Security, `@AuthenticationPrincipal`, global exceptions, validation, Google OAuth, refresh tokens, Flyway, Docker/CI | 🟡 **In progress** — core auth done & verified |
| **1. Workout Tracking (Core Engine)** | Exercises, routines, sessions, sets, PRs, seeding | ✅ **Done** |
| **2. Social & Community** | Follow/followers, private accounts, follow requests, public-profile compare | ⬜ Next |
| **3. Nutrition + Premium** | Food logging, water, daily summaries, subscription + premium gating | ⬜ Planned |
| **4. Gym B2B** | Organization/gym tenancy, trainer role & plans, crowding, banners, challenges | ⬜ Planned |
| **5. Integrations, Notifications, Deploy** | FCM push, Strava/Fitbit import, analytics, India-region deploy | ⬜ Planned |

Granular checklist lives in [milestones.md](milestones.md).

## Where we are now (2026-08-28)

**Phase 0 core authentication is implemented and runtime-verified** against local Postgres 18.

Delivered & tested:
- JWT access + refresh issuance, BCrypt password hashing.
- Stateless `SecurityConfig`: `/api/auth/**` + API docs public, everything else authenticated.
- `AuthController` (`POST /api/auth/register`, `POST /api/auth/login`).
- Removed the insecure `X-User-Id` header (and `WorkoutController`'s `findById(1L)` fallback);
  controllers now use `@AuthenticationPrincipal`.
- Global exception handler + `@Valid` request validation.

Verified locally: register→login→profile, and the 401/409/400 error paths, all pass; new
passwords persist as BCrypt; 173 exercises seed correctly. See [authentication.md](authentication.md).

**API test suite:** a Postman collection ([postman/](postman/)) covers Auth + Users + Workout —
**23/23 assertions pass** via newman. **Nutrition is deferred to next release** and hidden behind
`fityaar.features.nutrition=false` (returns 404). Testing also caught & fixed a bug where the
catch-all exception handler turned framework 404s into 500s.

### Open items to close Phase 0
1. **Data seeder inserts legacy plaintext users** (`john.doe`, `john.dowe`) — must BCrypt-hash like
   the register flow; those accounts can't log in until fixed.
2. **Google OAuth** sign-in (`googleId` field already exists on `User`).
3. **Refresh-token** endpoint + persistence/rotation.
4. **Flyway** migration conversion (currently Hibernate `ddl-auto: update`).
5. **Docker Compose + CI + Testcontainers + CLAUDE.md** conventions.

## Next step

Fix the seeder (small, directly exposed by testing), then Google OAuth — or jump to Phase 2 (Social),
since the workout core is already built.
