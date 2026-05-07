# SnapRep Backend API / Test Contract Matrix

Date: 2026-05-07  
Stage: 2B backend test-contract stabilization  
Scope: current backend source/schema/test contract for `Guide -> Recommendation -> Session -> Card -> My`. This document does not approve frontend changes, production API behavior changes, Prisma schema changes, or new features.

## Evidence basis

| Source | Role |
|---|---|
| `backend/src/exercises/exercises.controller.ts` | Recommendation API routes. |
| `backend/src/exercises/dto/exercise-recommendation.dto.ts` | Guide/recommendation request contract. |
| `backend/src/workout-sessions/workout-sessions.controller.ts` | Session create/update/complete/history/stat routes. |
| `backend/src/workout-sessions/dto/workout-session.dto.ts` | Session DTO contract. |
| `backend/src/cards/cards.controller.ts` | Result card generation/retrieval/rarity routes. |
| `backend/src/cards/dto/cards.dto.ts` | Card DTO contract. |
| `backend/src/scenarios/scenarios.controller.ts` | Guide scenario catalog. |
| `backend/src/equipment/equipment.controller.ts` | Guide equipment catalog. |
| `backend/src/theme-weeks/theme-weeks.controller.ts` | Current theme-week routes and response mapping. |
| `backend/prisma/schema.prisma` | Data model/schema source of truth. |
| `backend/test/business-flows/*.e2e-spec.ts` | Stage 2B current contract tests. |

## Stage 2B failure classification summary

| Finding | Evidence file path | Impact | Risk level | Recommended action |
|---|---|---|---|---|
| Previous business-flow tests expected removed/non-current fields: `User.isAnonymous`, `WorkoutSession.scenarioCode`, `Scenario.description/displayOrder`, `ThemeWeek.equipmentSeries/targetCount/name`. | `.omx/logs/stage2b-backend-test-contract-20260507/backend-npm-run-test-flows-fresh.log`; `backend/prisma/schema.prisma` | Tests failed before validating current backend behavior. | High | Treat as stale test contract; Stage 2B replaced them with current source/schema contract tests. |
| Previous business-flow tests expected routes that are not current backend API: `/auth/anonymous`, `/api/v1/workout-guide/**`, `/api/v1/users/me/**`, deeplink/collage/copy routes, split recommendation routes. | `.omx/logs/stage2b-backend-test-contract-20260507/backend-npm-run-test-flows-fresh.log`; `backend/src/**/*.controller.ts` | Runtime flow tests were asserting aspirational endpoints. | High | Document as production/API gaps; do not add routes in Stage 2B. |
| Previous flow tests directly used Prisma cleanup/fixtures against configured DB and hit `ENOTFOUND tenant/user postgres.tvjcmleckqovnieuexgu not found`. | `.omx/logs/stage2b-backend-test-contract-20260507/backend-npm-run-test-flows-fresh.log`; `backend/test/helpers/test-data.helper.ts` | Business-flow tests depended on unsafe external/prod-like env. | Critical | Current Stage 2B tests avoid DB access; future true E2E requires safe test DB and seed/reset. |
| Card generation DTO validates `sessionId` with `@IsUUID()` while `WorkoutSession.id` is `cuid()`. | `backend/src/cards/dto/cards.dto.ts`; `backend/prisma/schema.prisma` | Real card generation can reject valid session IDs. | High | Requires approved production DTO/API contract decision in a later task; Stage 2B only documents and tests the current mismatch. |

## 1. Guide input contract

| Item | Current contract |
|---|---|
| Scenario catalog endpoint | `GET /rest/v1/scenarios`; `GET /rest/v1/scenarios/:id`; `GET /rest/v1/scenarios/code/:code` from `backend/src/scenarios/scenarios.controller.ts`. |
| Equipment catalog endpoint | `GET /rest/v1/equipment`; `GET /rest/v1/equipment/:id`; `GET /rest/v1/equipment/code/:code`; `GET /rest/v1/equipment/category/grouped` from `backend/src/equipment/equipment.controller.ts`. |
| Dedicated guide-step API | Not implemented in current backend. `/api/v1/workout-guide/**` is a stale test expectation and production/API gap. |
| Required payload | Guide input is currently folded into `QuickRecommendationDto`; there is no separate Guide DTO. |
| Optional payload | `userId`, `intent`, `intents`, `equipment`, `equipmentCodes`, `scenario`, `scenarioCode`, `targetMuscles`, `duration`, `difficulty`, `excludeExerciseIds`, `themeWeekId`, `isOffline`, `currentStep`. |
| Validation rules | `intent/intents` must be `IntentType`; `targetMuscles` must be `PrimaryMuscle[]` and max 2; `duration` min 30 max 600; `difficulty` must be `Difficulty`; `currentStep` min 1 max 4. |
| Expected response | No guide-specific response. Recommendation endpoint returns the resulting workout recommendation shape. |
| Related DTO/model/schema | `QuickRecommendationDto`; enums `IntentType`, `Difficulty`, `PrimaryMuscle`; models `Scenario`, `Equipment`. |
| Test coverage | `backend/test/business-flows/flow-1-auth-entry.e2e-spec.ts`; `flow-2-quick-start.e2e-spec.ts`; `flow-3-guided-workout.e2e-spec.ts`. |

