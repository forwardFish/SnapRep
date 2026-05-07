# SnapRep Takeover Audit

Date: 2026-05-03  
Scope: unfinished SnapRep repository takeover audit only. No implementation, refactor, dependency install, deletion, package/lock change, or business-code change was performed.

## Repository snapshot

- Root project contains `backend/`, `frontend/`, `docs/`, `.vscode/`, `.claude/`, `.omx/`, and `AGENTS.md`.
- Backend is a NestJS service using Prisma, GraphQL, Swagger, scheduled jobs, and REST controllers.
- Frontend is a Flutter app named `snaprep`.
- Existing unrelated workspace state was present before audit document writing: `.claude/settings.local.json` modified and `frontend/build.pid` untracked.

## Findings

| ID | conclusion | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|---|
| A01 | Backend project identity is still starter-template state (`nestjs-prisma-client-starter`) rather than SnapRep-owned metadata. | `backend/package.json` | Ownership, onboarding, package metadata, and automation can mislead maintainers. | Medium | After audit approval, normalize metadata to SnapRep without changing product direction. |
| A02 | Backend architecture is a NestJS monolith with modules for auth, users, scenarios, equipment, exercises, workout sessions, cards, subscription, analytics, theme weeks, challenges, and assets. | `backend/src/app.module.ts`, `backend/nest-cli.json`, `backend/package.json` | Redevelopment should continue existing module boundaries, not rewrite architecture. | Low | Keep NestJS module boundaries and audit each module contract before fixes. |
| A03 | SnapRep is a hybrid Flutter + NestJS + Supabase architecture with business flow split across mobile UI, REST/GraphQL API, and direct database access. | `frontend/pubspec.yaml`, `backend/package.json`, `backend/src/app.module.ts`, `frontend/lib/core/services/api_service.dart` | Ownership boundaries are unclear before redevelopment. | Medium | Freeze a responsibility map: NestJS-owned logic, client-direct Supabase access, and GraphQL purpose. |
| A04 | Backend exposes mixed REST namespaces plus GraphQL. | `backend/src/*/*.controller.ts`, `backend/src/gql-config.service.ts`, `backend/src/schema.graphql` | Frontend/API contract confusion is likely. | Medium | Produce an endpoint contract matrix and identify public app contracts vs compatibility paths. |
| A05 | Swagger/GraphQL config is still debug/template grade. | `backend/src/common/configs/config.ts`, `backend/src/gql-config.service.ts` | API docs and runtime debug exposure are not production-hardened. | Medium-High | Move debug/playground/swagger settings behind environment-specific config after approval. |
| A06 | Prisma schema defines the core SnapRep domain: scenarios, equipment, exercises, users, workout sessions, share cards, rarity, theme weeks, challenges, subscriptions, payments, and daily usage. | `backend/prisma/schema.prisma` | Schema is the strongest source of domain intent. | Low | Use schema as the domain map, then validate each model against active APIs and frontend use. |
| A07 | Backend persistence is in transition: Prisma is bootstrapped, but some modules bypass through Supabase REST because of DB connection/client issues. | `backend/src/app.module.ts`, `backend/src/common/services/supabase-api.service.ts`, `backend/src/equipment/equipment.controller.ts`, `backend/src/subscription/subscription.controller.ts` | Business rules and consistency can diverge by module. | High | Choose a canonical data-access path per module and treat Supabase bypasses as temporary debt unless explicitly approved. |
| A08 | Auth registration/login and some GraphQL user/post flows are explicitly disabled. | `backend/src/auth/auth.service.ts`, `backend/src/posts/posts.resolver.ts`, `backend/src/users/users.resolver.ts` | Account creation/login and related GraphQL flows are not production-ready. | Critical | Audit Prisma/schema blockers, then restore approved auth/user flows with tests. |
| A09 | Backend bootstrap script is broken: `start:db` calls missing `migrate:up`. | `backend/package.json` | Fresh development setup can fail during DB initialization. | High | After approval, replace with existing Prisma migration commands or add the missing script. |
| A10 | Backend runtime versions are inconsistent: docs say Node 18+, `.node-version` is 18.16.1, Docker uses Node 16. | `backend/README.md`, `backend/.node-version`, `backend/Dockerfile` | Local, CI, and container behavior can diverge. | High | Standardize Node version across docs, Docker, local tooling, and CI. |
| A11 | Backend package manager ownership is unclear because both npm and yarn lockfiles exist. | `backend/package-lock.json`, `backend/yarn.lock` | Contributors can install different dependency trees. | Medium | Choose one package manager after audit approval; remove the other lockfile only with explicit approval. |
| A12 | Frontend is Flutter, but routing uses `MaterialApp.routes` while `go_router` is installed. | `frontend/pubspec.yaml`, `frontend/lib/main.dart`, `frontend/lib/routes/app_routes.dart` | Routing strategy is unclear and dependency noise exists. | Medium | Decide canonical routing strategy before route fixes. |
| A13 | Frontend auth/data flow is split between anonymous Supabase sessions, saved JWT tokens, direct table CRUD, and backend calls. | `frontend/lib/features/splash/splash_screen.dart`, `frontend/lib/core/services/supabase_service.dart`, `frontend/lib/core/services/token_service.dart`, `frontend/lib/core/services/api_service.dart` | Session and authorization behavior can become inconsistent. | High | Define one explicit auth/data contract and forbid unclear direct client writes. |
| A14 | Production frontend configuration is unfinished. | `frontend/lib/core/constants/app_constants.dart` | Production builds are not deployable as-is. | High | Define staging/production config and secret handling before release work. |
| A15 | Google sign-in is planned/named but disabled. | `frontend/lib/core/services/google_auth_service.dart`, `frontend/pubspec.yaml`, `frontend/lib/features/auth/screens/google_login_page.dart` | Auth UI/product expectations can mislead users and implementers. | Medium | Mark Google OAuth as 待确认 and restore or remove/rename only after approval. |
| A16 | Camera/AI recognition path is incomplete or disabled. | `frontend/pubspec.yaml`, `frontend/lib/routes/app_routes.dart`, `frontend/lib/features/workout_guide/screens/scenario_selection_page_full_camera.dart` | A differentiating product flow is unreliable. | High | Decide whether AI recognition is phase-1 scope; if deferred, quarantine it from active flows. |
| A17 | Workout execution navigation appears miswired: professional workout video navigation builds `ModernWorkoutResultPage`. | `frontend/lib/routes/app_routes.dart` | Start-workout navigation can loop back to results rather than execution. | High | Verify call sites and route to the intended execution screen after approval. |
| A18 | Some frontend quick-select presets use backend-unsupported intent enum values such as `LIGHT_CARDIO`. | `frontend/lib/routes/app_routes.dart`, `backend/prisma/schema.prisma`, `backend/src/exercises/dto/exercise-recommendation.dto.ts` | Preset recommendation requests can fail validation or behave unpredictably. | High | Create a shared enum contract and audit hardcoded payloads. |
| A19 | Frontend and backend endpoint contracts are inconsistent for AI/calendar/subscription/challenges/recommended exercise paths. | `frontend/lib/core/services/api_service.dart`, `frontend/lib/core/services/subscription_service.dart`, `frontend/lib/core/services/challenges_service.dart`, `frontend/lib/core/services/recommended_exercises_service.dart`, `backend/src/*/*.controller.ts` | Runtime flows can fail even if screens compile. | Critical | Create a frontend/backend endpoint matrix and reconcile contracts before feature development. |
| A20 | Subscription and card-generation backend contain stub/mock or placeholder behavior. | `backend/src/subscription/google-play.service.ts`, `backend/src/cards/services/card-generator.service.ts` | Monetization and post-workout reward flows may give false confidence. | High | Mark integrations incomplete and replace with verified provider integrations after approval. |
| A21 | Android release build is currently blocked. | `frontend/build.log`, `frontend/build-output.log` | Android production release cannot be trusted from current shell. | Critical | Re-baseline Android project shell against a current Flutter project, then reapply SnapRep config carefully. |
| A22 | Android build config is fragile and uses insecure HTTP mirrors plus conflicting forced AndroidX versions. | `frontend/android/settings.gradle`, `frontend/android/build.gradle`, `frontend/android/app/build.gradle` | Builds are environment-sensitive, less secure, and hard to reproduce. | High | Restore standard repositories and consolidate dependency version strategy after approval. |
| A23 | Workspace contains many backup/generated/duplicate artifacts. | `backend/_backup_old_versions/`, `backend/dist/`, `frontend/android_backup/`, `frontend/lib/features/*/backup/`, `frontend/temp/` | Takeover scope is noisy; stale code may be inspected or shipped by mistake. | Medium | Inventory authoritative vs obsolete artifacts, then quarantine/remove only after explicit approval. |
| A24 | Sensitive credential-bearing files exist in the workspace; tracking/history is 待确认. | `backend/.env`, `backend/keys/google-play-service-account.json`, `frontend/android_backup/key.properties`, `frontend/android_backup/local.properties`, `frontend/android_backup/snaprep-upload-keystore.jks` | Secret exposure could require rotation and cleanup. | Critical | Verify git tracking/history, rotate exposed secrets, and move secrets to secure secret management. |
| A25 | Frontend test coverage is minimal. | `frontend/test/widget_test.dart` | Future fixes have weak regression protection. | Medium | After approval, add smoke tests for splash/home, guided flow, workout result/start, and profile. |
| A26 | Existing docs are extensive but may be stale or aspirational. | `docs/API.md`, `docs/项目完成状态报告.md`, `docs/前端页面路由.md`, `docs/测试框架诊断报告.md`, `backend/README.md` | Planning from docs alone can overestimate completion. | High | Treat prior docs as input; validate every claim against active code and runtime evidence. |

