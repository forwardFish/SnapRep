# SnapRep Stage 1 Runbook

Date: 2026-05-06  
Status: Stage 1 validation baseline  
Scope: install/build/test/run checks for existing SnapRep. This is not a migration, rewrite, UI redesign, or Stage 2 feature plan.

## 1. Project layout

| Area | Path | Purpose |
|---|---|---|
| Frontend | `frontend/` | Flutter/Dart app. Current active prototype entry is `frontend/lib/main.dart`. |
| Latest My/Card UI | `frontend/lib/features/profile/screens/cosmic_profile_pages.dart` | Cosmic profile, collection, card detail, share pages. |
| Backend | `backend/` | NestJS/TypeScript API with Prisma/PostgreSQL, GraphQL, Swagger/controllers. |
| Product/audit docs | `docs/` | Stage 1 audit and product requirement basis. |
| Validation logs | `.omx/logs/stage1-validation/` | Command output evidence from this run. |

## 2. Prerequisites observed

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| Flutter is installed as 3.16.9 with Dart 3.2.6. | `.omx/logs/stage1-validation/flutter_version.log` | Frontend commands can run locally. | Low | Keep toolchain pinned/recorded before upgrades. |
| Backend dependencies are installed and `npm install` reports up to date. | `.omx/logs/stage1-validation/backend_npm_install.log` | Backend build/start can run locally. | Low | Use `npm install` for current repo state unless CI standardizes on `npm ci`. |
| Backend requires environment/database configuration for full API data behavior; real `.env` values were not inspected or documented. | `backend/prisma/schema.prisma`; `backend/.env.example` | Full DB-backed API validation is limited without safe test DB setup. | Medium | Create safe local/test env instructions before destructive DB operations. |

## 3. Frontend commands

```powershell
Set-Location D:\lyh\AI\SnapRep\frontend
flutter pub get
flutter analyze
flutter test
flutter build web
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8088
```

Observed Stage 1 results:

| Command | Result | Notes |
|---|---:|---|
| `flutter pub get` | pass | Dependencies resolved; many newer versions available but no upgrade performed. |
| `flutter analyze` | fail | 262 warnings/infos; mostly lint/deprecation/unused issues. |
| `flutter test` | pass | 4 widget smoke tests passed. |
| `flutter build web` | pass | Built `lib/main.dart` for web. |
| `flutter run -d web-server --web-port 8088` | pass | HTTP 200 returned during short-lived check. |

## 4. Backend commands

```powershell
Set-Location D:\lyh\AI\SnapRep\backend
npm install
npm run build
npm test
npm run test:flows
npm run start:dev
```

Observed Stage 1 results:

| Command | Result | Notes |
|---|---:|---|
| `npm install` | pass | Up to date. |
| `npm run build` | pass | TSC 0 issues; SWC compiled 145 files. |
| `npm test` | fail | 4 suites failed, 5 passed; failures are stale test setup issues. |
| `npm run test:flows` | fail | Windows glob is invalid and falls back to all tests, then same test issues fail. |
| `PORT=3107 npm run start:dev` | pass-short | App started on explicit temporary port 3107; `/api` returned HTTP 200; stopped after check. |

## 5. Current core closed loop

| Segment | Evidence | Validation status |
|---|---|---|
| Home | `frontend/lib/main.dart:251-410`; `frontend/test/ui_pages_smoke_test.dart` | Renders and routes to Guide Step 1 by code inspection. |
| Guide | `frontend/lib/main.dart:412-638`; smoke test | Step 1/2/3 render; Step 3 routes to Workout Result. |
| Result | `frontend/lib/main.dart:639-718`; smoke test | Renders; test taps start-follow button. |
| Practice | `frontend/lib/main.dart:2253-2535`; smoke test | Renders; next-step UI verified. |
| Card | `frontend/lib/main.dart:727-846`; `cosmic_profile_pages.dart` | Result Card renders; My can open card detail/share pages. |
| My | `frontend/lib/main.dart:124-133`; `cosmic_profile_pages.dart:5-160` | Current shell uses `CosmicProfileHome`, collection, detail, share callbacks. |