## 2. Recommendation contract

| Item | Current contract |
|---|---|
| Endpoint | `POST /api/v1/recommendations/quick` from `backend/src/exercises/exercises.controller.ts`. |
| HTTP status | Controller uses `@HttpCode(HttpStatus.OK)`, so current successful response is `200`, not `201`. |
| Input source | Guide selections or local/default frontend fallback can map into `QuickRecommendationDto`. |
| Recommendation rules | Implemented by `WorkoutRecommendationService.generateQuickRecommendation(dto)`; Stage 2B does not change rules. |
| Expected output shape | Controller Swagger documents `intent`, `totalDuration`, `difficulty`, `exercises[]`, and `alternatives[]`. Exercise items include id/code/name/duration/sets/difficulty/primaryMuscle/keyPoints/safetyWarnings/demoImageUrl/tags/benefits. |
| Error cases | Controller maps validation-style failures through `ResponseError` handling; details are current implementation dependent. |
| Unsupported/stale routes | `POST /api/v1/recommendations/scenario`, `POST /api/v1/recommendations/with-equipment`, and `/api/v1/ai/recognize-equipment` are not current production routes. |
| Related DTO/model/schema | `QuickRecommendationDto`; `Exercise`; `ExerciseEquipment`; `ExerciseScenario`; `Scenario`; `Equipment`. |
| Test coverage | `flow-2-quick-start.e2e-spec.ts`; `flow-4-result-page.e2e-spec.ts`. |

## 3. Workout session contract

| Item | Current contract |
|---|---|
| Create session | `POST /api/v1/workout-sessions`; guarded by `JwtAuthGuard`. |
| Create from recommendation | `POST /api/v1/workout-sessions/from-recommendation`; guarded by `JwtAuthGuard`. |
| Read session | `GET /api/v1/workout-sessions/:id`; optional `includeExercises` query. |
| Update session | `PATCH /api/v1/workout-sessions/:id`; guarded by `JwtAuthGuard`; accepts `UpdateWorkoutSessionDto`. |
| Complete session | `POST /api/v1/workout-sessions/:id/complete`; guarded by `JwtAuthGuard`; body supports `actualDuration`, `rating`, `feedback`. |
| Abandon session | `POST /api/v1/workout-sessions/:id/abandon`; guarded by `JwtAuthGuard`; body supports `reason`. |
| History retrieval | `GET /api/v1/users/:userId/sessions`; query DTO supports `status`, `fromDate`, `toDate`, `limit`, `offset`. |
| Stats retrieval | `GET /api/v1/users/:userId/stats`; query DTO supports `days`. |
| Persistence behavior | `WorkoutSession` persists `userId`, `intentType`, `scenarioId`, `targetMuscles`, `totalDuration`, `difficulty`, status/progress fields, and related `SessionExercise[]`. |
| Important schema naming | Current schema uses `scenarioId`, not `scenarioCode`. |
| Expected response | Controller wraps most session operations as `{ success: true, data, message? }`. |
| Related DTO/model/schema | `CreateWorkoutSessionDto`; `UpdateWorkoutSessionDto`; `SessionQueryDto`; `UserStatsQueryDto`; models `WorkoutSession`, `SessionExercise`. |
| Test coverage | `flow-3-guided-workout.e2e-spec.ts`; `flow-6-user-center.e2e-spec.ts`. |

## 4. Result card contract