<!-- STAGE1_VALIDATION_2026_05_06_START -->

## Stage 1 validation-first takeover update ? 2026-05-06

Status: **Partially Stable**  
Scope: validation/install/build/test/run audit only; no business-code fix, no UI redesign, no Stage 2 feature development.  
Generated: 2026-05-06T22:21:26+08:00

### Commands executed

| Command | Result | Evidence |
|---|---:|---|
| `git status --short` | pass, dirty tree already present | `.omx/logs/stage1-validation/git_status_short.log` |
| `flutter --version` | pass; Flutter 3.16.9 / Dart 3.2.6 | `.omx/logs/stage1-validation/flutter_version.log` |
| `cd frontend; flutter pub get` | pass | `.omx/logs/stage1-validation/frontend_flutter_pub_get.log` |
| `cd frontend; flutter analyze` | fail: 262 warnings/infos | `.omx/logs/stage1-validation/frontend_flutter_analyze.log` |
| `cd frontend; flutter test` | pass: 4 tests passed | `.omx/logs/stage1-validation/frontend_flutter_test.log` |
| `cd frontend; flutter build web` | pass | `.omx/logs/stage1-validation/frontend_flutter_build_web.log` |
| `cd backend; npm install` | pass: up to date | `.omx/logs/stage1-validation/backend_npm_install.log` |
| `cd backend; npm run build` | pass: TSC 0 issues, SWC compiled 145 files | `.omx/logs/stage1-validation/backend_npm_run_build.log` |
| `cd backend; npm test` | fail: 4 suites failed, 5 passed | `.omx/logs/stage1-validation/backend_npm_test.log` |
| `cd backend; npm run test:flows` | fail: Windows glob invalid; falls back to all tests and fails | `.omx/logs/stage1-validation/backend_npm_run_test_flows.log` |
| short `PORT=3107 npm run start:dev` | pass: HTTP 200 on `127.0.0.1:3107/api`; stopped after check | `.omx/logs/stage1-validation/command-summary-runchecks.txt` |
| short `flutter run -d web-server --web-port 8088` | pass: HTTP 200 on `127.0.0.1:8088`; stopped after check | `.omx/logs/stage1-validation/command-summary-runchecks.txt` |

