# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository

Tekka is a C2C fashion marketplace for Uganda. It is a polyglot monorepo (no workspaces tool) with four apps under `apps/` that share env files at the repo root and infra under `infra/`.

| App | Path | Stack | Default port | Subdomain |
|---|---|---|---|---|
| API | `apps/api` | NestJS 11 + Prisma 7 + PostgreSQL | 4000 (dev) / 3000 (default) | `api.tekka.ug` |
| User dashboard | `apps/user` | Next.js 16 + React 19 + Tailwind 4 + Zustand | 3000 | `tekka.ug` |
| Admin dashboard | `apps/admin` | Next.js 16 + React 19 + Tailwind 4 + Zustand | 3001 | `admin.tekka.ug` |
| Mobile | `apps/mobile` | Flutter + Riverpod 2.6 + GoRouter + Dio + Firebase | n/a | n/a |

`infra/docker/` holds prod/dev compose files. `infra/nginx/` is the reverse-proxy config (single Let's Encrypt cert covers all subdomains). `infra/scripts/init-ssl.sh` and `renew-ssl.sh` manage certs. `_bmad/` contains BMAD framework artifacts (planning workflow, not runtime).

## Common commands

All Node apps: from the app dir, `npm install` then run scripts below.

### `apps/api` (NestJS)
- Dev (loads `../../.env.development` via `dotenv-cli`): `npm run start:dev`
- Debug: `npm run start:debug`
- Build: `npm run build` → `dist/src/main`
- Prod start (no dotenv loaded — env must already be set): `npm run start:prod`
- Lint: `npm run lint` (eslint with `--fix`)
- Tests: `npm test`, `npm run test:watch`, `npm run test:cov`, `npm run test:e2e`
- Single test: `npx jest path/to/file.spec.ts` or `npx jest -t "test name"`
- Seed DB: `npm run db:seed`

### `apps/user` and `apps/admin` (Next.js)
- Dev: `npm run dev` (user → 3000, admin → 3001; override with `PORT=...`)
- Build: `npm run build`
- Prod start: `npm run start`
- Lint: `npm run lint`
- Tests (user only): `npm test`, `npm run test:watch`, `npm run test:coverage`. Admin has no test setup.

### `apps/mobile` (Flutter)
- Get deps: `flutter pub get`
- Codegen (Freezed/JSON/Riverpod): `dart run build_runner build --delete-conflicting-outputs`
- Run prod flavor: `flutter run --flavor prod -t lib/main.dart`
- Run dev flavor (no Firebase, hits `10.0.2.2:4000` Android / `127.0.0.1:4000` iOS): `flutter run --flavor dev -t lib/main_dev.dart`
- Run staging: `flutter run --flavor staging -t lib/main_staging.dart`
- Analyze: `flutter analyze`
- Tests: `flutter test`; single file: `flutter test test/path/to/file_test.dart`
- Pinned in CI: Flutter `3.41.1`, Java `17`, Dart SDK `^3.10.4`.

### Prisma (run from `apps/api`)
- Generate client: `npx prisma generate`
- Dev migration: `npx prisma migrate dev --name <name>`
- Prod migration: `npx prisma migrate deploy`
- DB URL is read from `process.env.DATABASE_URL` via `prisma.config.ts` (Prisma 7 requires datasource URL in config, not schema). Do NOT add `import 'dotenv/config'` to `prisma.config.ts` — the prod image is built with `--omit=dev` so dotenv isn't available; envs are injected by docker-compose `--env-file` or by `dotenv-cli` for local dev.

## Environment files

Repo-root env files are the single source of truth for all four apps:
- `.env.example` — template (committed)
- `.env.development` — local dev (gitignored)
- `.env.production` — prod values used by docker-compose `--env-file` (gitignored)

API dev scripts pass `-e ../../.env.development` explicitly; Next.js apps read whichever `.env*` Next picks up from their cwd. Don't duplicate values into `apps/*/.env*` unless intentional.

## Architecture

### API surface
- Global prefix `/api/v1` (set in `apps/api/src/main.ts`). All client code expects this — `NEXT_PUBLIC_API_URL` and the Flutter Dio base URL include it.
- Swagger UI at `/api/docs` — only registered when `NODE_ENV !== 'production'`.
- Global `ValidationPipe` with `whitelist` + `forbidNonWhitelisted` + `transform`. DTOs need `class-validator` decorators or fields are stripped.
- CORS origins from `CORS_ORIGINS` (comma-separated). Defaults to localhost ports for dev.
- Modules in `app.module.ts`: `Auth, Users, Listings, Chats, Reviews, Notifications, Reports, Meetups, PriceAlerts, SavedSearches, QuickReplies, Upload, Admin, Categories, Attributes, Locations, Email`. Cron-style work uses `@nestjs/schedule` (`ScheduleModule.forRoot()`).

### Auth
- Two parallel auth systems sharing the User table:
  - **User app**: phone + OTP (ThinkXCloud SMS provider — migrated from AfricasTalking) → JWT (1h access + 7d refresh).
  - **Admin app**: email + password (bcrypt). Legacy `firebase-admin` token verification still wired in `apps/api/src/auth/firebase-admin.ts` and `firebase-auth.guard.ts`, but not the primary path.
- Guards live in `apps/api/src/auth/guards/`: `JwtAuthGuard`, `AdminGuard`, `FirebaseAuthGuard`. `@CurrentUser()` decorator injects the resolved user.
- The `User` model has both `firebaseUid` and `passwordHash` columns; treat them as parallel auth identifiers, not duplicates.

### Domain workflows
- Listing status: `DRAFT → PENDING → ACTIVE → SOLD/ARCHIVED`. Pending requires admin approval before going live.
- Image pipeline: client picks → compresses to 1200×1200 @ 85% → uploads via API → API forwards to Cloudinary.
- Categories use a 3-level hierarchical system (`Categories` + `Attributes` modules) replacing the old flat enum.
- Item condition was collapsed to `NEW` / `USED` (2026-04-16); legacy values are normalized at the API boundary for old-client compatibility. Production DB has not been migrated yet — see memory `project_condition_collapse.md`.
- The "Offers" feature is being removed across all apps — files mentioning `offer/Offer` may be in transitional states.

### Deep linking & push (mobile)
- Universal links / verified App Links on `https://tekka.ug/*` only (no custom scheme). Web pages and the app share URLs.
- Verification files served by `apps/user` as Next.js route handlers under `apps/user/src/app/.well-known/*/route.ts` (must return JSON; the Apple AASA path has no `.json` extension).
- FCM payloads from `apps/api/src/notifications/notifications.service.ts` always include `type`, `deep_link`, and a type-specific ID. Flutter `PushNotificationService` prefers `deep_link` and falls back to `type` for old installs.
- See `ARCHITECTURE.md` for the full URL → screen mapping.

### Mobile flavors & Firebase
- Three flavors: `dev`, `staging`, `prod`. **Only `prod` initializes Firebase** — dev/staging skip it entirely.
- Android: `google-services` plugin tasks are explicitly disabled for non-prod in `android/app/build.gradle.kts`. Prod reads `android/app/src/prod/google-services.json` (gitignored).
- iOS: `Strip Firebase plist` Run Script removes `GoogleService-Info.plist` from non-prod builds. The plist is required to *exist* locally so Xcode's Resources phase doesn't fail; it's stripped from the final binary for dev/staging.
- CI injects both files from base64 secrets `GOOGLE_SERVICES_JSON` and `GOOGLE_SERVICE_INFO_PLIST` for release builds on `main`.
- Bundle IDs differ: iOS `com.tootiyesolutions.tekka`, Android `com.tootiye.tekka`. Both are published — do not unify.

## CI/CD

GitHub Actions in `.github/workflows/`:
- `ci-api.yml`, `ci-admin.yml`, `ci-user.yml` — per-app PR checks.
- `deploy-api.yml`, `deploy-admin.yml`, `deploy-user.yml` — push to `main` triggers Docker build → push to GHCR (`ghcr.io/<owner>/tekka-{api,admin,user}:latest`) → SSH to VPS → `docker compose -f infra/docker/docker-compose.prod.yml --env-file .env up -d`.
- `deploy-nginx.yml` — nginx config + cert renewal.
- `mobile.yml` — Flutter analyze/test (and release build on main).
- Each workflow filters by `paths:` so only relevant apps rebuild.
- Prod deployment runs `prisma migrate deploy` against the cloud Postgres (Alwaysdata).

## Conventions worth knowing

- Currency is UGX (Ugandan Shilling); phone numbers are E.164 `+256...`. Don't introduce other formats without checking.
- Web (user + admin) is **light-mode only**. Dark mode lives in the Flutter app.
- Theme tokens (orange `#F97316` family + neutrals) are documented in `THEME_TOKENS.md`. Reuse the listed values rather than introducing new shades.
- Static OTP override (`ALLOW_REVIEW_STATIC_OTP`, `REVIEW_STATIC_PHONE`, `REVIEW_STATIC_OTP`) exists for app-store review — gated by env, off in normal prod.
