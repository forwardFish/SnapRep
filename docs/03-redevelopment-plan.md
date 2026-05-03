# SnapRep Redevelopment Plan

Date: 2026-05-03  
Status: proposal only. Implementation requires explicit approval after audit document review.

## Guardrails

- Continue SnapRep itself; do not migrate, rename, or rewrite into another product.
- No feature development until audit documents are approved.
- Prefer smallest safe fixes after approval.
- Validate with evidence before changing behavior.
- Mark unclear scope as 待确认.

## Proposed plan

| ID | conclusion | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|---|
| D00 | Audit documents identify blockers but do not authorize implementation. | `AGENTS.md`, `docs/00-project-audit.md`, `docs/01-product-requirements-from-code.md`, `docs/02-risk-register.md` | Work must not proceed into code changes without explicit approval. | Critical | Product/engineering owner reviews docs and approves a phase-1 scope matrix. |
| D01 | Runtime setup is inconsistent across Node docs, `.node-version`, Docker, and Flutter Android shell. | `backend/README.md`, `backend/.node-version`, `backend/Dockerfile`, `frontend/build.log`, `frontend/android/settings.gradle` | Contributors cannot reproduce a stable environment. | High | Standardize Node version, Flutter version, Android Gradle baseline, and package-manager choice. |
| D02 | DB bootstrap command calls missing `migrate:up`. | `backend/package.json` | Fresh setup fails. | High | Replace with existing Prisma migration/generate/seed commands or add the missing script after approval. |
| D03 | Backend has npm and yarn lockfiles. | `backend/package-lock.json`, `backend/yarn.lock` | Dependency drift can invalidate test results. | Medium | Choose one package manager and remove the other lockfile only after approval. |
| D04 | Credential-bearing files are present in workspace; tracking/history is 待确认. | `backend/.env`, `backend/keys/google-play-service-account.json`, `frontend/android_backup/key.properties`, `frontend/android_backup/snaprep-upload-keystore.jks` | Potential credential exposure blocks safe release. | Critical | Verify git history/tracking, rotate exposed credentials, and replace local files with secret-manager/env workflows. |
| D05 | Frontend calls multiple endpoints that do not match backend controllers. | `frontend/lib/core/services/api_service.dart`, `frontend/lib/core/services/subscription_service.dart`, `frontend/lib/core/services/challenges_service.dart`, `backend/src/*/*.controller.ts` | Runtime behavior cannot be trusted until contracts are reconciled. | Critical | Create a matrix of every frontend call, backend route, auth requirement, request shape, response shape, and status. |
| D06 | Backend exposes broad auth endpoints, auth service is disabled, and Google sign-in is disabled in frontend. | `backend/src/auth/auth.controller.ts`, `backend/src/auth/auth.service.ts`, `frontend/lib/core/services/google_auth_service.dart`, `frontend/lib/features/auth/screens/google_login_page.dart` | User identity behavior is unclear. | High | Decide approved auth methods: anonymous, email/password, OTP, Google OAuth, or subset. |
| D07 | Recommendation and session lifecycle are core flows but span multiple providers/controllers. | `frontend/lib/core/providers/workout_guide_provider.dart`, `frontend/lib/core/services/api_service.dart`, `backend/src/exercises/exercises.controller.ts`, `backend/src/workout-sessions/workout-sessions.controller.ts` | Core workout flow can break if contracts drift. | High | Specify DTOs and session state transitions before UI fixes. |
| D08 | AI, challenges, theme weeks, offline-first, Google auth, and subscriptions exist in code but are unevenly implemented. | `frontend/pubspec.yaml`, `frontend/lib/routes/app_routes.dart`, `backend/src/challenges/challenges.controller.ts`, `backend/src/theme-weeks/theme-weeks.controller.ts`, `frontend/README.md` | Unbounded redevelopment can sprawl. | High | Mark each as must-have, fix-only, defer, or remove/quarantine. |
| D09 | Flutter build logs report unsupported Gradle project and failed bundle release. | `frontend/build.log`, `frontend/build-output.log`, `frontend/android/settings.gradle`, `frontend/android/build.gradle`, `frontend/android/app/build.gradle` | Release pipeline is blocked. | Critical | Generate a clean compatible Flutter Android shell, reapply SnapRep package/signing/config carefully, and verify `flutter build`. |
| D10 | Frontend contains backup/incomplete Dart files and minimal tests. | `frontend/lib/features/*/backup/`, `frontend/lib/features/workout_guide/screens/scenario_selection_page_full_camera.dart`, `frontend/test/widget_test.dart` | Future fixes lack reliable regression signal. | High | Decide active source set, quarantine stale files after approval, run analyzer, then add smoke tests. |
| D11 | Backend includes many test scripts but setup/runtime issues and disabled flows reduce confidence. | `backend/package.json`, `backend/test/`, `backend/test-*.js`, `backend/src/auth/auth.service.ts` | Existing tests may not represent production readiness. | High | Run build/test only after dependency/tooling baseline is approved; prioritize auth, recommendation, session, cards, subscription contracts. |
| D12 | Auth is a blocker for profile, history, subscription, cards, and user sessions. | `backend/src/auth/auth.service.ts`, `frontend/lib/core/services/supabase_service.dart`, `frontend/lib/main.dart` | Many downstream flows depend on stable identity. | Critical | Fix approved auth path first, with backend and frontend smoke tests. |
| D13 | Canonical user journey depends on scenario/equipment/intent/muscle selection and recommendation generation. | `frontend/lib/routes/app_routes.dart`, `frontend/lib/core/providers/workout_guide_provider.dart`, `backend/src/exercises/exercises.controller.ts` | This is the core SnapRep value proposition. | High | Fix only the canonical guided path first; defer alternate/legacy routes unless approved. |
| D14 | Execution routing appears miswired, and session lifecycle must complete before cards/history work. | `frontend/lib/routes/app_routes.dart`, `frontend/lib/features/workout_execution/screens/professional_workout_video_page.dart`, `backend/src/workout-sessions/workout-sessions.controller.ts` | Users may not complete workouts reliably. | High | Correct execution route and verify start → progress → complete → result handoff. |
| D15 | Card generation and rarity are intended, but generator behavior may be placeholder. | `backend/src/cards/cards.controller.ts`, `backend/src/cards/services/card-generator.service.ts`, `frontend/lib/features/result_card/screens/result_card_page.dart` | Retention/gamification loop is incomplete if cards are unreliable. | High | Verify generation output, storage, rarity, and share-count behavior after session completion is stable. |
| D16 | Subscription endpoints and frontend service names currently disagree. | `backend/src/subscription/subscription.controller.ts`, `frontend/lib/core/services/subscription_service.dart`, `frontend/lib/features/subscription/widgets/subscription_paywall_dialog.dart` | Premature paywall work can block core usage and create false purchase states. | High | Reconcile entitlement API, then gate only approved actions. |
| D17 | Duplicate/backup/generated files increase takeover noise. | `backend/_backup_old_versions/`, `backend/dist/`, `frontend/android_backup/`, `frontend/temp/`, `frontend/lib/features/*/backup/` | Future work may target obsolete files. | Medium | After explicit approval, move/remove obsolete artifacts and document authoritative paths. |
| D18 | Metadata and API docs still contain template/generic labels. | `backend/package.json`, `frontend/pubspec.yaml`, `backend/src/common/configs/config.ts` | Ownership remains confusing. | Medium | Update metadata/docs after functional baselines are stable. |
| D19 | Current test coverage does not protect primary flows. | `frontend/test/widget_test.dart`, `backend/package.json`, `backend/test/` | Fixes may regress silently. | Medium | Add minimal tests for auth, recommendation, session completion, card generation, and route smoke flows. |
| D20 | Critical build/auth/API risks mean new features would compound instability. | `docs/00-project-audit.md`, `docs/02-risk-register.md`, `backend/src/auth/auth.service.ts`, `frontend/build.log` | New development before stabilization would increase takeover risk. | Critical | Begin new feature work only after approval plus passing backend build/test, frontend analyze/build, and core flow smoke checks. |

## Proposed stop conditions before feature development

1. Audit docs approved.
2. Phase-1 scope matrix approved.
3. Backend setup/build/test baseline is reproducible.
4. Frontend analyze/build baseline is reproducible.
5. Auth, guided recommendation, workout execution/completion, and result/card handoff pass smoke checks.