### Findings

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| SnapRep is currently **Partially Stable**, not fully stable: frontend tests/build/run pass, backend install/build/run pass, but frontend analyzer and backend tests fail. | `.omx/logs/stage1-validation/command-summary-frontend.txt`; `.omx/logs/stage1-validation/command-summary-backend.txt`; `.omx/logs/stage1-validation/command-summary-runchecks.txt` | Development can continue, but CI-quality acceptance is blocked until analyzer/test debt is handled. | High | Treat Stage 2 entry as conditional: first fix test/analyzer blockers with minimal scoped changes. |
| Actual frontend stack is Flutter/Dart, with Provider/local StatefulWidget patterns; latest active prototype entry is `frontend/lib/main.dart`. | `frontend/pubspec.yaml`; `frontend/lib/main.dart:7-28`; `frontend/lib/main.dart:112-175` | Prevents mistaken migration assumptions and clarifies the active UI surface. | Medium | Keep Stage 1 docs grounded in `main.dart`; decide in Stage 2 whether to keep single-file prototype or reconcile with modular pages. |
| Latest My/Card visual implementation is imported from `frontend/lib/features/profile/screens/cosmic_profile_pages.dart` and wired into `AppShell`. | `frontend/lib/main.dart:5`; `frontend/lib/main.dart:124-133`; `frontend/lib/features/profile/screens/cosmic_profile_pages.dart:5-160` | My/Card requirements should use cosmic profile pages as current UI baseline. | Medium | Preserve current UI; plan a Stage 2 integration/ownership decision rather than redesign. |
| SnapRep has both a real backend/API and frontend local/default fallback layers. | `backend/src/app.module.ts`; `backend/prisma/schema.prisma`; `frontend/lib/core/services/api_service.dart`; `frontend/lib/core/services/default_data_service.dart` | Product validation must cover both API routes and local fallback behavior; neither side alone is the whole product. | High | Document dual-mode reality; in Stage 2 align the latest UI flow with backend recommendation/session/card APIs. |
| Backend starts and maps recommendation, workout-session, card, challenge, asset, analytics, theme-week, GraphQL routes. | `.omx/logs/stage1-validation/backend_start_dev.stdout.log`; `backend/src/exercises/exercises.controller.ts`; `backend/src/workout-sessions/workout-sessions.controller.ts`; `backend/src/cards/cards.controller.ts` | Real API surface exists and is not a placeholder, but automated tests are stale. | Medium | Prioritize backend test harness repair before contract expansion. |
| Core frontend closed loop is present and test-rendered: Home, Guide Step 1/2/3, Workout Result, Training Practice, Result Card, Profile, History, Camera. | `frontend/test/ui_pages_smoke_test.dart`; `.omx/logs/stage1-validation/frontend_flutter_test.log`; `frontend/lib/main.dart` | The product loop is usable enough for continued validation, though not all navigation is covered by end-to-end browser automation. | Medium | Add Stage 2 end-to-end flow coverage after stabilizing tests. |
| Camera behavior is currently fallback/mock-style UI: `camera` dependency is disabled, `image_picker` remains, and `CameraScreen` switches to `RecognitionSheet` in tests. | `frontend/pubspec.yaml`; `frontend/lib/main.dart:1090-1265`; `frontend/test/ui_pages_smoke_test.dart` | Do not claim real AI/camera recognition is complete. | High | Mark true camera/AI recognition as ???; keep manual selection fallback as first-class. |
| Active `main.dart` asset constants resolve successfully, but many tracked old assets are deleted and replacement assets are untracked. | `.omx/logs/stage1-validation/asset-constant-check.txt`; `frontend/pubspec.yaml:82-89`; `git status --short -- frontend/assets` | Current web build works, but repository asset hygiene/reproducibility is risky. | Medium | Stage 2 should normalize asset locations and commit/restore intended assets without deleting active UI references. |
| Backend unit/flow tests are blocked by stale test setup: empty suite, bad DTO enum import, missing `SupabaseApiService` provider mocks, and Windows glob issue in `test:flows`. | `.omx/logs/stage1-validation/backend_npm_test.log`; `.omx/logs/stage1-validation/backend_npm_run_test_flows.log`; `backend/src/equipment/equipment.dao.spec.ts`; `backend/src/scenario-equipment/scenario-equipment.dao.spec.ts`; `backend/package.json` | Backend cannot be classified stable despite build/start success. | High | Request explicit approval for minimal test-harness fixes before any feature work. |
| Required docs `docs/PRD-SnapRep.md` and `docs/UI-Design-Spec.md` were not found. | filesystem check during Stage 1; current basis docs: `docs/07-current-product-requirements-summary.md`, `docs/01-product-requirements-from-code.md`, `docs/design/claude????.md` | PRD/UI source of truth remains split. | Medium | Mark missing docs as ??? and use existing current summary/code-derived PRD/design doc as Stage 1 basis. |

