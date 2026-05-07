# SnapRep Stage 2C Runtime Backend E2E Baseline Plan

Date: 2026-05-07  
Scope: planning only for backend runtime E2E baseline after Stage 2B.  
Status: no production code, test code, package, schema, frontend, lockfile, or `.env` changes are made by this plan.

## 1. Current backend stability status

| Area | Current status | Evidence | Interpretation |
|---|---:|---|---|
| Backend build | Pass | `.omx/logs/stage2b-backend-test-contract-20260507/backend-npm-run-build-post-deslop.log` | TypeScript/build is stable for current backend source. |
| Backend unit tests | Pass, 9 suites / 77 tests | `.omx/logs/stage2b-backend-test-contract-20260507/backend-npm-test-post-deslop.log` | Unit regression gate is green. |
| Backend business-flow contract tests | Pass, 7 suites / 25 tests | `.omx/logs/stage2b-backend-test-contract-20260507/backend-npm-run-test-flows-post-deslop.log` | Current source/schema contracts are documented and tested; not full runtime E2E. |
| Backend API test command | Pass | `.omx/logs/stage2b-backend-test-contract-20260507/backend-npm-run-test-api-post-deslop.log` | Current script resolves to passing Jest coverage. |
| Backend health check | Fail | `.omx/logs/stage2b-backend-test-contract-20260507/backend-npm-run-test-health.log`; `backend/scripts/api-health-checker.js` | Health checker requires running local/Supabase services and still checks stale endpoints. |
| Production code changed in Stage 2B | No | `docs/05-development-log.md`; `docs/07-api-test-contract-matrix.md` | Stage 2B was test/docs-only. |
| Runtime E2E readiness | Not ready | `docs/07-api-test-contract-matrix.md` | Needs safe test DB/env/seed and approved decisions for contract gaps. |

Overall classification: **Partially Stable**. Backend source builds and contract tests pass, but DB-backed runtime E2E is not yet safe or complete.

## 2. Remaining blockers table

| ID | Blocker | Classification | Root cause | Must fix now for runtime E2E? | Can defer? | Production code change required? | Schema migration required? | API contract decision required? | Recommended strategy |
|---|---|---|---|---:|---:|---:|---:|---:|---|
| B1 | Isolated runtime test DB/env missing | env/infra issue | Current tests/scripts can point at configured Supabase/Postgres and previously hit `ENOTFOUND tenant/user postgres.tvjcmleckqovnieuexgu not found`. | Yes | No | No | No | Yes, for environment policy | Create explicit test-only env strategy with `SNAPREP_E2E_ENV=test`, `SNAPREP_E2E_ALLOW_DB_RESET=1`, and `TEST_DATABASE_URL`/`TEST_DIRECT_URL`; never use real `.env`. |
| B2 | Seed/reset requirement missing | test-only + env/infra issue | Runtime E2E needs scenarios/equipment/exercises/theme week/user/session/card fixtures and deterministic cleanup. | Yes | No | No | No | Yes, for seed data ownership | Add test-only seed/reset scripts gated by explicit env and test DB URL allowlist. |
| B3 | `GenerateCardDto.sessionId` UUID validator vs `WorkoutSession.id` CUID | real API/DTO contract mismatch | `backend/src/cards/dto/cards.dto.ts` uses `@IsUUID()` while `backend/prisma/schema.prisma` defines `WorkoutSession.id String @id @default(cuid())`. | Yes, if card generation is in runtime E2E | No for complete Guide->Card E2E | Yes, DTO/validator only | No, if accepting CUID | Yes | Prefer explicit `SessionId` validator supporting current CUID session IDs; do not migrate session IDs to UUID. |
| B4 | Missing dedicated `/api/v1/workout-guide/**` APIs | requires product/API decision | Current backend has catalog + recommendation + session endpoints, but no guide orchestration controller. | No for MVP runtime E2E | Yes | Only if adding new Guide API | No | Yes | For MVP, use existing catalog + `recommendations/quick` + session APIs; defer dedicated Guide API until product approves backend orchestration. |
| B5 | Missing REST `/api/v1/users/me/**` APIs | requires product/API decision | Current backend has GraphQL `me` and userId-scoped REST cards/sessions/stats, but no `/me` REST profile/settings endpoints. | No for MVP runtime E2E | Yes | Only if adding `/me` adapters | No | Yes | For immediate runtime E2E, use userId-scoped routes; for frontend integration, consider thin guarded `/me` adapters after auth model approval. |
| B6 | Missing anonymous auth route/schema | requires product/API decision | Current auth routes are `rest/v1/auth/register`, `login`, OTP, Google, refresh, me, logout; schema lacks `User.isAnonymous`. | No for backend runtime E2E if test fixture is used | Yes | Yes if product anonymous backend identity is required | Possibly, if `isAnonymous` is added | Yes | For runtime E2E, use test-only seeded user/JWT fixture; defer product anonymous auth until auth strategy is approved. |
| B7 | `npm run test:health` stale/offline checks | test-only/script issue + env/infra issue | Script checks stale routes like `/api/v1/recommendations/scenario`, hardcoded Supabase host, and assumes local server on port 3000. | Yes, if health is a required validation gate | No for runtime E2E plan | No production code | No | Yes, for what health should mean | Make health checker env-driven, current-route aware, and non-destructive; separate local server checks from external Supabase checks. |
| B8 | SupabaseApiService mixed with Prisma in runtime modules | 待确认 / env issue | Some controllers/services bypass Prisma through Supabase REST due prior DB connection issues. | Yes for deterministic E2E design | No | Prefer no production change initially | No | Yes, for canonical data path later | In runtime E2E, override/fake SupabaseApiService in tests or provision test Supabase; do not hit production Supabase. |