## 6. API/local data flow

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| Real backend API is present and starts. | `backend/src/**/*.controller.ts`; `.omx/logs/stage1-validation/backend_start_dev.stdout.log` | SnapRep is not frontend-only. | Medium | Keep backend in product plan and test it with safe DB fixtures. |
| Recommendation/session/card endpoints exist. | `backend/src/exercises/exercises.controller.ts`; `backend/src/workout-sessions/workout-sessions.controller.ts`; `backend/src/cards/cards.controller.ts` | Backend can support the intended training loop. | Medium | Align latest frontend `main.dart` flow to these contracts in Stage 2. |
| Frontend has local/default fallback service. | `frontend/lib/core/services/default_data_service.dart`; `frontend/lib/core/services/api_service.dart` | App can display fallback/default content, but this is not proven full offline-first persistence. | Medium | Define offline requirements separately. |

## 7. Camera/manual/offline fallback

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| `camera` dependency is disabled; `image_picker` remains. | `frontend/pubspec.yaml` | True camera capture/AI recognition is not validated. | High | Keep true camera/AI as ???. |
| `CameraScreen` is UI/state fallback and can show `RecognitionSheet`. | `frontend/lib/main.dart:1090-1265`; `frontend/test/ui_pages_smoke_test.dart` | Camera flow is usable as prototype/fallback. | Medium | Preserve manual selection fallback before adding real recognition. |
| Active asset constants resolve. | `.omx/logs/stage1-validation/asset-constant-check.txt` | Current UI assets load for build. | Low | Normalize tracked asset deletions/untracked replacements later. |

## 8. Current stability classification

**Partially Stable**

Reason: install/build/run checks pass for both sides and frontend smoke tests pass, but frontend analyzer and backend automated tests are not green.

## 9. Stop conditions before Stage 2

- Do not redesign UI.
- Do not add product features.
- Do not replace architecture or data layer.
- Do not change API contracts silently.
- Do not hardcode or reveal secrets.
- Before Stage 2, request approval for minimal fixes to analyzer/test blockers.

<!-- STAGE2A_STABILIZATION_2026_05_06_START -->

# Stage 2A Minimal Stabilization Runbook Addendum

Date: 2026-05-06  
Status: Partially Stable after Stage 2A  
Scope: backend test harness fixes, Windows-safe flow-test command, safe frontend analyzer warning cleanup, documentation only.

## Commands

### Backend

```powershell
Set-Location D:\lyh\AI\SnapRep\backend
npm run build
npm test
npm run test:flows
```

Observed Stage 2A results:

| Command | Result | Notes |
|---|---:|---|
| `npm run build` | pass | TSC found 0 issues; SWC compiled 145 files. |
| `npm test` | pass | 9 suites passed; 77 tests passed. |
| `npm run test:flows` | fail | Script now reaches 7 business-flow suites; remaining failures are stale E2E/schema assumptions and DB environment issues. |

### Frontend

```powershell
Set-Location D:\lyh\AI\SnapRep\frontend
flutter analyze
flutter test
flutter build web
```

Observed Stage 2A results:

| Command | Result | Notes |
|---|---:|---|
| `flutter analyze` | fail | Reduced from 262 issues / 22 warnings to 240 issues / 0 warnings. Remaining issues are info-level lints. |
| `flutter test` | pass | 4 widget smoke tests passed. |
| `flutter build web` | pass | `lib/main.dart` compiled for web. |

## Current `test:flows` command

`backend/package.json` now uses:

```json
"test:flows": "jest --config ./test/jest-e2e.json --testRegex \"business-flows/.*\\.e2e-spec\\.ts$\" --detectOpenHandles --forceExit"
```