### Closed-loop validation result

| loop segment | validation evidence | result |
|---|---|---|
| Home | `frontend/lib/main.dart:251-410`; `frontend/test/ui_pages_smoke_test.dart` | Rendered in widget smoke test; Home CTA routes to Guide Step 1 by code inspection. |
| Guide | `frontend/lib/main.dart:412-638`; `frontend/test/ui_pages_smoke_test.dart` | Guide Step 1/2/3 render; Step 3 routes to Workout Result by code inspection. |
| Result | `frontend/lib/main.dart:639-718`; `frontend/test/ui_pages_smoke_test.dart` | Result page renders; test taps start-follow button and reaches Training Practice. |
| Practice | `frontend/lib/main.dart:2253-2535`; `frontend/test/ui_pages_smoke_test.dart` | Training page renders; next-step control verified by widget test. |
| Card | `frontend/lib/main.dart:727-846`; `frontend/lib/features/profile/screens/cosmic_profile_pages.dart` | Result Card renders in smoke test; cosmic card detail/share pages are wired from My/Profile. |
| My | `frontend/lib/main.dart:124-133`; `frontend/lib/features/profile/screens/cosmic_profile_pages.dart:5-160` | Current AppShell uses `CosmicProfileHome` with collection/card navigation callbacks. |

### Blockers before Stable classification

1. `flutter analyze` exits 1 with 262 warnings/infos. Mostly lint/deprecation/unused issues; build still passes.
2. `npm test` exits 1. Backend test suite failures are existing test-harness/staleness issues.
3. `npm run test:flows` exits 1. The Windows glob is invalid and runs all tests instead.
4. Dirty working tree predates this validation and includes modified `frontend/lib/main.dart`, `frontend/pubspec.yaml`, deleted old assets, untracked replacement assets, untracked `cosmic_profile_pages.dart`, and untracked smoke test.
5. True camera/AI recognition is ???; current verified behavior is UI fallback/manual-style recognition sheet.
<!-- STAGE1_VALIDATION_2026_05_06_END -->
