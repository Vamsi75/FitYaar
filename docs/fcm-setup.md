# FCM push — go-live checklist

Push notifications are **fully coded and dormant**. The backend and the Flutter
app both build and run today with FCM inactive. Flipping it on needs a Firebase
project (only you can create it) plus two credential files. Nothing below
touches application logic — it's config + secrets only.

## What's already wired (no code left to write)

**Backend** (`com.fityaar.notification`)
- `device_tokens` table (migration `V14`), `DeviceToken` entity + repo.
- `DeviceTokenService` (upsert/unregister), `PushService` (fail-soft: logs when
  disabled, prunes dead tokens when sending).
- `DeviceController` → `POST` / `DELETE /api/devices/token` (authenticated).
- Gym owner announcements (`GymService.createEvent`) already call
  `pushService.sendToUsers(activeMembers, …)`.
- Feature flag in `application.yml`: `app.fcm.enabled` (`FCM_ENABLED`, default
  `false`) + `app.fcm.service-account-json` (`FCM_SERVICE_ACCOUNT_JSON`).

**Mobile** (`lib/core/push/push_messaging.dart`)
- `PushMessaging` — guarded `Firebase.initializeApp()`; if Firebase isn't
  configured it no-ops (that's why the app builds without `google-services.json`).
- Token registered after login / on an already-authed launch, removed on logout
  (`AuthService.registerPush` / `removeToken`, driven from `AuthProvider`).
- Foreground messages shown via `GymNotifications.showMessage`; background/
  terminated handled by a top-level `@pragma('vm:entry-point')` handler.
- `firebase_core` + `firebase_messaging` are already in `pubspec.yaml`.

The **only** thing missing is the Firebase project and its two files.

## Step 1 — Create the Firebase project
1. https://console.firebase.google.com → add project.
2. Add an **Android app** with package name **`com.fityaar.fityaar`**
   (matches `android/app/build.gradle.kts` `applicationId`).
3. Download **`google-services.json`** → place at
   `FitYaar-Mobile/android/app/google-services.json`.
   *(Already git-ignored — it will not be committed.)*

## Step 2 — Enable the google-services Gradle plugin
This plugin is intentionally **not** applied yet, because it hard-fails the build
when `google-services.json` is absent. Add it once the file is in place.

`android/settings.gradle.kts` — in the `plugins { }` block add:
```kotlin
id("com.google.gms.google-services") version "4.4.2" apply false
```

`android/app/build.gradle.kts` — in the top `plugins { }` block add:
```kotlin
id("com.google.gms.google-services")
```

Then `flutter clean && flutter run`. On login you should see a row appear in
`device_tokens` for your user.

> If Gradle complains about `minSdk`, set `minSdk = 23` in
> `android/app/build.gradle.kts` `defaultConfig` (firebase_messaging's floor).

## Step 3 — Let the backend send
1. Firebase console → Project settings → **Service accounts** → *Generate new
   private key* → download the JSON.
2. Provide it to the backend as **raw JSON** (not a path):
   - `FCM_SERVICE_ACCOUNT_JSON` = the full JSON contents
   - `FCM_ENABLED=true`
   (Docker: add both to the backend service env; local dev: set them before
   `mvn spring-boot:run`.)
3. Restart the backend. On boot it logs that Firebase initialized (instead of
   "FCM disabled").

## Step 4 — Verify end to end
1. Log in on the device → confirm a `device_tokens` row.
2. As a gym owner, post an announcement (`POST /api/gyms/{id}/events`).
3. Active members receive a push — **foreground** shows via the in-app
   notification, **background/closed** shows in the system tray.

## Not yet done (later Phase-5 slices)
- Scheduled **server-side** density-alert push (needs a cron job; the in-app
  local density alert already works).
- **iOS APNs** (upload the APNs key in Firebase, add
  `GoogleService-Info.plist`). Android first.
