# FitYaar — project conventions

India-first fitness app (Hevy-like) + gym B2B. One backend serves Android/iOS/Web.
See `docs/roadmap.md`, `docs/architecture.md`, `docs/milestones.md`.

## Layout
- `FitYaar-Backend/` — Spring Boot 3.4, Java 21, Postgres, Flyway. Modular monolith.
- `FitYaar-Mobile/` — Flutter app (feature-first `lib/features/*`, shared `lib/core/*`).
- `FitYaar-Web/` — web (incl. `superadmin.html`, a lite super-admin console).
- `docs/` — roadmap, architecture, milestones, auth, Postman collection.

## Backend
- Modules under `com.fityaar.*`: `user`, `workout`, `gym`, `social`, `security`, `exception`, `common`, `config`.
- Each: `controller → service → repository` + `dto` / `entity`.
- **Auth**: stateless JWT (access) + persisted **rotating refresh tokens**; Google OAuth via `/api/auth/google`. Get the current user with `@AuthenticationPrincipal UserPrincipal`.
- **Schema is Flyway-owned** (`src/main/resources/db/migration`), `ddl-auto: validate`. Migrations are **forward-only** — add a new `V{n}__*.sql`, never edit an applied one. Entities must match the migrated schema.
- Errors go through `GlobalExceptionHandler` → `ApiError` (404/409/400/401/403).
- Run: `mvn spring-boot:run` (dev profile → port 2098). Prod profile reads `DB_URL/DB_USERNAME/DB_PASSWORD`, `JWT_SECRET`, `SUPER_ADMIN_CODE`, `GOOGLE_CLIENT_ID`.
- Docker: `docker compose up` (Postgres + backend on host :2098). CI: `.github/workflows/ci.yml` (`mvn verify` runs the Testcontainers smoke test).

## Mobile (Flutter)
- State via `provider`. HTTP via `core/network/ApiClient` (injects JWT, auto-refreshes on 401). Tokens in secure storage behind `TokenStore`.
- API base URL: `--dart-define=API_BASE_URL=...` (default `http://10.0.2.2:2098` for the Android emulator; use the machine LAN IP for a physical device).
- Verify changes: `flutter analyze`; integration tests in `test/*_flow_test.dart` hit the live backend (`--dart-define=API_BASE_URL=http://localhost:2098`).
- Bottom nav: Home · Workout · Social · Profile. Glass UI (`core/widgets/GlassCard`, `GlassButton`) over a dark gradient.

## Testing / verifying
- Backend: `mvn verify` (Testcontainers). Mobile: `flutter analyze` + the `*_flow_test.dart` suites.
- Always run a real build/analyze after UI changes — the web CFE catches type errors the analyzer can miss.

## Local machine notes (this dev box)
- Terminal PATH lacks mvn/flutter/JDK21. Use: JDK21 `C:\Users\VamsiH\.jdks\ms-21.0.10`, Maven `C:\Program Files\IntelliJ IDEA 2025\plugins\maven\lib\maven3\bin\mvn.cmd`, Flutter `C:\Users\VamsiH\flutter\bin\flutter.bat`, psql `C:\Program Files\PostgreSQL\18\bin\psql.exe`. No Android SDK installed yet (USB device builds need it).

## Demo codes
- Gym: join `IRON123`, owner `OWNER123`. Super-admin claim code: `LETMEIN-SUPER`.
