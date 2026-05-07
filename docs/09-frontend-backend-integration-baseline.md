# SnapRep Frontend-Backend Integration Baseline — Stage 2C-3

Date: 2026-05-07

Status: **baseline known, not live-verified**.

No production DB, real `.env`, Prisma migration, backend API expansion, Guide API, `/api/v1/users/me/**`, `/auth/anonymous`, product direction change, or UI redesign was performed.

## 1. Base URL/config mechanism

| Finding | Evidence file path | Impact | Risk level | Recommended action |
|---|---|---|---|---|
| Main frontend service code uses `AppConstants.nestJsApiUrl`, which resolves to `http://127.0.0.1:3000` in development and a placeholder production domain in production mode. | `frontend/lib/core/constants/app_constants.dart`; `frontend/lib/core/services/api_service.dart` | Local backend target is clear for development. Production target is not configured. | Medium | Keep local target for Stage 2C; configure production only in a later deployment task. |
| Some service classes use `ApiConfig.baseUrl = http://localhost:3000` instead of `AppConstants.nestJsApiUrl`. | `frontend/lib/core/config/api_config.dart`; `frontend/lib/core/services/equipment_service.dart`; `frontend/lib/core/services/exercise_service.dart`; `frontend/lib/core/services/challenges_service.dart` | Split config can cause inconsistent localhost behavior across platforms. | Medium | Standardize in a future safe frontend integration cleanup. |
| Supabase direct client is still part of frontend data access. | `frontend/lib/core/services/supabase_service.dart`; `frontend/lib/core/services/api_service.dart` | Backend-only local integration is not complete without auth/data-source decisions. | High | Decide whether Stage 2D should use NestJS-only APIs or preserve Supabase direct reads. |

## 2. Flow-to-contract map

| Flow | Frontend evidence | Backend evidence | Baseline result | Risk level | Recommended action |
|---|---|---|---|---:|---|
| Catalog: scenarios | `frontend/lib/core/services/api_service.dart` calls `/rest/v1/scenarios`; `frontend/lib/core/services/default_data_service.dart` has fallback data. | `backend/src/scenarios/scenarios.controller.ts`; `backend/test/e2e/runtime-current-contract.e2e-spec.ts`; `backend/test/api-integration/all-endpoints.e2e-spec.ts` | Contract exists and backend tests pass. | Medium | Keep current `/rest/v1/scenarios`; do not add Guide API. |
| Catalog: equipment | `frontend/lib/core/services/api_service.dart` and `frontend/lib/core/services/equipment_service.dart` call `/rest/v1/equipment`. | `backend/src/equipment/equipment.controller.ts`; `backend/test/e2e/runtime-current-contract.e2e-spec.ts` | Contract exists and backend tests pass. | Medium | Keep current catalog route. |
| Scenario equipment | `frontend/lib/core/services/equipment_service.dart` calls `/rest/v1/scenario-equipment/by-code/{scenarioCode}/equipment`. | `backend/src/scenario-equipment/scenario-equipment.controller.ts` | Route exists; live Flutter behavior not verified. | Medium | Include in future local integration smoke. |
| Recommendation quick | `frontend/lib/core/services/exercise_service.dart` calls `/api/v1/recommendations/quick`; `frontend/lib/core/services/api_service.dart` also has a quick recommendation method. | `backend/src/exercises/exercises.controller.ts`; `backend/test/e2e/runtime-current-contract.e2e-spec.ts` | Backend contract exists; frontend has multiple callers and response parsing needs live verification. | High | Prefer one current-contract adapter and verify response shape before product changes. |
| Workout session create/read/update/complete | Frontend has mixed access: direct Supabase reads/updates and backend userId-scoped history APIs. | `backend/src/workout-sessions/workout-sessions.controller.ts`; `backend/test/e2e/runtime-current-contract.e2e-spec.ts` | Backend route set exists; Flutter runtime path is not backend-only. | High | Decide data-source policy before adding a live smoke. |
| Card generation | `frontend/lib/core/services/api_service.dart` posts to `/api/v1/cards/generate`. | `backend/src/cards/cards.controller.ts`; `backend/src/cards/dto/cards.dto.ts`; `backend/test/e2e/runtime-current-contract.e2e-spec.ts` | Backend route exists; frontend request/parse shape likely needs adapter verification (`template` vs `cardTemplate`, direct card parse vs `{ success, data }`). | High | Fix in a future frontend adapter task only if approved; do not change backend contract here. |
| User cards | Frontend calls `/api/v1/users/{userId}/cards`. | `backend/src/cards/cards.controller.ts`; `backend/test/e2e/runtime-current-contract.e2e-spec.ts` | Current userId-scoped route exists. | Medium | Continue using userId-scoped route; do not add `/users/me`. |
| User sessions/stats | Frontend calls `/api/v1/users/{userId}/sessions`; recommended exercises service calls `/rest/v1/users/{userId}/stats`; backend current stats route is `/api/v1/users/{userId}/stats`. | `frontend/lib/core/services/api_service.dart`; `frontend/lib/core/services/recommended_exercises_service.dart`; `backend/src/workout-sessions/workout-sessions.controller.ts` | Sessions route aligns; stats path has at least one frontend service using stale `/rest/v1` path. | High | Align frontend to current `/api/v1/users/{userId}/stats` in a future adapter cleanup; do not add `/users/me`. |
| Auth/current user | Frontend may call `/rest/v1/auth/me` if Supabase session is unavailable. | `backend/src/auth/auth.controller.ts` | Current `/rest/v1/auth/me` exists; no anonymous auth route exists. | Medium | Use authenticated/current route only; do not add `/auth/anonymous`. |