## 3. Decision analysis

### A. Card `sessionId` contract

| Option | Description | Pros | Cons | Migration? | Recommendation |
|---|---|---|---|---:|---|
| Option 1 | Change `GenerateCardDto.sessionId` validator to accept CUID by removing/replacing `@IsUUID()`. | Minimal; aligns with current `WorkoutSession.id`; no DB migration. | If implemented as plain string, may be too loose. | No | Acceptable but less explicit than Option 3. |
| Option 2 | Change session IDs from CUID to UUID. | Uniform UUID identity. | High risk; requires schema migration, data migration, relationship migration, test/data rewrite. | Yes | Do **not** choose for Stage 2C. |
| Option 3 | Introduce explicit `SessionId` validator/decorator supporting current CUID, optionally UUID for compatibility. | Clear contract; no schema migration; validates actual current schema; can be unit-tested. | Small production DTO/validator change requires approval. | No | **Recommended.** Safest and most explicit. |

Recommendation: **Option 3**. Implement a test-covered `SessionId` validator that accepts CUID-shaped `WorkoutSession.id` and optionally UUID if legacy clients send UUID. This is a production DTO validation change and requires approval, but no schema migration.

### B. Guide API

| Option | Description | Pros | Cons | Recommendation |
|---|---|---|---|---|
| Option 1 | Add dedicated `/api/v1/workout-guide/**` endpoints. | Backend can own multi-step guide state; aligns old aspirational tests. | Adds new product API surface; needs product semantics and frontend alignment. | Defer. |
| Option 2 | Keep current catalog + recommendation endpoints and adapt frontend/runtime E2E to them. | Minimal; uses current proven API; no production route expansion. | Frontend guide orchestration remains client-side; no backend step persistence. | **Recommended for MVP runtime E2E.** |

Recommendation: **Option 2** for MVP. Validate Guide by calling scenario/equipment catalog endpoints and `POST /api/v1/recommendations/quick`. Add dedicated Guide endpoints only after product approval.

### C. My/Profile API

| Option | Description | Pros | Cons | Recommendation |
|---|---|---|---|---|
| Option 1 | Add REST `/api/v1/users/me/**` endpoints. | Best long-term frontend ergonomics; avoids passing userId around; can use auth guard. | Production API addition; requires auth decision and tests. | Future approved integration step. |
| Option 2 | Keep current `/api/v1/users/:userId/**` routes. | No production change; current cards/sessions/stats routes already exist. | Frontend/test must know userId; weaker current-user abstraction. | **Recommended for immediate runtime E2E.** |
| Option 3 | Use GraphQL `me`. | Existing `me` resolver. | Mixed REST/GraphQL integration; less aligned with current REST card/session routes. | Defer unless GraphQL is chosen as product direction. |

Recommendation: **Option 2** for Stage 2C runtime E2E baseline. For later frontend integration, consider Option 1 as thin guarded adapters after auth/user identity is approved.

### D. Anonymous auth

| Option | Description | Pros | Cons | Recommendation |
|---|---|---|---|---|
| Option 1 | Add `/auth/anonymous` and schema support. | Matches old tests and guest onboarding. | Product/auth/schema decision; may require adding `isAnonymous`; risk of auth model churn. | Defer. |
| Option 2 | Keep local guest user only. | No backend auth change; frontend can remain offline/guest first. | Backend runtime E2E cannot test authenticated flows without fixture auth. | Useful product fallback, not enough for backend E2E. |
| Option 3 | Use test-only anonymous/guest user fixture and test JWT. | Enables runtime E2E without product auth changes; safe and reversible. | Does not prove production anonymous onboarding. | **Recommended for runtime E2E.** |

