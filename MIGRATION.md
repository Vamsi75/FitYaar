# FitYaar — migrate local dev setup to a new PC

Snapshot taken from this machine. DB: **876** exercises, **27** users, **103**
sessions, **2144** sets, Flyway at **V20**.

## 0. What travels, and how

| Piece | How it moves |
|-------|--------------|
| **Code** | `git clone https://github.com/Vamsi75/FitYaar.git` — build dirs & secrets are gitignored, so they will *not* come with the clone. |
| **Database** | The two files in `migration/` (**not in git** — copy them to the new PC by USB / drive / scp). They contain user emails + password hashes + refresh tokens, so they're gitignored on purpose. |
| **Secrets** | Copy manually — see step 4. |

The two DB files:
- `migration/creation.sql` — full schema (all 30 tables incl. `flyway_schema_history`).
- `migration/data.sql` — all rows + sequence positions (FK-safe, `--disable-triggers`).

Both were validated by restoring into a throwaway DB — counts matched exactly.

## 1. Install prerequisites on the new PC
- **JDK 21**, **Maven** (or use IntelliJ's bundled Maven)
- **PostgreSQL 18** (restore is from 18.3; put `psql`/`pg_dump` on PATH)
- **Flutter SDK** (+ Dart)
- **Node.js 18+** (website + tooling)
- **Android SDK** — only needed for emulator/USB device builds (not currently installed on the old box either)
- **Git**

> After install, update the **"Local machine notes"** section in `CLAUDE.md` with the new PC's JDK / Maven / Flutter / `psql` paths.

## 2. Get the code
```bash
git clone https://github.com/Vamsi75/FitYaar.git
cd FitYaar
```

## 3. Restore the database
The dev backend expects DB **`FitYaar`** on `localhost:5432`, user **`postgres`**, password **`root`** (see `FitYaar-Backend/src/main/resources/application-dev.yml` — edit it if your Postgres uses a different password).

```bash
# from the repo root, with the migration/ files copied in
psql -U postgres -c "CREATE DATABASE \"FitYaar\";"      # name is case-sensitive
psql -U postgres -d FitYaar -f migration/creation.sql   # schema
psql -U postgres -d FitYaar -f migration/data.sql        # data + flyway history
```
Because `flyway_schema_history` is restored, the backend's Flyway sees all 20
migrations already applied and just **validates** (no re-run, no wipe —
`clean-disabled: true`).

> **Alternative (fresh, no user data):** skip the dump and start the backend on an
> empty `FitYaar` DB. Flyway builds the schema and seeds the **876 exercises**
> (V2 + V19) automatically — but you'd lose the 27 demo users and their history.

## 4. Copy the gitignored secrets (a `git clone` does NOT include these)
- `FitYaar-Mobile/android/app/google-services.json` — **required** or the Android app won't build (Firebase).
- `FitYaar-Web/.env.local` — create it: `cp FitYaar-Web/.env.local.example FitYaar-Web/.env.local` (defaults are fine for local).
- *(Optional — push notifications, off by default)* backend Firebase service-account key via env `FCM_SERVICE_ACCOUNT_JSON=<raw json>` and `FCM_ENABLED=true`.
- *(Optional)* `GOOGLE_CLIENT_ID` for Google sign-in; `JWT_SECRET` / `SUPER_ADMIN_CODE` for non-dev.

## 5. Run each surface
```bash
# Backend  → http://localhost:2098  (dev profile)
cd FitYaar-Backend && mvn spring-boot:run
#   watch for: "Successfully validated 20 migrations"

# Website  → http://localhost:3000
cd FitYaar-Web && npm install && npm run dev

# Mobile   (Android emulator)
cd FitYaar-Mobile && flutter pub get && \
  flutter run --dart-define=API_BASE_URL=http://10.0.2.2:2098
#   physical device: use the PC's LAN IP instead of 10.0.2.2
```

## 6. Verify
- `curl http://localhost:2098/api/public/exercises` → returns the list.
- Web `/exercises`, `/calculators` load; log in with an existing user or register.
- Super-admin claim code: `LETMEIN-SUPER`. Gym demo codes: join `IRON123`, owner `OWNER123`.

## 7. Don't-forget / gotchas
- **Never commit `migration/`** — it holds real user data + password hashes + refresh tokens (already gitignored). Move it out-of-band.
- Postgres password must be `root` for `postgres`, or edit `application-dev.yml`. DB name is case-sensitive: `FitYaar`.
- Restore into **PostgreSQL 18** (dump is 18.3); older majors may reject it.
- Missing `google-services.json` → `flutter run` fails at the Firebase step.
- Regenerable dirs were deleted from this snapshot (`build/`, `.dart_tool/`, `target/`, `.next/`, `node_modules/`) — they rebuild via `pub get` / `mvn` / `npm install`.

## Appendix: regenerate the snapshot later
```bash
PGDUMP="/c/Program Files/PostgreSQL/18/bin/pg_dump.exe"
PGPASSWORD=root "$PGDUMP" -U postgres -h localhost -d FitYaar \
  --schema-only --no-owner --no-privileges -f migration/creation.sql
PGPASSWORD=root "$PGDUMP" -U postgres -h localhost -d FitYaar \
  --data-only --no-owner --disable-triggers -f migration/data.sql
```