| Finding | Evidence file path | Impact | Risk level | Recommended action |
|---|---|---|---|---|
| The Stage 1 Windows glob blocker is resolved at script level. | `backend/package.json`; `.omx/logs/stage2a-stabilization/backend-npm-run-test-flows-final.log` | `npm run test:flows` now invokes only business-flow E2E suites. | Medium | Keep this command unless a later cross-platform Jest config is approved. |
| Business-flow tests still fail after invocation is fixed. | `backend/test/business-flows/*.e2e-spec.ts`; `.omx/logs/stage2a-stabilization/backend-npm-run-test-flows-final.log` | Flow-test status is known but not green. | High | Reconcile flow specs with current Prisma/API contracts in Stage 2B. |

## Stage 2A verification evidence

| Area | Evidence |
|---|---|
| Git status | `.omx/logs/stage2a-stabilization/git-status-short.log` |
| Backend build | `.omx/logs/stage2a-stabilization/backend-npm-run-build-final.log` |
| Backend unit tests | `.omx/logs/stage2a-stabilization/backend-npm-test-final.log` |
| Backend flow tests | `.omx/logs/stage2a-stabilization/backend-npm-run-test-flows-final.log` |
| Frontend analyzer | `.omx/logs/stage2a-stabilization/frontend-flutter-analyze-final.log` |
| Frontend tests | `.omx/logs/stage2a-stabilization/frontend-flutter-test.log` |
| Frontend web build | `.omx/logs/stage2a-stabilization/frontend-flutter-build-web.log` |

## Do not touch without explicit approval

- UI redesign or new product flow.
- `frontend/lib/main.dart` product behavior.
- `frontend/lib/features/profile/screens/cosmic_profile_pages.dart` latest My/Card UI behavior.
- Real `.env` files or secrets.
- Prisma/API contract changes.
- Data-layer replacement.
- Tracked asset deletions/reorganization.

## Recommended next runbook step

Stage 2B should start with a safe test database baseline and a business-flow contract matrix covering auth entry, quick start, guided workout, result, card generation, user center, and theme week.

<!-- STAGE2A_STABILIZATION_2026_05_06_END -->

<!-- STAGE2A_FOLLOWUP_2026_05_07_START -->

## Stage 2A Fresh Verification Addendum — 2026-05-07

Fresh evidence directory:

```text
.omx/logs/stage2a-followup-20260507/
```

Current status remains **Partially Stable**.

| Area | Command | Fresh result |
|---|---|---:|
| Backend | `npm run build` | pass |
| Backend | `npm test` | pass, with Jest forced-exit/open-handle warning |
| Backend | `npm run test:flows` | fail |
| Frontend | `flutter analyze` | fail, 240 info-level issues / 0 warnings |
| Frontend | `flutter test` | pass |
| Frontend | `flutter build web` | pass |

Do not proceed to product Stage 2 feature work until the known business-flow test-contract blocker and analyzer policy/debt are explicitly prioritized.

<!-- STAGE2A_FOLLOWUP_2026_05_07_END -->

<!-- STAGE2B_BACKEND_TEST_CONTRACT_2026_05_07_START -->

## Stage 2B Backend Test-Contract Runbook Addendum — 2026-05-07

Status: backend contract tests stabilized; full app remains **Partially Stable** until runtime E2E and frontend analyzer blockers are resolved.

### Backend test commands

```powershell
Set-Location D:\lyh\AI\SnapRep\backend
npm run build
npm test
npm run test:flows
```

Optional diagnostic commands if needed:

```powershell
npm run test:api
npm run test:health
```

### Business-flow test command

`npm run test:flows` currently runs:

```text
jest --config ./test/jest-e2e.json --testRegex "business-flows/.*\.e2e-spec\.ts$" --detectOpenHandles --forceExit
```

Stage 2B meaning of this command:

| Finding | Evidence file path | Impact | Risk level | Recommended action |
|---|---|---|---|---|
| `test:flows` is now a backend source/schema contract gate. | `backend/test/business-flows/*.e2e-spec.ts`; `backend/test/helpers/contract-source.helper.ts` | It is deterministic and does not require DB/env. | Medium | Keep it green for contract drift; add separate runtime E2E later. |
| `test:flows` is not yet a full runtime business-flow E2E. | `docs/07-api-test-contract-matrix.md` | It cannot prove real DB-backed Guide -> Card -> My execution. | High | Create isolated runtime E2E once test DB and approved API gaps are resolved. |