| Item | Current contract |
|---|---|
| Generate card endpoint | `POST /api/v1/cards/generate`. |
| Card generation input | `GenerateCardDto`: `sessionId`, optional `cardTemplate`, `shareText`, `isPublic`, `specialTags`, `cityEdition`, `themeWeek`, `forceRegenerate`. |
| Card metadata | `ShareCard` persists `cardImageUrl`, `cardTemplate`, `cardData`, `rarity`, `personalStars`, `equipmentSeries`, `rarityScore`, `dataSource`, `specialTags`, `cityEdition`, `themeWeek`, `shareText`, `isPublic`, `shareCount`, `viewCount`. |
| Persistence behavior | `ShareCard.sessionId` is unique and references `WorkoutSession.id`. |
| Retrieval behavior | `GET /api/v1/cards/:id`, `GET /api/v1/cards/session/:sessionId`, `GET /api/v1/users/:userId/cards`, `GET /api/v1/cards/public`. |
| Rarity behavior | `GET /api/v1/rarity/calculate/:code`, `POST /api/v1/rarity/calculate-batch`, `GET /api/v1/rarity/ranking`, `GET /api/v1/rarity/:code/trend`. |
| Expected response | Controller wraps card routes as `{ success: true, data, message?/pagination? }`. |
| Known blocker | `GenerateCardDto.sessionId` currently has `@IsUUID()` but `WorkoutSession.id` is `cuid()`. Do not change in Stage 2B; requires approval. |
| Related DTO/model/schema | `GenerateCardDto`; `CardsQueryDto`; `UpdateCardDto`; `ShareCard`; `RarityLevel`; `DataSource`. |
| Test coverage | `flow-4-result-page.e2e-spec.ts`; `flow-5-card-generation.e2e-spec.ts`. |

## 5. My/Profile/card retrieval contract

| Item | Current contract |
|---|---|
| Profile retrieval | GraphQL `me` exists in `backend/src/users/users.resolver.ts`; REST `/api/v1/users/me/profile` is not implemented. |
| History retrieval | `GET /api/v1/users/:userId/sessions`. |
| Session stats | `GET /api/v1/users/:userId/stats`; `GET /api/v1/users/:userId/most-trained-exercises`. |
| Card collection retrieval | `GET /api/v1/users/:userId/cards`; `GET /api/v1/users/:userId/cards/stats`. |
| Settings retrieval | REST `/api/v1/users/me/settings/**` routes are not implemented in current backend. |
| Expected response | Cards and sessions controllers use `{ success, data, pagination?/message? }`. |
| Related DTO/model/schema | `CardsQueryDto`; `SessionQueryDto`; `UserStatsQueryDto`; `User`; `WorkoutSession`; `ShareCard`. |
| Test coverage | `flow-6-user-center.e2e-spec.ts`; `flow-5-card-generation.e2e-spec.ts`. |

## 6. Theme week support contract

| Item | Current contract |
|---|---|
| Current theme week | `GET /api/v1/theme-weeks/current`; optional `userId` query. |
| Join theme week | `POST /api/v1/theme-weeks/:themeWeekId/join`; body requires `userId`. |
| Update progress | `POST /api/v1/theme-weeks/:themeWeekId/update-progress`; body includes `userId`, `exercisesCompleted`. |
| Naming | Current schema/controller uses `title`, `equipmentCode`, `targetExerciseCount`, not old `name`, `equipmentSeries`, `targetCount`. |
| Persistence behavior | `ThemeWeekParticipation` persists `exercisesCompleted`, `targetExercises`, `progressPercent`, `rewardEarned`, `relatedSessions`. |
| Test coverage | `flow-7-theme-week.e2e-spec.ts`. |

## Remaining contract blockers requiring future approval

| Finding | Evidence file path | Impact | Risk level | Recommended action |
|---|---|---|---|---|
| Dedicated Guide step API does not exist. | `backend/src/**/*.controller.ts`; `flow-3-guided-workout.e2e-spec.ts` | Frontend Guide must either use quick recommendation directly or a new approved guide API must be designed. | High | Stage 2C should decide whether to add backend Guide orchestration endpoints. |
| Anonymous auth and `/auth/anonymous` are not current backend contracts. | `backend/src/auth/auth.controller.ts`; `backend/prisma/schema.prisma` | Old onboarding tests cannot be made real without auth/schema decisions. | High | Decide anonymous/session identity strategy before production auth work. |
| REST My/Profile `/api/v1/users/me/**` endpoints are absent. | `backend/src/users`; `backend/src/cards/cards.controller.ts`; `backend/src/workout-sessions/workout-sessions.controller.ts` | Latest My UI may need adapter logic or new endpoints. | High | Stage 2C should define My/Profile API ownership and auth model. |
| Card generation ID validation conflicts with current schema ID format. | `backend/src/cards/dto/cards.dto.ts`; `backend/prisma/schema.prisma` | Valid session IDs may fail validation. | High | Approve either UUID session IDs or remove UUID-only card DTO validation. |
| True E2E business-flow tests still need safe DB/test env. | `backend/test/helpers/test-data.helper.ts`; Stage 2B logs | Runtime flow tests cannot be safely green against unknown external DB. | Critical | Create isolated test database and seed/reset script before runtime E2E work. |
