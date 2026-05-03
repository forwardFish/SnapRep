# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**SnapRep** is a production-ready fitness app that enables "exercise anywhere, anytime with objects at hand":
- **Backend**: Complete NestJS GraphQL API with PostgreSQL (production-ready with 15+ modules)
- **Frontend**: Flutter cross-platform mobile app (architecture documented, implementation pending)

The app provides personalized 60-second workouts by matching target muscle groups with available everyday objects, featuring a sophisticated 9-tier rarity system for exercise card collection and sharing.

## Monorepo Structure

```
SnapRep/
├── backend/                    # Production NestJS API (15+ modules)
│   ├── src/                   # Core application modules
│   ├── prisma/                # Database schema v3.0 (16 models)
│   ├── test/                  # Comprehensive test suite
│   └── scripts/               # Test orchestration scripts
├── frontend/                  # Flutter app (architecture planned)
├── docs/                      # API docs, business flows, design
└── .claude/                   # Claude Code workspace settings
```

## Backend Development Commands

### Setup & Daily Development
```bash
cd backend

# Install dependencies
npm install

# Development server (hot reload)
npm run start:dev

# Production build and start
npm run build
npm run start:prod

# Code quality
npm run lint
npm run format
```

### Database Operations (Prisma)
```bash
cd backend

# Generate Prisma client (run after schema changes)
npm run prisma:generate

# Database migrations
npm run migrate:dev              # Create and apply migration
npm run migrate:dev:create       # Create migration only
npm run migrate:deploy           # Apply migrations (production)
npm run migrate:status           # Check migration status

# Database utilities
npm run prisma:studio           # Open Prisma Studio UI
npm run seed                    # Seed database with test data
```

### Testing
```bash
cd backend

# Run all tests
npm test                        # Unit tests
npm run test:watch             # Watch mode
npm run test:cov               # Coverage report
npm run test:e2e               # End-to-end tests

# New comprehensive test suite
npm run test:full              # Full test orchestration script
npm run test:flows             # Business flow tests (7 scenarios)
npm run test:api               # API integration tests
npm run test:quick             # Quick validation script

# Test single file
npm test -- users.service.spec.ts
```

### Docker Operations
```bash
cd backend

# Database only
npm run docker:db              # Start PostgreSQL container

# Full stack
npm run docker:build           # Build images
npm run docker                 # Start all containers
npm run docker:seed            # Seed database in container
```

## Frontend Development Commands

### Setup & Daily Development
```bash
cd frontend

# Clean and install dependencies
flutter clean && flutter pub get

# Run app (development)
flutter run
flutter run -d <device_id>     # Specific device

# Code quality
flutter analyze                # Lint analysis
flutter test                   # Run tests
```

### Platform-Specific Builds
```bash
cd frontend

# Android
flutter build apk             # Debug APK
flutter build appbundle       # Release App Bundle (Google Play)

# iOS (macOS only)
flutter build ios --release

# Gradle operations (Android)
cd android
./gradlew assembleDebug
./gradlew clean
```

## Backend Architecture

### Technology Stack
- **Framework**: NestJS 10.1.0 (TypeScript)
- **API**: GraphQL (Apollo Server 4.7.5) + REST (Swagger)
- **Database**: PostgreSQL with Prisma 5.22.0 ORM
- **Authentication**: JWT + Supabase Auth (UUID-based)
- **Build Tool**: SWC (faster TypeScript compilation)

### Production Modules (15+)
```
backend/src/
├── main.ts                      # Bootstrap with Swagger/CORS setup
├── app.module.ts                # Root module with GraphQL config
├── auth/                        # JWT authentication module
├── users/                       # User management + preferences
├── scenarios/                   # Training environments (office, home, gym, park)
├── equipment/                   # Everyday objects catalog (200+ items)
├── exercises/                   # Exercise library (50+ exercises)
│   ├── exercise-matching.service.ts    # Equipment/scenario filtering
│   └── workout-recommendation.service.ts # Core recommendation engine
├── workout-sessions/            # Session tracking with follow-along mode
├── cards/                       # Sharing card generation system
│   ├── rarity-calculator.service.ts    # 9-tier rarity system
│   └── card-generator.service.ts       # Visual card templates
├── common/                      # Shared utilities, decorators, configs
└── prisma/                      # Database schema v3.0 & migrations
```

