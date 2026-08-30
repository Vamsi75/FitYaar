# FitYaar Project Milestones

## Milestone 0: Foundation — Auth & Security 🔐
- [x] 0.1 JWT authentication (access + refresh tokens) + BCrypt password hashing
- [x] 0.2 Stateless Spring Security config (public: /api/auth/**, docs; rest authenticated)
- [x] 0.3 `@AuthenticationPrincipal` replaces the insecure `X-User-Id` header everywhere
- [x] 0.4 Global exception handler + request validation (`@Valid`)
- [ ] 0.5 Google OAuth sign-in (googleId field exists)
- [ ] 0.6 Refresh-token endpoint + persistence/rotation
- [ ] 0.7 Convert schema to Flyway migrations (currently Hibernate ddl-auto)
- [ ] 0.8 Docker Compose + CI + Testcontainers + CLAUDE.md conventions

## Milestone 1: Workout Tracking (Core Engine) 🏗️
- [x] 1.1 Data Transfer Objects (DTOs) & Mappers
- [x] 1.2 Workout Service Logic (Routines & Sessions)
- [x] 1.3 REST API Endpoints (Exercises, Routines, Sessions)
- [x] 1.4 Personal Records (PR) Tracking logic
- [x] 1.5 Database Seeding (Exercises & Templates)

## Milestone 2: Social & Community 👥
- [ ] 2.1 Friendship Management (Requests & Friend list)
- [ ] 2.2 Social Analytics (Friend comparison)
- [ ] 2.3 Profile Discovery & Privacy

## Milestone 3: Advanced Nutrition & Integration 🥗
- [ ] 3.1 Comprehensive Food Database (Indian Staples)
- [ ] 3.2 Goal Integration (Calorie & Water)
- [ ] 3.3 Dashboard Aggregation API

---
*Status: Milestone 0 in progress (core auth landed 2026-08-28); Milestone 1 complete; Milestone 2 (Social) is next.*
