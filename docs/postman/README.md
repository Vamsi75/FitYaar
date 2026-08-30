# FitYaar Postman Collection

API tests for **Auth**, **Users**, and **Workout**. Nutrition is deferred to the next release and is
hidden by a feature flag, so this collection asserts `/api/nutrition/**` returns `404`.

## Files
- `FitYaar.postman_collection.json` — the collection.
- `FitYaar.local.postman_environment.json` — sets `baseUrl` to the dev instance (`http://localhost:2098`).

## Run in the Postman app
1. Import both files.
2. Select the **FitYaar Local (dev)** environment.
3. Run the collection top-to-bottom (Collection Runner). **Register runs first** and captures the JWT
   into the `accessToken` collection variable, which every protected request reuses.

## Run from the CLI (newman)
No install needed if you have Node:
```bash
npx newman run docs/postman/FitYaar.postman_collection.json \
  -e docs/postman/FitYaar.local.postman_environment.json
```

## Notes
- Each run registers a fresh unique email (`pm_<timestamp>@fityaar.com`), so re-runs don't collide.
- Covers happy paths and the `401 / 409 / 400 / 404` error paths.
- The dev profile runs on **port 2098** (see `application-dev.yml`).
