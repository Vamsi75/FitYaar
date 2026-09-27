# FitYaar Management — Super-Admin Portal (design analysis)

_Last updated: 2026-09-08_

## 1. Principle & scope
- **Super-admin portal = web.** The platform-level console: gyms, users, money, audit, health.
- **Owners & trainers = the Flutter app** (already true — `trainer_gym_screen`, `members_screen`,
  `member_detail_screen`). The portal sits *above* tenants; it does not duplicate gym-floor management.
- Today's `FitYaar-Web/superadmin.html` is a lite vanilla-JS console (sign in, claim super-admin,
  create gym, assign owner, set plan, grant Pro). It proved the flows — the real portal **supersedes** it.

## 2. Recommended tech (low-cost, low-maintenance, "good")
| Concern | Recommendation | Why |
|---|---|---|
| Framework | **React + Vite + TypeScript** on **React-Admin** (marmelab) *or* **Refine** | Purpose-built admin frameworks over a REST API — generate tables, filters, pagination, forms, auth, CRUD. A "good portal" in a fraction of hand-rolled effort. React-Admin = most batteries-included; Refine = lighter/more flexible. |
| Data layer | One **REST data provider** → `/api/admin/*` | Backend is already REST + JWT; one provider wires every resource. |
| Auth | Reuse `POST /api/auth/login` → JWT; an **authProvider** that rejects non-`ADMIN` | Same identity system; portal gates on super-admin. |
| UI kit | MUI (ships with React-Admin) or shadcn/ui if custom | Responsive, dashboard-friendly. |
| Charts | Recharts / visx | KPI cards + timeseries. |
| Hosting | Static build on **Cloudflare Pages / Netlify / Vercel** free tier, or serve from backend under `/admin` | Static SPA = near-zero hosting cost/maintenance. |
| Repo | New `FitYaar-Web/portal/` alongside the legacy static files | Keeps the monorepo tidy. |

**Alternative** (zero framework lock-in): plain React + shadcn/ui + TanStack Query/Table — more control,
more work. For these constraints, **React-Admin/Refine** is the pick.

## 3. Information architecture (sidebar)
```
FitYaar Management
├── Dashboard         ← metrics on login
├── Gyms              ← list · detail · create · plan/seats · owner
├── Users             ← search/filter · detail · suspend/reactivate · impersonate
├── Subscriptions     ← personal Pro + gym plans · grants · promo codes
├── Payments          ← transactions, MRR, failed/refunds (Razorpay, later)
├── Plans             ← catalog CRUD (Starter/Growth/Pro…)
├── Audit Logs        ← who did what, filterable
├── Broadcasts        ← platform/gym announcements (later)
├── Content           ← exercise DB / food DB moderation (later)
└── Settings          ← platform config, admins, feature flags
```

## 4. Section-by-section (features + metrics)
**Dashboard (login landing).** KPI cards + trend charts + "needs attention":
- Gyms: total, active (plan ACTIVE), trialing, expired/suspended.
- Users: total, active, new (7/30d), Pro subscribers (personal vs gym-sponsored).
- Revenue: **MRR**, new vs churned this month, revenue by plan.
- Engagement: workouts logged (today/7d), check-ins live now, DAU/WAU/MAU (proxied from workouts+check-ins).
- Attention: gyms **over seat cap**, plans expiring in 7 days, failed payments, pending owner invites.
- Recent activity feed (from audit log).

**Gyms.** Table (name, owner, plan, members/seats, live now, status, renewal) — search/filter/sort/paginate.
Detail: overview, members/trainers roster (read-only), plan & seat utilization, billing window,
check-in/activity trends, per-gym audit trail, actions (assign/change owner, set plan, suspend, deactivate).

**Users.** Global search (email/name), filter by role/status. Detail: profile, gym memberships,
subscription/entitlement, activity, actions (suspend/reactivate/deactivate, grant Pro, resend invite,
**impersonate / "view as"** — time-boxed + audited).

**Subscriptions.** Personal Pro list (source RAZORPAY/MANUAL/PROMO, plan, until) + gym plans; grant Pro;
manage promo codes; see who's Pro and why.

**Payments** (activates with Razorpay). Transactions, subscription charges, MRR/ARPU, failed payments +
retries, refunds/chargebacks, revenue by plan/region. Until live: shows manual grants + gym plan revenue.