Recommendation: **Option 3** for Stage 2C runtime E2E. Seed a test user and issue/use a test JWT via test-only helper or current auth flow. Do not add production anonymous auth until approved.

### E. Test DB/env strategy

Recommended approach:

1. Prefer isolated local Postgres test DB first (`snaprep_test`) for Prisma-backed runtime E2E.
2. If Supabase REST-backed code paths must be exercised, use either:
   - a dedicated Supabase test project with test-only keys, or
   - Nest testing-module overrides/fakes for `SupabaseApiService` in E2E tests.
3. Never use real `.env` for E2E. Use one of:
   - `.env.test.example` committed with placeholder names only,
   - local untracked `.env.test`, or
   - CI secret variables scoped to test environment.
4. Required guard variables:
   - `SNAPREP_E2E_ENV=test`
   - `SNAPREP_E2E_ALLOW_DB_RESET=1`
   - `TEST_DATABASE_URL`
   - `TEST_DIRECT_URL`
   - `TEST_JWT_SECRET` or equivalent test-only auth secret
   - `TEST_SUPABASE_URL` / `TEST_SUPABASE_ANON_KEY` only if a test Supabase project is approved.
5. Accident prevention:
   - Reset scripts must refuse to run unless `SNAPREP_E2E_ALLOW_DB_RESET=1`.
   - Reset scripts must reject URLs containing known production Supabase hosts.
   - Reset scripts must require database name or URL to include `test` or `snaprep_test`.
   - Log target host/database name, but never log passwords or secret values.

## 4. Safest Stage 2C implementation path

Recommended direction: split Stage 2C implementation into two lanes.

### Lane 1 — Test infra and current-contract runtime baseline, minimal production risk

1. Add test-only env loading and guard helper.
2. Add test-only seed/reset helper for scenarios, equipment, exercises, one test user, one active theme week.
3. Add runtime E2E tests that use current backend contracts only:
   - `GET /rest/v1/scenarios`
   - `GET /rest/v1/equipment`
   - `POST /api/v1/recommendations/quick`
   - `POST /api/v1/workout-sessions` or `from-recommendation`
   - complete session endpoint
   - `POST /api/v1/cards/generate` after card `sessionId` decision is approved
   - `GET /api/v1/users/:userId/sessions`
   - `GET /api/v1/users/:userId/cards`
4. Update `api-health-checker.js` or add a new health checker that is current-route aware and env-driven.
5. Do not add Guide `/workout-guide/**`, My `/me/**`, or anonymous auth APIs in this lane.

### Lane 2 — Approved small production contract fix

1. Implement Option 3 card `SessionId` validator if approved.
2. Add focused unit tests for accepted CUID session IDs and rejected invalid IDs.
3. Re-run build/unit/contract/runtime E2E.

### Deferred product/API decisions

- Dedicated Guide API: defer unless product wants backend-owned guide state.
- REST My `/me/**`: defer until auth/current-user strategy is approved.
- Anonymous backend auth: defer until guest-account semantics and schema are approved.
- Session ID UUID migration: do not do.

## 5. Safe implementation order

| Order | Step | Type | Why first/now | Production change? | Rollback |
|---:|---|---|---|---:|---|
| 0 | Confirm approval for Stage 2C implementation scope and whether card `SessionId` validator is allowed. | approval gate | Avoid silent production contract change. | No | N/A |
| 1 | Add test-only env guard and `.env.test.example` placeholders. | test/infra | Prevent production DB accidents before any reset/seed. | No | Delete helper/example. |
| 2 | Add test-only seed/reset scripts/helpers with hard safety checks. | test/infra | Runtime E2E needs deterministic data. | No | Delete scripts/helpers; drop local test DB. |
| 3 | Add current-contract runtime E2E using existing routes and seeded test user. | test-only | Proves current backend runtime without adding features. | No | Revert test files. |
| 4 | Update/fix health checker to current endpoints and env-driven hosts, or add `test:health:local`. | test/script | Makes health command meaningful and non-stale. | No, unless package script is changed | Revert script/package change. |
| 5 | Implement approved `SessionId` validator for card generation. | small production DTO validation | Required for card generation with current CUID sessions. | Yes | Revert validator/DTO/tests. |
| 6 | Add card generation runtime E2E after validator fix. | test-only | Completes Session -> Card leg. | No | Revert test file. |
| 7 | Re-run full validation and document remaining product/API decisions. | validation/docs | Confirms no regression. | No | N/A |

