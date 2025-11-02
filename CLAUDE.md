# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**SnapRep** is a full-stack fitness monorepo consisting of:
- **Backend**: NestJS GraphQL API with PostgreSQL database (production-ready)
- **Frontend**: Flutter cross-platform mobile app (early development, template code only)

The app enables users to "exercise anywhere, anytime with objects at hand" by selecting target muscle groups and available everyday objects to receive 3 safe exercise recommendations.

## Monorepo Structure

```
SnapRep/
├── backend/          # NestJS + GraphQL + PostgreSQL API
├── frontend/         # Flutter mobile app
└── .claude/          # Claude Code workspace settings
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

# Run tests
npm test                        # Unit tests
npm run test:watch             # Watch mode
npm run test:cov               # Coverage report
npm run test:e2e               # End-to-end tests

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
- **Database**: PostgreSQL with Prisma 5.0.0 ORM
- **Authentication**: JWT with bcrypt password hashing
- **Build Tool**: SWC (faster TypeScript compilation)

### Modular Architecture
```
backend/src/
├── main.ts                 # Bootstrap with Swagger/CORS setup
├── app.module.ts           # Root module with GraphQL config
├── auth/                   # JWT authentication module
│   ├── auth.service.ts     # JWT & password validation
│   ├── auth.resolver.ts    # signup/login GraphQL mutations
│   ├── jwt.strategy.ts     # JWT extraction strategy
│   └── gql-auth.guard.ts   # GraphQL auth guard
├── users/                  # User management module
│   ├── users.resolver.ts   # User GraphQL queries
│   └── users.service.ts    # User business logic
├── posts/                  # Posts CRUD module (example)
├── common/                 # Shared utilities
│   ├── configs/            # Configuration service
│   ├── pagination/         # Pagination logic
│   └── decorators/         # Custom decorators
└── prisma/                 # Database schema & migrations
```

### Key Patterns
- **Code-first GraphQL**: Schema generated from TypeScript decorators
- **Module-based**: Each domain has resolver + service + DTOs
- **Guards & Decorators**: Authentication via `@UseGuards(GqlAuthGuard)`
- **Prisma ORM**: Type-safe database access with migrations

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

## Database Schema (Current)

```prisma
User {
  id: String (CUID)
  email: String (unique)
  password: String (bcrypt hashed)
  firstname, lastname: Optional String
  role: Role (ADMIN | USER)
  posts: Post[] (relation)
  timestamps: createdAt, updatedAt
}

Post {
  id: String (CUID)
  title: String
  content: Optional String
  published: Boolean
  author: User? (relation)
  timestamps: createdAt, updatedAt
}
```

**Note**: Current schema is from NestJS starter template. SnapRep will need Exercise, Object, and UserWorkout models.

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
- **`backend/prisma/schema.prisma`**: Database schema definition
- **`backend/nest-cli.json`**: NestJS compiler config (SWC-based)
- **`frontend/pubspec.yaml`**: Flutter dependencies and metadata
- **`frontend/CLAUDE.md`**: Detailed frontend development guide

## Development Workflow

### Backend Changes
1. Modify code in `backend/src/`
2. Update Prisma schema if needed: `npm run migrate:dev`
3. Generate Prisma client: `npm run prisma:generate`
4. Run tests: `npm test`
5. Test GraphQL queries in playground

### Frontend Changes
1. Implement features in `frontend/lib/`
2. Run `flutter analyze` for linting
3. Test on device: `flutter run`
4. Run tests: `flutter test`

### Database Changes
1. Update `backend/prisma/schema.prisma`
2. Create migration: `npm run migrate:dev`
3. Update resolvers/services to match new schema
4. Update seed data if needed: edit `backend/prisma/seed.ts`

## Authentication Flow

Backend uses JWT-based authentication:
1. **Signup/Login**: POST to GraphQL mutations
2. **Token Storage**: Client stores JWT token
3. **Protected Routes**: Use `Authorization: Bearer <token>` header
4. **Guards**: `@UseGuards(GqlAuthGuard)` on protected resolvers

## Performance Requirements

### Frontend Targets
- **Time to Value**: ≤30 seconds from app open to exercise recommendations (P75)
- **Exercise Generation**: ≤5 seconds
- **Completion Card Export**: ≤800ms
- **Session Completion Rate**: ≥95%

### Backend Targets
- GraphQL query response times optimized for mobile
- Database queries use proper indexing and pagination
- JWT token validation with minimal overhead

## Testing Strategy

### Backend
- **Unit Tests**: Jest with ts-jest for services and resolvers
- **E2E Tests**: Supertest for API endpoint testing
- **Database Tests**: In-memory or test database with migrations

### Frontend
- **Unit Tests**: Individual function and class testing
- **Widget Tests**: UI component testing
- **Integration Tests**: Complete user flow testing

Use `npm run test:watch` (backend) or `flutter test --watch` (frontend) for development.