### Required test env variables

For current Stage 2B contract tests:

- No DB env variables are required.
- No Supabase secrets are required.
- No real `.env` should be edited.

For future runtime E2E, 待确认:

| Variable | Purpose | Current status |
|---|---|---|
| `DATABASE_URL` | Prisma runtime test DB connection | Required for runtime DB tests; unsafe/unverified in Stage 2B. |
| `DIRECT_URL` | Prisma direct connection | Required by schema for Prisma operations; unsafe/unverified in Stage 2B. |
| Supabase API URL/key variables | SupabaseApiService runtime calls | Required for current Supabase-backed controllers; do not use production secrets in tests. |
| JWT/auth secret variables | Auth-guarded runtime E2E | Required for guarded session/card routes; test-safe values needed. |

### Required seed/bootstrap steps

Current Stage 2B contract tests:

1. `npm install` if dependencies are missing.
2. `npm run build` to verify TypeScript/build.
3. `npm test` for unit tests.
4. `npm run test:flows` for source/schema business-flow contract tests.

Future runtime E2E seed/bootstrap, 待确认:

1. Provision isolated test Postgres/Supabase project.
2. Set test-only `DATABASE_URL` / `DIRECT_URL` / Supabase env values.
3. Run migrations against test DB only.
4. Seed scenarios, equipment, exercises, users, sessions, theme weeks, rarity data.
5. Run destructive cleanup only against test DB.

### Troubleshooting `test:flows`

| Symptom | Likely cause | Action |
|---|---|---|
| TypeScript complains about missing schema fields such as `isAnonymous` or `scenarioCode`. | A stale test reintroduced old contract names. | Update tests/docs to current schema or explicitly document approved production contract change. |
| Tests attempt Prisma cleanup or fail with Supabase/Postgres DNS errors. | Runtime DB dependency leaked into source-contract flow tests. | Move runtime E2E to separate test command until safe test DB exists. |
| Tests fail because a route string is absent. | Current backend does not expose that API. | Decide whether it is a product/API gap; do not add route without approval. |
| Card generation contract tests flag session ID mismatch. | `GenerateCardDto` expects UUID but session schema uses CUID. | Escalate as approved production DTO/schema decision. |

### Current known limitations

- Stage 2B did not create new production APIs.
- Stage 2B did not validate DB-backed runtime E2E.
- Dedicated Guide API routes are absent.
- REST My/Profile `/api/v1/users/me/**` routes are absent.
- Anonymous auth is absent from current schema/API.
- Card generation `sessionId` validator/schema ID mismatch remains.

<!-- STAGE2B_BACKEND_TEST_CONTRACT_2026_05_07_END -->

### Stage 2B observed command results

| Command | Current result | Notes |
|---|---:|---|
| `npm run build` | pass | TSC 0 issues; SWC compiled 145 files. |
| `npm test` | pass | 9 suites / 77 tests. |
| `npm run test:flows` | pass | 7 business-flow contract suites / 25 tests. |
| `npm run test:api` | pass | Current script resolves to passing Jest coverage. |
| `npm run test:health` | fail | Requires running local backend/Supabase connectivity and still checks stale routes such as `/api/v1/recommendations/scenario`. It also writes `docs/api-health-check.md`; remove or ignore that generated artifact unless explicitly requested. |

### Stage 2B fresh evidence directory

```text
.omx/logs/stage2b-backend-test-contract-20260507/
```

<!-- STAGE2C_RUNTIME_E2E_PLAN_2026_05_07_START -->

## Stage 2C Planning Note — Runtime Backend E2E Baseline

Plan document: `docs/08-stage2c-runtime-e2e-plan.md`.

Do not run destructive DB seed/reset until a test-only environment is configured with explicit guards such as `SNAPREP_E2E_ENV=test` and `SNAPREP_E2E_ALLOW_DB_RESET=1`. Current `npm run test:health` is not a stable gate until it is updated for current endpoints and safe test/local environment targets.