## 6. Validation commands

Required local validation after Stage 2C implementation:

```powershell
Set-Location D:\lyh\AI\SnapRep\backend
npm run build
npm test
npm run test:flows
npm run test:api
npm run test:health
```

Runtime E2E command to add or document in implementation:

```powershell
# proposed; exact script name to be created in implementation
$env:SNAPREP_E2E_ENV='test'
$env:SNAPREP_E2E_ALLOW_DB_RESET='1'
$env:TEST_DATABASE_URL='postgresql://.../snaprep_test'
$env:TEST_DIRECT_URL='postgresql://.../snaprep_test'
npm run test:e2e:runtime
```

Manual verification if script is not yet added:

1. Start backend against test env only.
2. Verify `GET /api` returns Swagger/HTTP 200.
3. Verify catalog endpoints return seeded scenarios/equipment.
4. Call quick recommendation with seeded catalog values.
5. Create and complete a workout session with seeded user/exercises.
6. Generate/retrieve card only after `SessionId` validator fix is approved and implemented.
7. Retrieve user sessions/cards/stats by seeded test user ID.

## 7. Rollback strategy

Planning rollback:

```powershell
git checkout -- docs/08-stage2c-runtime-e2e-plan.md docs/05-development-log.md docs/06-runbook.md
```

Future implementation rollback:

| Area | Rollback |
|---|---|
| Test env helper | Revert helper files and `.env.test.example`; remove local untracked `.env.test`. |
| Seed/reset scripts | Revert scripts; drop only the isolated `snaprep_test` database/container. |
| Runtime E2E tests | Revert test files and package script if added. |
| Health checker | Revert `backend/scripts/api-health-checker.js` or new health script/package entry. |
| `SessionId` validator | Revert validator, DTO decorator changes, and focused tests. No DB migration rollback needed if Option 3 is used. |
| Accidental generated docs | Remove generated health reports unless explicitly approved. |

Never roll back by deleting or resetting real production databases. Only isolated test DB/container may be dropped.

## 8. Exact Stage 2C implementation prompt to run next

```text
$ralph "SnapRep Stage 2C runtime backend E2E baseline implementation.

This is NOT a migration, rewrite, UI redesign, frontend work, or new product feature development.

Goal:
Implement the approved Stage 2C runtime backend E2E baseline from docs/08-stage2c-runtime-e2e-plan.md.

Must read first:
- AGENTS.md
- docs/05-development-log.md
- docs/06-runbook.md
- docs/07-api-test-contract-matrix.md
- docs/08-stage2c-runtime-e2e-plan.md
- backend/package.json
- backend/prisma/schema.prisma
- backend/src/
- backend/test/

Allowed implementation scope:
1. Add test-only env guard and seed/reset helpers for an isolated test DB.
2. Add or update test-only runtime E2E tests using current backend contracts only.
3. Update health checker or add a test-health script so it checks current endpoints and test/local env safely.
4. Implement the approved Option 3 card SessionId validator that accepts current CUID session IDs and rejects invalid IDs.
5. Add focused tests for the SessionId validator.
6. Update docs/05-development-log.md and docs/06-runbook.md.

Forbidden:
- Do not add dedicated /api/v1/workout-guide/** routes.
- Do not add /api/v1/users/me/** routes.
- Do not add /auth/anonymous or User.isAnonymous.
- Do not change Prisma schema or migrate IDs.
- Do not touch frontend files.
- Do not edit real .env or hardcode secrets.
- Do not use production DB/Supabase in tests.

Safety requirements:
- Reset/seed must refuse to run unless SNAPREP_E2E_ENV=test and SNAPREP_E2E_ALLOW_DB_RESET=1.
- Reset/seed must reject URLs that do not clearly target a test database.
- Log database host/name only, never secrets.

Validation:
Run and document:
- git status --short
- cd backend; npm run build
- cd backend; npm test
- cd backend; npm run test:flows
- cd backend; npm run test:api
- cd backend; npm run test:health
- cd backend; npm run test:e2e:runtime or the documented runtime E2E command

Stop and document, do not implement, if any required step would touch frontend, real .env, production DB, Prisma schema migration, Guide API, My /me API, or anonymous auth."
```

## 9. Summary recommendation

Recommended Stage 2C direction:

1. Fix test infra first: isolated test DB/env, seed/reset, safety guards.
2. Keep MVP runtime E2E on current backend contracts.
3. Approve and implement only the small `SessionId` validator production DTO fix because it aligns validation with the existing schema and avoids migration.
4. Defer Guide API, My `/me` API, and anonymous auth to explicit product/API approval tasks.
5. Make health checks current-route aware and env-driven before using `npm run test:health` as a gate.


<!-- STAGE2C_RUNTIME_E2E_IMPLEMENTATION_STATUS_2026_05_07_START -->

## 10. Stage 2C implementation status ? 2026-05-07

Implemented baseline:

- Safe runtime E2E env guard and deterministic seed/reset helpers.
- Current-contract runtime E2E command: `npm run test:e2e:runtime`.
- Current-route health checker: `npm run test:health` passes in source mode.
- Approved Option 3 `SessionId` validator: card DTO accepts current CUID session IDs.
- API contract script stabilization: `npm run test:api` now runs current API contract tests on Windows.

Validation evidence: `.omx/logs/stage2c-runtime-e2e-20260507/`.

Remaining implementation prerequisite: isolated test DB/env is still required before enabling the DB-backed runtime E2E flow.

<!-- STAGE2C_RUNTIME_E2E_IMPLEMENTATION_STATUS_2026_05_07_END -->


<!-- STAGE2C2_DB_BACKED_RUNTIME_E2E_STATUS_2026_05_07_START -->

## 11. Stage 2C-2 DB-backed runtime E2E status ? 2026-05-07

Implemented:

- `backend/docker-compose.test.yml` local-only Postgres helper.
- `backend/.env.test.example` non-secret test env example.
- `backend/scripts/runtime-e2e-db.js` safe wrapper for DB-backed runtime E2E.
- npm scripts: `e2e:db:up`, `e2e:db:ps`, `e2e:db:down`, `e2e:db:push`, `e2e:db:seed`, `e2e:db:reset`, `e2e:db:all`, `test:e2e:runtime:db`.

Attempted:

- Docker startup failed because the Docker Desktop/Linux engine was unavailable.
- DB-backed E2E failed because no PostgreSQL server was reachable at `127.0.0.1:55432`.

Next exact command after starting Docker Desktop:

```powershell
Set-Location D:\lyh\AI\SnapRep\backend
npm run e2e:db:up
npm run e2e:db:all
```

Evidence: `.omx/logs/stage2c2-db-backed-runtime-e2e-20260507/`.

<!-- STAGE2C2_DB_BACKED_RUNTIME_E2E_STATUS_2026_05_07_END -->

<!-- STAGE2C3_STABILIZATION_STATUS_2026_05_07_START -->

## 12. Stage 2C-3 stabilization status — 2026-05-07

Result: **Partially Stable**.

Verified:

- Backend build/test/flow/API/health/runtime-preflight gates pass.
- Frontend `flutter test` and `flutter build web` pass.
- Docker/test DB blocker is exact and reproducible.
- Frontend-backend integration baseline is documented in `docs/09-frontend-backend-integration-baseline.md`.

Not complete:

| Finding | Evidence file path | Impact | Risk level | Recommended action |
|---|---|---|---|---|
| DB-backed runtime E2E did not run to success because Docker Desktop/Linux engine is unavailable. | `.omx/logs/stage2c3-stabilization-20260507/backend-e2e-db-up.log` | Runtime DB-backed path remains unverified in this environment. | High | Start Docker Desktop and rerun `npm run e2e:db:all`. |
| Frontend analyzer remains red with 240 issues. | `.omx/logs/stage2c3-stabilization-20260507/frontend-flutter-analyze.log` | Frontend baseline is only partially green. | Medium | Run a separate scoped analyzer cleanup pass; avoid UI redesign and broad refactor. |
| Flutter-to-backend live runtime integration is mapped but not proven. | `docs/09-frontend-backend-integration-baseline.md`; `frontend/lib/core/services/api_service.dart`; `backend/test/e2e/runtime-current-contract.e2e-spec.ts` | Product/runtime integration risk remains. | High | After DB availability, run backend locally and add a minimal service-level integration smoke if product/API decisions allow. |

Next recommended task:

1. Start Docker Desktop and run `cd backend; npm run e2e:db:all`.
2. If it passes, run the backend regression suite again.
3. Then do a narrow frontend integration contract adapter/test task focused on current userId-scoped APIs only.

<!-- STAGE2C3_STABILIZATION_STATUS_2026_05_07_END -->
