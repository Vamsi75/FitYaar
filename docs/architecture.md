# FitYaar Architecture

_Last updated: 2026-08-28_

## Overview

FitYaar is a **modular monolith**: one deployable Spring Boot application organized into feature
modules. One backend serves all clients (Android, iOS, Web) over a versioned JSON API.

```
FitYaar/
├── FitYaar-Backend/   Spring Boot API (Java 21, Spring Boot 3.4)
├── FitYaar-Mobile/    Flutter app (Android + iOS)
├── FitYaar-Web/       React analytics dashboard
├── docs/              Documentation (this folder)
├── database/          Flyway migrations & seed data
└── storage/           Media & export storage
```

## Backend module map (`com.fityaar`)

| Module | Responsibility |
|--------|----------------|
| `user` | Accounts, profiles, auth-facing endpoints |
| `workout` | Exercises, routines, sessions, sets, personal records |
| `nutrition` | Food/water logging, daily summaries |
| `social` | Follow graph, friend requests, privacy |
| `subscription` | Premium tiers & billing |
| `analytics` | Aggregations & dashboards |
| `security` | JWT filter, `UserPrincipal`, `UserDetailsService` |
| `exception` | Global handler + typed exceptions |
| `config` | Spring Security & cross-cutting config |
| `common` | Shared base entities (e.g. `BaseAuditEntity`) |

Each module follows `controller → service → repository`, plus `dto` / `entity` / `mapper`.

## Key decisions

| Decision | Choice | Why (given our constraints) |
|---|---|---|
| Backend shape | **Modular monolith** | One deployable = lowest cost/maintenance; module boundaries let contributors work in parallel. Can split later. |
| Mobile | **Flutter** | One codebase → Android + iOS. |
| Web | **React** | Read-only analytics dashboard. |
| DB | **PostgreSQL** + **Flyway** | Versioned, ordered migrations avoid multi-contributor schema conflicts. |
| Auth | **JWT (access + refresh)** + Google OAuth | Stateless → identical across all devices, no session store. |
| API | Versioned + **OpenAPI/Swagger** | The contract that keeps clients & contributors in sync; can generate client SDKs. |
| Images | Cloudflare R2 (planned) | No egress fees. |
| Push | FCM (planned) | Free; gym banners & social notifications. |
| Payments | Play Billing / Apple IAP (consumer) + Razorpay (gym B2B) | Stores require IAP for in-app digital subscriptions in India. |
| Hosting | India region (e.g. DigitalOcean Bangalore / AWS Mumbai) + managed Postgres | Low latency for India, low starting cost. |

## How this satisfies the constraints

- **Low cost / low maintenance** — one deployable, managed Postgres, free FCM, cheap object storage.
- **Multiple contributors/agents** — modular monolith + Flyway (no schema merge wars) + OpenAPI
  contract + tests. Each contributor can own a module.
- **Multiple devices** — one stateless JWT API, versioned, OpenAPI → generated clients so every
  device shares the same contract.

## Current tech stack (in `pom.xml`)

Java 21 · Spring Boot 3.4 · Spring Security · Spring Data JPA · Validation · Flyway
(core + postgres) · PostgreSQL · Lombok · MapStruct · springdoc-openapi · jjwt 0.12.3 ·
Testcontainers (test).

> Note: dependencies were pre-added; some (Flyway, OpenAPI wiring) are present but not yet fully
> activated. See [roadmap.md](roadmap.md) for status.