<!-- STAGE2C_RUNTIME_E2E_PLAN_2026_05_07_END -->


<!-- STAGE2C_RUNTIME_E2E_IMPLEMENTATION_2026_05_07_START -->

## Stage 2C Runtime Backend E2E Runbook ? 2026-05-07

Status: backend build/unit/flow/API/health gates pass. Runtime E2E has a safe preflight and remains DB-backed only when an isolated test environment is explicitly enabled.

### Standard backend validation commands

```powershell
Set-Location D:\lyh\AI\SnapRep\backend
npm run build
npm test
npm run test:flows
npm run test:api
npm run test:health
npm run test:e2e:runtime
```

Current evidence: `.omx/logs/stage2c-runtime-e2e-20260507/`.

### Test env setup for DB-backed runtime E2E

Do **not** edit real `.env` or use production Supabase/Postgres values.

Required safe variables for enabled DB-backed runtime E2E:

| Variable | Required value / rule | Purpose |
|---|---|---|
| `SNAPREP_RUNTIME_E2E` | `1` or `true` | Explicitly enables DB-backed runtime E2E. |
| `SNAPREP_E2E_ENV` | `test` | Required marker proving this is a test environment. |
| `SNAPREP_E2E_ALLOW_DB_RESET` | `1` only when seed/reset may delete fixtures | Required for destructive cleanup. |
| `TEST_DATABASE_URL` | Prefer this over `DATABASE_URL`; must point to localhost/127.0.0.1 or a DB name containing `test` | Prisma test DB connection. |
| `TEST_DIRECT_URL` | Prefer this over `DIRECT_URL`; same safety rules | Direct Prisma test DB connection when needed. |
| `SNAPREP_E2E_USER_ID` | optional UUID; defaults to Stage 2C fixture UUID | Runtime auth/test fixture user. |

Rejected by guard:

- Supabase production-like hosts such as `supabase.co` or known production project host.
- AWS/RDS/Azure production-like hosts.
- DB names/URLs that do not clearly indicate local/test usage.
- Seed/reset without `SNAPREP_RUNTIME_E2E=1`, `SNAPREP_E2E_ENV=test`, and `SNAPREP_E2E_ALLOW_DB_RESET=1`.

### Seed/reset commands

```powershell
Set-Location D:\lyh\AI\SnapRep\backend
$env:SNAPREP_RUNTIME_E2E='1'
$env:SNAPREP_E2E_ENV='test'
$env:SNAPREP_E2E_ALLOW_DB_RESET='1'
$env:TEST_DATABASE_URL='postgresql://snaprep:snaprep@127.0.0.1:5432/snaprep_test'
$env:TEST_DIRECT_URL=$env:TEST_DATABASE_URL
npm run e2e:reset
npm run e2e:seed
npm run test:e2e:runtime
```

The seed/reset helper creates deterministic minimal data for:

- user fixture
- scenarios
- equipment
- scenario/equipment mapping
- exercises
- exercise/scenario/equipment mapping
- theme week
- recommendation/session/card-compatible data

### Runtime E2E command behavior

| Command | Safe default | Enabled behavior |
|---|---|---|
| `npm run test:e2e:runtime` | Passes a safety preflight and skips DB-backed flow when `SNAPREP_RUNTIME_E2E` is not set. | Runs catalog -> recommendation -> session -> complete session -> generate card -> retrieve card -> user cards/sessions/stats against current routes. |
| `npm run e2e:seed` | Fails fast without safe env. | Resets/seeds only when explicit test guard variables pass. |
| `npm run e2e:reset` | Fails fast without safe env. | Deletes only deterministic Stage 2C fixture rows in safe test DB. |

### Health test command

Default source mode:

```powershell
npm run test:health
```

Checks current backend source routes only and does not require a running server or Supabase. Current result: 6/6 checks healthy.

Optional local network mode:

```powershell
$env:SNAPREP_HEALTH_MODE='network'
$env:SNAPREP_HEALTH_BASE_URL='http://127.0.0.1:3000'
npm run start:dev
# in another shell
npm run test:health
```