## 3. Verification evidence

| Command | Result | Evidence |
|---|---:|---|
| `cd backend; npm run build` | PASS | `.omx/logs/stage2c3-stabilization-20260507/backend-npm-run-build.log` |
| `cd backend; npm test` | PASS, 10 suites / 80 tests | `.omx/logs/stage2c3-stabilization-20260507/backend-npm-test.log` |
| `cd backend; npm run test:flows` | PASS, 7 suites / 25 tests | `.omx/logs/stage2c3-stabilization-20260507/backend-npm-run-test-flows.log` |
| `cd backend; npm run test:api` | PASS, 1 suite / 10 tests | `.omx/logs/stage2c3-stabilization-20260507/backend-npm-run-test-api.log` |
| `cd backend; npm run test:health` | PASS, source mode 6/6 | `.omx/logs/stage2c3-stabilization-20260507/backend-npm-run-test-health.log` |
| `cd backend; npm run test:e2e:runtime` | PASS safe preflight; DB-backed test skipped by default | `.omx/logs/stage2c3-stabilization-20260507/backend-npm-run-test-e2e-runtime.log` |
| `cd frontend; flutter analyze` | FAIL, 240 info-level issues | `.omx/logs/stage2c3-stabilization-20260507/frontend-flutter-analyze.log` |
| `cd frontend; flutter test` | PASS, 4 tests | `.omx/logs/stage2c3-stabilization-20260507/frontend-flutter-test.log` |
| `cd frontend; flutter build web` | PASS | `.omx/logs/stage2c3-stabilization-20260507/frontend-flutter-build-web.log` |

## 4. Why no new integration smoke was added in this pass

| Finding | Evidence file path | Impact | Risk level | Recommended action |
|---|---|---|---|---|
| DB-backed backend runtime is unavailable because Docker Desktop/Linux engine is not running. | `.omx/logs/stage2c3-stabilization-20260507/backend-e2e-db-up.log` | A true Flutter-to-backend runtime smoke would not have a reliable local DB-backed backend. | High | Start Docker Desktop and run DB-backed backend first. |
| Frontend runtime currently mixes NestJS and Supabase direct data access. | `frontend/lib/core/services/api_service.dart`; `frontend/lib/core/services/supabase_service.dart` | A minimal smoke needs an explicit data-source/auth decision to avoid inventing APIs. | High | Approve a focused adapter contract task before adding smoke tests. |
| Adding `/users/me`, `/auth/anonymous`, or Guide APIs is explicitly forbidden. | User Stage 2C-3 instructions; `backend/test/api-integration/all-endpoints.e2e-spec.ts` | Missing convenience APIs cannot be filled during this stabilization pass. | High | Continue with existing userId-scoped APIs until product/API approval. |

## 5. Remaining blockers by severity

### High

1. Docker/test DB unavailable; DB-backed runtime E2E not passed.
2. Flutter-to-backend live runtime integration not proven.
3. Frontend response adapters likely need current-contract fixes for card generation and some stats/session paths.

### Medium

1. `flutter analyze` fails with 240 info-level issues.
2. Frontend API base URL constants are split between `AppConstants` and `ApiConfig`.
3. Jest `npm test` still reports a force-exit/open-handle warning despite passing.

## 6. Next recommended task

After Docker Desktop is running:

```powershell
Set-Location D:\lyh\AI\SnapRep\backend
npm run e2e:db:up
npm run e2e:db:all
npm run build
npm test
npm run test:flows
npm run test:api
npm run test:health
npm run test:e2e:runtime
```

Then run a separate, narrow frontend integration adapter task that:

- uses existing userId-scoped backend APIs only;
- does not add `/users/me`, `/auth/anonymous`, or Guide APIs;
- does not redesign UI;
- adds a minimal service-level smoke only after the backend DB-backed path is green.
