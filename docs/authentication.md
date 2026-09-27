# FitYaar Authentication

_Last updated: 2026-08-28_

FitYaar uses **stateless JWT authentication**. Clients register or log in, receive an access +
refresh token, and send the access token as a `Bearer` header on every subsequent request.

## Endpoints

### `POST /api/auth/register`
Creates a user + profile and returns tokens.

Request:
```json
{ "email": "you@example.com", "password": "password123", "displayName": "Your Name" }
```
Response `200`:
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "tokenType": "Bearer",
  "expiresIn": 86400000,
  "user": { "id": 3, "email": "you@example.com", "displayName": "Your Name", "role": "USER" }
}
```

### `POST /api/auth/login`
```json
{ "email": "you@example.com", "password": "password123" }
```
Returns the same `AuthResponse` shape as register.

### Authenticated requests
Send the access token on all non-public routes:
```
Authorization: Bearer <accessToken>
```
Controllers read the current user via `@AuthenticationPrincipal UserPrincipal principal`.
Example protected routes: `GET/PUT /api/users/profile`, all of `/api/workout/**`.

## Security model

- **Public** routes: `/api/auth/**`, `/v3/api-docs/**`, `/swagger-ui/**`, `/swagger-ui.html`.
- **Everything else**: authenticated. Missing/invalid token → `401`.
- Passwords are hashed with **BCrypt**; plaintext is never stored.
- Sessions are **stateless** (`SessionCreationPolicy.STATELESS`) — no server-side session.

### Error responses
All handled exceptions return a consistent `ApiError` body (`timestamp`, `status`, `error`,
`message`, `path`, optional `fieldErrors`):

| Situation | Status |
|---|---|
| Missing/invalid token on protected route | `401` |
| Wrong email/password on login | `401` |
| Duplicate email on register | `409` |
| Validation failure (e.g. password < 8 chars) | `400` |
| Entity not found | `404` |

## Configuration

Set via `application.yml` / environment variables (see [configuration.md](configuration.md)):

| Variable | Purpose | Default |
|---|---|---|
| `JWT_SECRET` | HMAC signing secret (**change in prod**) | dev-only placeholder |
| `app.jwt.access-expiration-ms` | Access token TTL | `86400000` (24h) |
| `app.jwt.refresh-expiration-ms` | Refresh token TTL | `604800000` (7d) |
| `GOOGLE_CLIENT_ID` | Google Sign-In (planned) | — |

## Relevant classes

| Class | Role |
|---|---|
| `security.jwt.JwtService` | Issues/validates tokens |
| `security.jwt.JwtAuthenticationFilter` | Reads `Bearer` header, populates security context |
| `security.UserPrincipal` | Adapts `User` → Spring `UserDetails` |
| `security.CustomUserDetailsService` | Loads user by email |
| `config.SecurityConfig` | Filter chain, BCrypt, CORS, `AuthenticationManager` |
| `user.controller.AuthController` | `/api/auth/register`, `/api/auth/login` |
| `exception.GlobalExceptionHandler` | Maps exceptions → `ApiError` |

## Known issues / TODO

- **Legacy plaintext seed users** (`john.doe`, `john.dowe`) predate hashing and **cannot log in**;
  the data seeder must BCrypt-hash passwords like the register flow. _(Fix pending.)_
- **Google OAuth** sign-in not yet implemented (`User.googleId` field exists).
- **Refresh-token** endpoint + persistence/rotation not yet implemented (tokens are issued but there
  is no `/api/auth/refresh` yet).
- Registration moved from `POST /api/users/register` → **`POST /api/auth/register`** and now returns
  tokens; mobile/web clients must use the new path.

## Local testing

Dev profile runs on **port 2098** (`application-dev.yml`). Quick smoke test:
```powershell
$base="http://localhost:2098"
$reg = Invoke-RestMethod "$base/api/auth/register" -Method Post -ContentType application/json `
  -Body (@{email="you@example.com";password="password123";displayName="You"}|ConvertTo-Json)
Invoke-RestMethod "$base/api/users/profile" -Headers @{Authorization="Bearer $($reg.accessToken)"}
```