### Key Features
- **Recommendation Engine**: Matches exercises by muscle group, equipment, scenario, difficulty
- **Rarity System**: 9-tier equipment rarity (COMMON to APEX) with personal stars
- **Session Tracking**: Complete workout sessions with progress and analytics
- **Card Generation**: Shareable workout cards with multiple visual templates
- **User Preferences**: ML-driven preference learning and personalization

### API Access
- **GraphQL Playground**: http://localhost:3000/graphql
- **REST API Docs**: http://localhost:3000/api (Swagger)
- **Database Studio**: `npm run prisma:studio`

## Frontend Architecture (Planned)

### Current Status
- **Early scaffolding**: Only Flutter template code in `lib/main.dart`
- **Architecture planned** but not implemented
- Detailed architecture guide exists in `frontend/CLAUDE.md`

### Target Architecture
```
frontend/lib/
├── features/               # Feature modules (exercise, objects, recommendation)
├── core/                   # Shared utilities, widgets, services
├── app/                    # Root app widget and theme
└── config/                 # Routes, localization
```

### Key Requirements
- **Offline-first**: All exercise data stored locally
- **Performance**: ≤30 seconds from app open to exercise recommendations
- **Safety-first**: Curated exercise whitelist with contraindications
- **Cross-platform**: Android/iOS primary, web/desktop supported

## Database Schema v3.0 (Production-Ready)

### Core Domain Models (16 total)
```prisma
// Training Environment
Scenario {
  id, code, name, isActive
  noiseTolerance: NoiseLevel (SILENT/QUIET/NORMAL)
  spaceRequirement: SpaceSize (SMALL/MEDIUM/LARGE)
}

// Everyday Objects Catalog
Equipment {
  id, code, name, category: EquipmentCategory (9 types)
  recognizable: Boolean (AI detection capable)
  recognitionLabels: String[] (object detection labels)
  recognitionConfidence: Float (AI confidence threshold)
  usageFrequencyScore: Float (rarity calculation input)
}

// Exercise Library
Exercise {
  id, code, name, description: Json (i18n support)
  primaryMuscle: PrimaryMuscle (9 muscle groups)
  secondaryMuscles: String[]
  intentType: IntentType (RELAX/STRETCH/MODERATE/STRENGTH)
  difficulty: Difficulty (GREEN/BLUE/RED color-coded)
  defaultDuration, defaultSets, durationType
  demoImageUrl, demoVideoUrl, tags
}

// Users with Extended Preferences
User {
  id: UUID (Supabase Auth integration)
  email, password, name, avatarUrl
  totalWorkouts, totalDurationSec, currentStreak, longestStreak
  preferredIntents: IntentType[], preferredDifficulty, preferredDuration
  avoidEquipment: String[] (user blacklist)
  streakReminder, themeWeekReminder, quietHoursStart/End
}

// Workout Session Tracking
WorkoutSession {
  id, userId, status: SessionStatus
  targetMuscle, selectedEquipment: String[]
  estimatedDurationSec, actualDurationSec
  isFollowAlong: Boolean (guided mode)
  sessionExercises: SessionExercise[] (detailed exercise tracking)
}

// Rarity & Card Collection System
ShareCard {
  id, userId, workoutSessionId
  basicRarity: RarityLevel (equipment usage frequency)
  personalStars: Int (1-5 user-specific usage)
  equipmentSeries: String (collection category)
  templateStyle, shareUrl, clickCount
}

RarityTable {
  id, equipmentCode, weekStart
  usageCount, totalUsers, rarityScore
  dataSource: DataSource (WEEKLY_TABLE/ON_THE_FLY_ESTIMATE)
}
```