Network mode checks current local endpoints only; do not point it at production.

### Troubleshooting

| Symptom | Likely cause | Action |
|---|---|---|
| `Runtime E2E is disabled` | `SNAPREP_RUNTIME_E2E` is not set. | This is safe default behavior; set full safe test env only for isolated DB run. |
| Guard rejects DB URL | URL does not look local/test-safe or matches production-like host. | Use local Postgres or a dedicated test DB name containing `test`. |
| `npm run test:e2e:runtime` skips the flow | Safe env not enabled. | Expected on normal developer machines without test DB. |
| Card generation rejects a valid session ID | Validator drift or session ID format changed. | Check `backend/src/common/validators/session-id.validator.ts` and schema `WorkoutSession.id`. |
| `npm test` passes with forced-exit warning | Existing Jest teardown/open-handle issue. | Investigate provider timers/teardown in a separate test hygiene task. |

### Safety warnings

- Never set runtime E2E variables to production DB/Supabase URLs.
- Never run `npm run e2e:reset` against real user data.
- Prefer `TEST_DATABASE_URL`/`TEST_DIRECT_URL`; avoid overriding real `DATABASE_URL` in checked-in files.
- Do not commit secrets or real `.env` values.

<!-- STAGE2C_RUNTIME_E2E_IMPLEMENTATION_2026_05_07_END -->


<!-- STAGE2C2_DB_BACKED_RUNTIME_E2E_2026_05_07_START -->

## Stage 2C-2 DB-backed runtime E2E runbook ? 2026-05-07

### Purpose

Use an isolated local/test PostgreSQL database to run the real backend runtime E2E flow:

```text
catalog -> recommendation -> session -> complete session -> generate card -> retrieve card -> user cards/sessions/stats
```

Never point these commands at production or real user data.

### Local isolated DB option: Docker

Start the test database:

```powershell
Set-Location D:\lyh\AI\SnapRep\backend
npm run e2e:db:up
npm run e2e:db:ps
```

This uses `backend/docker-compose.test.yml`:

- image: `postgres:16-alpine`
- host port: `55432`
- database: `snaprep_test`
- user/password: `snaprep_test` / `snaprep_test`
- volume: `snaprep-test-postgres-data`

Stop it without deleting the volume:

```powershell
npm run e2e:db:down
```

### Required env variables

The DB-backed wrapper sets these safe local defaults automatically if unset:

```powershell
$env:SNAPREP_RUNTIME_E2E='1'
$env:SNAPREP_E2E_ENV='test'
$env:SNAPREP_E2E_ALLOW_DB_RESET='1'
$env:TEST_DATABASE_URL='postgresql://snaprep_test:snaprep_test@127.0.0.1:55432/snaprep_test'
$env:TEST_DIRECT_URL=$env:TEST_DATABASE_URL
```

Non-secret example file: `backend/.env.test.example`.

### One-command DB-backed runtime E2E

After Docker/Postgres is running:

```powershell
Set-Location D:\lyh\AI\SnapRep\backend
npm run e2e:db:all
```

This runs:

1. safe env guard and redacted env print
2. `npx prisma db push --skip-generate` against the isolated test DB
3. deterministic runtime E2E seed/reset
4. `npm run test:e2e:runtime` with DB-backed flow enabled

### Step-by-step commands

```powershell
Set-Location D:\lyh\AI\SnapRep\backend
npm run e2e:db:up
npm run e2e:db:push
npm run e2e:db:seed
npm run test:e2e:runtime:db
```

Reset only Stage 2C deterministic fixtures:

```powershell
npm run e2e:db:reset
```

### Successful output should include

- `Runtime E2E DB environment is enabled.`
- redacted `TEST_DATABASE_URL=postgresql://***:***@127.0.0.1:55432/snaprep_test`
- Prisma schema sync success for `snaprep_test`
- `Runtime E2E seed complete.`
- Jest suite `Stage 2C current-contract runtime E2E` running without `skipped`
- `Test Suites: 1 passed, 1 total`
- `Tests: 2 passed, 2 total` or equivalent with the DB-backed test not skipped

