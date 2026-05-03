# SnapRep Development Log

## 2026-05-03 — Stage 1 stabilization

### Scope
Only Stage 1 stabilization was executed. No Stage 2 work, UI redesign, product-direction change, new feature development, database schema change, major module removal, dependency installation beyond normal install commands, or lockfile/package-manager migration was performed.

The `backend/package.json` script edit was made under the user's explicit Stage 1 approval in this session: allowed work included "fix package scripts", and the documented blocker was the missing `migrate:up` referenced by `start:db`.

### Required roadmap input status
- Finding: `docs/04-final-redevelopment-roadmap.md` was requested but is missing from the workspace.
- Evidence file path: `docs/04-final-redevelopment-roadmap.md`
- Impact: Exact roadmap wording could not be verified from that document.
- Risk level: Medium
- Recommended action: Recreate or restore `docs/04-final-redevelopment-roadmap.md`; until then, treat the explicit user prompt and `docs/03-redevelopment-plan.md` as the Stage 1 authority. 待确认.

### Changes made
| Finding | Evidence file path | Impact | Risk level | Recommended action |
|---|---|---|---|---|
| Backend `start:db` referenced a missing `migrate:up` script. Added `migrate:up` as an alias to existing `migrate:deploy`. | `backend/package.json` | Fresh setup scripts no longer fail immediately because of a missing npm script name. | High | In Stage 2, decide the canonical DB bootstrap command and remove stale Prisma preview flags if approved. |
| Flutter analyzer scanned stale backup/copy artifacts that are not active app source. Added analyzer excludes for backup/copy artifacts and disabled full-camera file. | `frontend/analysis_options.yaml`, `frontend/lib/features/workout_guide/screens/scenario_selection_page_full_camera.dart` | Analyzer no longer blocks on inactive/disabled files while preserving those files for later audit. | Medium | In Stage 2, inventory/quarantine obsolete files explicitly instead of relying on analyzer excludes. |
| Active target-muscle card referenced a non-existent `backgroundImageUrl` getter. Updated it to use the existing `getBackgroundImageUrl()` API with the configured NestJS base URL and a color fallback if the image asset is missing. | `frontend/lib/features/workout_guide/widgets/target_muscle_selection_card.dart`, `frontend/lib/core/models/target_muscle.dart`, `frontend/lib/core/constants/app_constants.dart` | Flutter compile/analyze errors are reduced without adding a new product flow; missing backend image assets should not block rendering. | High | In Stage 2, verify asset URL contracts and replace fallback-only rendering with real approved assets. |

### Verification results
| Command / check | Result | Evidence |
|---|---|---|
| `npm ci` from `backend/` | Passed | Added 1167 packages; exit 0. |
| `npm run build` from `backend/` | Passed | Nest build: TSC found 0 issues; SWC compiled 145 files; exit 0. |
| `npm run start:dev` from `backend/` | Passed | Dev server started; log includes `Nest application successfully started`; port 3000 listening. |
| Backend main route smoke | Passed | `GET http://127.0.0.1:3000/api` returned HTTP 200 Swagger UI. |
| `flutter pub get` from `frontend/` | Passed | Dependencies resolved; exit 0. |
| `flutter analyze --no-fatal-infos --no-fatal-warnings` | Passed for blocking errors | 0 analyzer error lines; exit 0. Strict analyze still reports warnings/infos. |
| `flutter build web` from `frontend/` | Passed | Compiled `lib/main.dart` for web; exit 0. |
| `flutter run -d web-server --web-hostname 127.0.0.1 --web-port 8085` | Passed | `lib/main.dart is being served at http://127.0.0.1:8085`; port 8085 listening. |
| Frontend main route smoke | Passed | `GET http://127.0.0.1:8085/` returned HTTP 200 HTML. |

Note: a repeated `npm ci` failed once while the backend dev server was running because Windows held Prisma's `query_engine-windows.dll.node` open. After stopping only the Stage 1 backend dev process, `npm ci` and `npm run build` passed again, and the backend dev server restarted successfully.

Post-deslop regression also passed: `npm run build`, `flutter analyze --no-fatal-infos --no-fatal-warnings`, `flutter build web`, backend `/api` smoke, and frontend `/` smoke all succeeded after the changed-files cleanup pass.

### Remaining non-blocking issues
| Finding | Evidence file path | Impact | Risk level | Recommended action |
|---|---|---|---|---|
| Strict `flutter analyze` still reports many warnings/infos after blocking errors were cleared. | `frontend/lib/**`, `frontend/tools/check_chinese_strings.dart` | Code quality signal is noisy, but current web build/dev startup is not blocked. | Medium | Stage 2 should address analyzer warnings by area, not as part of Stage 1 stabilization. |
| Backend DB-backed smoke routes can fail without a verified local DB/data baseline. | `backend/src/scenarios/scenarios.controller.ts`, `backend/src/cards/cards.controller.ts`, `backend/.env` | Dev server starts, but data-dependent endpoints may return 500/unhealthy until DB/env is reconciled. | High | Stage 2 should define local DB bootstrap, seed, and health-check expectations. |
| `GET /api/v1/workout-sessions/health` returned 401 during smoke testing. | `backend/src/workout-sessions/workout-sessions.controller.ts` | Health check may be behind auth or route ordering may be misleading. | Medium | Stage 2 should audit health endpoints and auth guards. |
| Workspace contains pre-existing unrelated changes and reorganized docs paths. | `git status --short` | Stage 1 changes are mixed with prior user/workspace changes. | Medium | Review and separate commits before broader redevelopment. |
| Current `frontend/lib/main.dart` was already heavily modified before this Stage 1 run. | `frontend/lib/main.dart` | It compiles and serves, but it may not match audited canonical app wiring. | High | Stage 2 should decide whether to preserve, revert, or reconcile this file against product requirements; do not redesign without approval. 待确认. |

### Recommended next Stage 2 task
Create an endpoint/runtime contract matrix and local environment baseline: backend DB bootstrap + seed + health checks, then verify frontend-to-backend calls for the canonical guided recommendation flow.