### Junction Tables & Advanced Features
- **ExerciseScenario** / **ExerciseEquipment**: Many-to-many relationships
- **ThemeWeek** & **ThemeWeekParticipation**: Weekly challenges with rewards
- **DailyTraining**: Daily statistics for streak tracking
- **Deeplink** & **DeeplinkClick**: Short URL sharing analytics
- **UserPreference**: ML preference learning storage

### Rarity System (9-Tier)
```
COMMON (≥8%) → UNCOMMON (3-8%) → FINE (1-3%) → RARE (0.3-1%)
→ ELITE (0.1-0.3%) → EPIC (0.03-0.1%) → MYTHIC (0.01-0.03%)
→ LEGENDARY (0.003-0.01%) → APEX (<0.003%)
```

## Development Environment

### Backend Requirements
- Node.js 16+
- PostgreSQL 15
- Docker & Docker Compose (optional)

### Frontend Requirements
- Flutter 3.13.0+
- Dart 3.1.0+
- Android SDK API 31+ (Android)
- Xcode (iOS, macOS only)

### Environment Setup
1. **Backend**: Copy `backend/.env.example` to `backend/.env` and configure DATABASE_URL
2. **Database**: Run `npm run docker:db` or setup local PostgreSQL
3. **Frontend**: Run `flutter doctor` to verify setup

## Key Configuration Files

- **`backend/package.json`**: Scripts for build, test, migrate, docker operations
- **`backend/prisma/schema.prisma`**: Database schema v3.0 definition (16 models, 728 lines)
- **`backend/nest-cli.json`**: NestJS compiler config (SWC-based)
- **`frontend/pubspec.yaml`**: Flutter dependencies and metadata
- **`frontend/CLAUDE.md`**: Detailed frontend development guide
- **`docs/API.md`**: Complete API specification (29+ endpoints)
- **`docs/业务流程.md`**: Complete business flows and user journeys

## Test Structure (Comprehensive)

### Business Flow Tests (7 scenarios)
```
test/business-flows/
├── flow-1-auth-entry.e2e-spec.ts         # User registration & login
├── flow-2-quick-start.e2e-spec.ts        # 60-second workout generation
├── flow-3-guided-workout.e2e-spec.ts     # Follow-along session mode
├── flow-4-result-page.e2e-spec.ts        # Workout completion & analytics
├── flow-5-card-generation.e2e-spec.ts    # Rarity calculation & card sharing
├── flow-6-user-center.e2e-spec.ts        # Profile & preferences management
└── flow-7-theme-week.e2e-spec.ts         # Weekly challenges & rewards
```

### API Integration Tests
```
test/api-integration/
└── all-endpoints.e2e-spec.ts             # Complete API endpoint validation
```

### E2E Scenario Tests
```
test/e2e/
├── scenario-1-new-user-full-flow.e2e-spec.ts    # Complete user journey
├── scenario-2-ai-recognition.e2e-spec.ts        # Object detection flow
├── scenario-3-copy-same-workout.e2e-spec.ts     # Workout replication
└── scenario-4-theme-week.e2e-spec.ts            # Challenge participation
```

### Test Helpers
- **`test/helpers/api-client.helper.ts`**: API testing utilities
- **`test/helpers/test-data.helper.ts`**: Seed data generation
- **`scripts/run-tests.js`**: Test orchestration script
- **`scripts/test-helper.js`**: Quick validation utilities

## Development Workflow

### Backend Changes
1. Modify code in `backend/src/` (15+ production modules)
2. Update Prisma schema if needed: `npm run migrate:dev`
3. Generate Prisma client: `npm run prisma:generate`
4. Run business flow tests: `npm run test:flows`
5. Test GraphQL queries in playground: http://localhost:3000/graphql

### Frontend Changes
1. Implement features in `frontend/lib/` (follow architecture in frontend/CLAUDE.md)
2. Run `flutter analyze` for linting
3. Test on device: `flutter run`
4. Run tests: `flutter test`

### Database Changes
1. Update `backend/prisma/schema.prisma` (current: v3.0, 16 models)
2. Create migration: `npm run migrate:dev`
3. Update resolvers/services to match new schema
4. Update seed data: edit `backend/prisma/seed.ts` or `complete-test-data.sql`