**Plans (catalog).** CRUD `SubscriptionPlan` (name, maxMembers, maxTrainers, price, cycle, active);
assign to gyms; utilization per plan. (Backend **Phase 2**.)

**Audit Logs.** Filter by actor/action/gym/date; export CSV. (Backend **Phase 4**.)

**Later / "everything else":** Broadcasts (platform/per-gym push — FCM already live), Content moderation
(exercise/food DB), backend health & error monitoring, data export / GDPR delete, multiple portal-admin
seats with scoped permissions, feature-flags UI (`fityaar.features.*`).

## 5. Backend gaps (portal need vs what exists)
| Portal need | Endpoint today | Status |
|---|---|---|
| Admin login + "am I super-admin" | `POST /api/auth/login`, `/api/admin/claim` | ✅ exists |
| Gyms list / create / assign owner / set plan / seats | `/api/admin/gyms*`, `/gyms/{id}/plan`, `/seats` | ✅ exists |
| Suspend/reactivate/deactivate user | `/api/admin/users/{action}` | ✅ (RBAC Phase 1) |
| Grant Pro / promo | `/api/subscriptions/grant`, `/redeem` | ✅ exists |
| **Dashboard metrics + timeseries** | — | ❌ build (`com.fityaar.analytics` empty package is the home) |
| **Users list/search/detail** | — | ❌ build `GET /api/admin/users?role=&status=&q=&page` |
| **Gym detail aggregate** (members/revenue/activity) | partial | ❌ build `GET /api/admin/gyms/{id}` |
| **Subscriptions list** | — | ❌ build `GET /api/admin/subscriptions` |
| **Plan catalog CRUD** | — | ⏳ backend **Phase 2** |
| **Audit log query** | — | ⏳ backend **Phase 4** |
| **Payments/transactions** | — | ⏳ needs **Razorpay live** |

Implies a small **"admin read API" slice** (metrics + users-list + gym-detail + subscriptions-list) on top
of the already-planned Phase 2 (plans) and Phase 4 (audit).

## 6. Security & compliance (high-privilege surface)
- **Super-admin only** — authProvider rejects non-`ADMIN`; every route guarded server-side too (never
  trust the SPA).
- **Audit every action** (Phase 4) — the portal is the #1 reason audit matters.
- **Prod hardening**: lock CORS to the portal origin (currently wildcard), HTTPS only, short-lived JWT +
  refresh, consider **2FA / IP allowlist** for super-admins, **impersonation** time-boxed + audited.
- Pagination + rate limits on list endpoints; CSV export respecting PII.

## 7. Build order (fits the approved 5-phase RBAC/backend plan)
1. **Portal MVP shell** — React-Admin app + admin login + wire *existing* endpoints (gyms, users suspend,
   grant Pro, assign owner, set plan). Instantly better than `superadmin.html`; **zero** new backend.
2. **Dashboard metrics** — build `GET /api/admin/metrics` (+ users-list, gym-detail) → login dashboard.
3. **Plans** page — rides on backend **Phase 2**.
4. **Audit Logs** page — rides on backend **Phase 4**.
5. **Payments** — when Razorpay goes live.
6. **Advanced** — impersonation, broadcasts, exports, content moderation.

Rough effort: MVP shell ~2–3 days on React-Admin; metrics endpoint + dashboard ~2 days; each later page
~1–2 days once its backend exists.

## 8. Open decisions
1. **Framework**: React-Admin (fastest) vs Refine (flexible) vs plain React+shadcn (full control).
   Recommendation: **React-Admin**.
2. **Hosting**: separate static host (Cloudflare Pages) vs served by backend at `/admin`.
3. **v1 scope**: start with the **MVP shell over existing endpoints**, or wait for Phase 2/4 so it launches
   feature-complete?
4. **Impersonation** in v1 or deferred (powerful but sensitive)?

## Relationship to other docs
- Backend RBAC/subscription/audit phases: the plan file (`moonlit-foraging-moth.md`) — the portal consumes
  Phase 2 (plans) and Phase 4 (audit) + a new admin read-API slice.
- Premium/Razorpay: `premium-setup.md`. Push/broadcasts: `fcm-setup.md`.