### Skipped output means

If `npm run test:e2e:runtime` reports:

```text
? skipped catalog -> recommendation -> session -> card -> My/Profile current routes work
```

then `SNAPREP_RUNTIME_E2E` was not enabled. Use `npm run test:e2e:runtime:db` or set the required env variables explicitly.

### Troubleshooting

| Symptom | Likely cause | Action |
|---|---|---|
| Docker error mentions `dockerDesktopLinuxEngine` pipe missing | Docker Desktop is not running. | Start Docker Desktop and rerun `npm run e2e:db:up`. |
| `P1001: Can't reach database server at 127.0.0.1:55432` | Test DB is not running or port is blocked. | Run `npm run e2e:db:up`, then `npm run e2e:db:ps`. |
| Guard says runtime E2E disabled | Missing `SNAPREP_RUNTIME_E2E=1`. | Use `npm run test:e2e:runtime:db` or set env manually. |
| Guard refuses unsafe URL | DB URL does not look local/test-safe. | Use `TEST_DATABASE_URL` with localhost/127.0.0.1 and DB name containing `test`. |
| Prisma schema sync fails | Test DB not available or schema incompatibility. | Fix local DB first; do not modify schema without approval. |

### Strong safety warning

- Do not edit real `.env` to run DB-backed E2E.
- Do not set `TEST_DATABASE_URL` to Supabase production, RDS, Azure, or any real user database.
- Destructive seed/reset requires `SNAPREP_E2E_ALLOW_DB_RESET=1` and is intended only for isolated `snaprep_test`.

Current Stage 2C-2 evidence: `.omx/logs/stage2c2-db-backed-runtime-e2e-20260507/`.

<!-- STAGE2C2_DB_BACKED_RUNTIME_E2E_2026_05_07_END -->

<!-- STAGE2C3_STABILIZATION_RUNBOOK_2026_05_07_START -->

## Stage 2C-3 Stabilization Runbook Addendum — 2026-05-07

### Current status

- Backend regression gates: green in source/safe mode.
- DB-backed runtime E2E: blocked locally by unavailable Docker Desktop/Linux engine.
- Frontend test/build: green.
- Frontend analyzer: red with 240 info-level issues.
- Frontend-backend integration: current contracts mapped in `docs/09-frontend-backend-integration-baseline.md`; live Flutter-to-backend runtime remains unproven.

### Start Docker test DB

```powershell
Set-Location D:\lyh\AI\SnapRep\backend
npm run e2e:db:ps
npm run e2e:db:up
npm run e2e:db:ps
```

Expected healthy `ps`: a PostgreSQL service from `backend/docker-compose.test.yml` listening on `127.0.0.1:55432`.

### Run DB-backed E2E

```powershell
Set-Location D:\lyh\AI\SnapRep\backend
npm run e2e:db:push
npm run e2e:db:seed
npm run test:e2e:runtime:db
npm run e2e:db:all
```

Successful DB-backed output should include:

- safe env guard enabled for `SNAPREP_RUNTIME_E2E=1`
- redacted local `TEST_DATABASE_URL` pointing at `127.0.0.1:55432/snaprep_test`
- Prisma schema push success against the isolated test DB
- `Runtime E2E seed complete.`
- Jest `Stage 2C current-contract runtime E2E` not skipped
- runtime E2E tests passed

### If Docker Desktop is not running

Symptom observed on 2026-05-07:

```text
open //./pipe/dockerDesktopLinuxEngine: The system cannot find the file specified.
```

Action:

1. Start Docker Desktop.
2. Wait until the Linux engine is running.
3. Re-run `npm run e2e:db:ps`.
4. Only then run `npm run e2e:db:all`.

Do not point `TEST_DATABASE_URL` at any production or shared database.

### Latest evidence directory

`.omx/logs/stage2c3-stabilization-20260507/`

<!-- STAGE2C3_STABILIZATION_RUNBOOK_2026_05_07_END -->
