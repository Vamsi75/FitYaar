# FitYaar-Web

The public **FitYaar.com** website + unified account hub, built with **Next.js (App Router) + TypeScript + Tailwind**.

It is one of three surfaces on the single FitYaar backend:

- **Mobile app** (Flutter) — logging & tracking
- **Website** (this repo) — discovery / SEO / calculators / learning **and** the one place to create or log into a FitYaar account
- **Management portal** — the existing super-admin cockpit served by the backend at `/admin`

## Run

```bash
cp .env.local.example .env.local     # then edit if needed
npm install
npm run dev                          # http://localhost:3000
```

The Spring backend must be running (dev: `http://localhost:2098`). Calculators work with no backend; login/register call `/api/auth/*`.

```bash
npm run build && npm run start       # production build (type-checked)
```

## Environment

| Var | Purpose | Dev default |
| --- | --- | --- |
| `NEXT_PUBLIC_API_BASE_URL` | FitYaar backend base URL | `http://localhost:2098` |
| `NEXT_PUBLIC_SITE_URL` | Canonical site URL for SEO/sitemap | `http://localhost:3000` |

## Super-admin → portal hand-off

On login the site stores the session under the **same `localStorage` keys the `/admin` portal reads** (`fy_admin_token`, `fy_admin_role`, `fy_admin_email`). When the site and `/admin` are served from the **same origin in production**, a super-admin (`role === "ADMIN"`) opening **FitYaar Management** lands in the portal already authenticated — no second login. In split-origin dev, the Management link opens `/admin` where the portal handles its own login.

## Structure

```
app/
  page.tsx                 # home
  calculators/             # hub + bmi / bmr / tdee / protein (SEO pages)
  login/ register/ me/     # unified account
  sitemap.ts robots.ts     # SEO plumbing
components/  ui/ auth/ calculators/ exercises/
lib/         api.ts session.ts session-client.ts types.ts calc/ body/ exercises.ts
app/api/session/  login/ register/ logout/   # httpOnly-cookie session route handlers
```

## Session & security (D-2, done)

The web session lives in **httpOnly cookies** set by the `app/api/session/*` route handlers:
`fy_at` (access token, httpOnly), `fy_rt` (refresh token, httpOnly), and a readable
`fy_user` (base64url JSON — identity only, no secret) for menu rendering. **No tokens in
`localStorage`.** The backend `JwtAuthenticationFilter` accepts the JWT from either the
`Authorization: Bearer` header (mobile/API) or the `fy_at` cookie (same-origin web + portal).

**CORS** is an explicit allow-list, not `*`:

| Var | Purpose | Dev default |
| --- | --- | --- |
| `APP_CORS_ALLOWED_ORIGINS` (backend) | comma-separated web origins allowed to send credentialed requests | `http://localhost:3000` |

Super-admin → `/admin` hand-off is now via the same-origin `fy_at` cookie (prod). In split
dev (:3000 vs :2098) cookies aren't shared, so the portal shows its own login.

Follow-ups: auto-refresh via `fy_rt` when `fy_at` expires; refresh-token revoke on logout;
CSRF token; Google OAuth on web. See `docs/milestones.md` → **Milestone 7**.