### Rarity System Development
Location: `backend/src/cards/services/rarity-calculator.service.ts`
- Modify 9-tier rarity calculation logic
- Update weekly rarity table calculations
- Test with: `npm run test:flows` (flow-5-card-generation)

## Core Business Logic

### Recommendation Engine
Location: `backend/src/exercises/services/workout-recommendation.service.ts`
```typescript
// Key methods:
recommendExercises(targetMuscle, equipment[], scenario, duration)
filterByDifficulty(exercises, userPreference)
calculateOptimalDuration(exercises, totalTimeLimit)
```

### Rarity Calculator
Location: `backend/src/cards/services/rarity-calculator.service.ts`
```typescript
// Key methods:
calculateRarity(equipmentCode): RarityLevel
calculateBatchRarity(equipmentCodes[]): Map<string, RarityLevel>
calculatePersonalStars(userId, equipmentCode): number (1-5)
getRarityTrend(equipmentCode, weeks): TrendData
```

### Session Tracking
Location: `backend/src/workout-sessions/`
- Session status: PENDING → IN_PROGRESS → COMPLETED/ABANDONED
- Exercise tracking: comfort level, effectiveness rating
- Follow-along mode support

## API Architecture

### Dual API Pattern
- **Supabase Auto-REST**: Direct table access (fast queries)
- **NestJS GraphQL**: Complex business logic, multi-table operations
- **29+ Endpoints**: Complete CRUD + business operations

### Authentication Flow
- **Supabase Auth**: UUID-based user management
- **JWT Strategy**: Custom token validation for NestJS
- **Hybrid Support**: Both Supabase sessions + custom JWT tokens

## Performance Requirements

### Frontend Targets
- **Time to Value**: ≤30 seconds from app open to exercise recommendations (P75)
- **Exercise Generation**: ≤5 seconds (recommendation engine)
- **Completion Card Export**: ≤800ms (rarity calculation + card generation)
- **Session Completion Rate**: ≥95%

### Backend Targets
- **Rarity Calculation**: Cached weekly updates, ≤200ms real-time queries
- **Recommendation Engine**: ≤3 seconds for exercise matching
- **GraphQL Queries**: Optimized for mobile, ≤500ms response times
- **Database Queries**: Proper indexing on muscle groups, equipment, rarity scores

## Testing Strategy

### Production Test Suite
- **Business Flow Tests** (7 scenarios): Complete user journeys from auth to card sharing
- **API Integration Tests**: All 29+ endpoints validation
- **E2E Scenario Tests** (4 scenarios): Object detection, workout replication, challenges
- **Unit Tests**: Jest with ts-jest for services and resolvers
- **Database Tests**: Complete seed data with `complete-test-data.sql`

### Test Execution
```bash
npm run test:full      # Complete test orchestration
npm run test:quick     # Quick validation (recommended for development)
npm run test:flows     # Business flow validation
npm run test:api       # API endpoint validation
npm run test:watch     # Development watch mode
```

## Important Implementation Notes

### Rarity System Complexity
- **9-tier structure**: COMMON to APEX with mathematical progression
- **3-layer calculation**: Basic rarity + Personal stars + Equipment series
- **Caching strategy**: Weekly batch updates with real-time estimates
- **Fallback logic**: Estimated scores when data unavailable

### UUID vs CUID Hybrid
- **User IDs**: UUID for Supabase Auth compatibility
- **Other entities**: CUID for better performance and URL-safe IDs
- **Migration support**: UUID conversion scripts available

### Database Schema Evolution
- **Current**: v3.0 (production-ready, 728 lines)
- **16 models**: Complete fitness domain with gamification
- **Junction tables**: Proper many-to-many relationships
- **Enum consistency**: UPPER_SNAKE_CASE naming convention

### Frontend Architecture Status
- **Current**: Only template code in `lib/main.dart`
- **Documentation**: Complete architecture guide in `frontend/CLAUDE.md`
- **Requirements**: Offline-first with 30-second TTV target