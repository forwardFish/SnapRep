# SnapRep Backend - Database Schema Documentation

**Version**: Production Ready (Unified)
**Last Updated**: 2025-10-30
**Database**: PostgreSQL 15+ (Supabase)

## Overview

SnapRep is a fitness app that enables users to work out anywhere with everyday objects. This document describes the complete database schema, designed for rapid deployment with smooth scalability to a NestJS monolith (Phase 1).

### Design Principles

- **Fast Launch**: Optimized for quick production deployment
- **Smooth Scaling**: Clean migration path to Phase 1 (NestJS monolith)
- **Protocol Consistency**: Unified naming conventions (resource-based vs compute-based APIs)
- **Permission Boundaries**: Enhanced Row Level Security (RLS) with cascade policies
- **Idempotency**: Retry-safe operations with Idempotency-Key support
- **Cache Performance**: ETag-based cache negotiation
- **Observability**: Comprehensive monitoring and logging support

---

## Quick Start

### Prerequisites

- Node.js 18+
- PostgreSQL 15+ or Supabase account
- Prisma CLI: `npm install -g prisma`

### Setup

```bash
# 1. Install dependencies
cd backend
npm install

# 2. Configure environment variables
cp .env.example .env
# Edit .env with your DATABASE_URL and DIRECT_URL

# 3. Generate Prisma Client
npx prisma generate

# 4. Run migrations (for Supabase, use the SQL file directly)
# Option A: Prisma migrations (local development)
npx prisma migrate dev --name init

# Option B: Supabase (production)
# Upload supabase_migration.sql to Supabase SQL Editor
```

### Seed Data (Optional)

```bash
npx prisma db seed
```

---

## Architecture Overview

### Hybrid Approach

- **Supabase**: Handles basic CRUD, Auth, Storage, Realtime subscriptions
- **NestJS**: Complex business logic, ML recommendations, analytics
- **Prisma**: Type-safe database access layer

### Key Tables (16 Total)

1. **Core Domain**
   - `scenarios` - Training environments (office, home, gym, park)
   - `equipment` - Everyday objects used for exercises
   - `exercises` - 50+ exercises with AI-recognizable equipment

2. **User & Sessions**
   - `users` - User profiles with Supabase Auth integration
   - `workout_sessions` - Training sessions with follow-along mode
   - `session_exercises` - Junction table tracking exercise completion

3. **Gamification**
   - `share_cards` - Social sharing with rarity collection system
   - `rarity_table` - Weekly equipment rarity rankings
   - `daily_trainings` - Daily statistics for streak tracking

4. **Social Features**
   - `theme_weeks` - Weekly challenges with rewards
   - `theme_week_participations` - User participation tracking

5. **Analytics & Personalization**
   - `user_preferences` - ML-driven preference learning
   - `deeplinks` - Short URLs for sharing
   - `deeplink_clicks` - Click tracking (no auth required)

6. **Junction Tables**
   - `exercise_scenarios` - Many-to-many: exercises ↔ scenarios
   - `exercise_equipment` - Many-to-many: exercises ↔ equipment

---

## Schema Highlights

### Enums (11 Total)

All enums use `UPPER_SNAKE_CASE` for consistency:

```prisma
enum NoiseLevel {
  SILENT   // Office, library
  QUIET    // Hotel, dorm
  NORMAL   // Home, gym
}

enum Difficulty {
  GREEN    // Beginner-friendly
  BLUE     // Intermediate
  RED      // Advanced
}

enum IntentType {
  RELAX      // Muscle relaxation
  STRETCH    // Flexibility
  MODERATE   // Light cardio
  STRENGTH   // Muscle building
}

enum RarityLevel {
  COMMON      // >50% usage rate
  UNCOMMON    // 20-50%
  RARE        // 5-20%
  EPIC        // 1-5%
  LEGENDARY   // <1%
}
```

### Core Relationships

```
User (1) ----< (N) WorkoutSession (1) ----< (N) SessionExercise (N) >---- (1) Exercise
                          |                                                      |
                          v                                                      v
                     ShareCard (1)                                      ExerciseEquipment (N)
                          |                                                      |
                          v                                                      v
                     RarityTable (N) >------------------------------------ (1) Equipment
```

### AI Recognition System

Equipment can be automatically recognized via camera:

```prisma
model Equipment {
  recognizable          Boolean  @default(false)
  recognitionLabels     String[] @default([])        // TensorFlow Lite labels
  recognitionConfidence Float    @default(0.85)      // Confidence threshold
}
```

Example:
- `chair`: `recognitionLabels = ["chair", "office chair", "dining chair"]`
- `wall`: `recognizable = false` (too generic for ML)

### Rarity Collection System

Weekly updated rarity rankings for equipment:

```prisma
model RarityTable {
  equipmentCode String      // e.g., "chair", "bottle"
  weekStart     DateTime    // Monday of each week
  rarityScore   Float       // 0.0-1.0
  rarityLevel   RarityLevel // COMMON to LEGENDARY
  dataSource    DataSource  // WEEKLY_TABLE or ON_THE_FLY_ESTIMATE
}
```

Users collect rare equipment combinations to earn special share cards.

---

## Row Level Security (RLS)

### Key Policies

1. **User Data Protection**
   ```sql
   -- Users can only access their own data
   CREATE POLICY "users_own_data" ON users
   FOR ALL USING (auth.uid() = id);
   ```

2. **Cascade Privacy**
   ```sql
   -- Share cards visible only if session is completed by owner
   CREATE POLICY "share_cards_cascade" ON share_cards
   FOR SELECT USING (
     is_public = true
     OR user_id = auth.uid()
     OR EXISTS (
       SELECT 1 FROM workout_sessions ws
       WHERE ws.id = session_id
       AND ws.user_id = auth.uid()
     )
   );
   ```

3. **Public Read, Owner Write**
   ```sql
   -- All users can read scenarios, only admins can modify
   CREATE POLICY "scenarios_public_read" ON scenarios
   FOR SELECT USING (is_active = true);
   ```

4. **No-Auth Data Access**
   ```sql
   -- Deeplink clicks don't require authentication
   CREATE POLICY "deeplink_clicks_public_insert" ON deeplink_clicks
   FOR INSERT WITH CHECK (true);
   ```

### RLS Testing

```sql
-- Test as specific user
SET LOCAL ROLE authenticated;
SET LOCAL request.jwt.claims.sub = '00000000-0000-0000-0000-000000000001';

SELECT * FROM workout_sessions; -- Should only see own sessions
```

---

## API Design Patterns

### Resource-Based Endpoints (RESTful)

```
GET    /api/exercises              # List all exercises
GET    /api/exercises/:id          # Get specific exercise
POST   /api/exercises              # Create exercise (admin)
PATCH  /api/exercises/:id          # Update exercise (admin)
DELETE /api/exercises/:id          # Delete exercise (admin)
```

### Compute-Based Endpoints (RPC-style)

```
POST   /api/workout-sessions/generate  # Generate new workout
POST   /api/workout-sessions/:id/start # Start session
POST   /api/workout-sessions/:id/pause # Pause session
POST   /api/share-cards/render         # Render share card image
```

### Unified Response Format

```typescript
// Success response
{
  "data": { /* resource data */ },
  "meta": {
    "timestamp": "2025-10-30T12:00:00Z",
    "requestId": "req_abc123"
  }
}

// Error response
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "Exercise not found",
    "details": { "exerciseId": "ex_123" }
  },
  "meta": {
    "timestamp": "2025-10-30T12:00:00Z",
    "requestId": "req_abc123"
  }
}
```

---

## Performance Optimization

### Key Indexes

```sql
-- User workout history (most frequent query)
CREATE INDEX idx_workout_sessions_user_completed
ON workout_sessions(user_id, completed_at DESC);

-- Exercise filtering (scenario + difficulty + intent)
CREATE INDEX idx_exercises_filter
ON exercises(primary_muscle, difficulty, intent_type)
WHERE is_active = true;

-- Rarity lookups (weekly table)
CREATE INDEX idx_rarity_table_week
ON rarity_table(equipment_code, week_start DESC);
```

### Caching Strategy

1. **ETag Support**: Use `updated_at` timestamps
   ```typescript
   const etag = `"${exercise.updatedAt.getTime()}"`;
   res.setHeader('ETag', etag);
   ```

2. **Cache-Control Headers**
   - Static data (scenarios, equipment): `max-age=3600` (1 hour)
   - Dynamic data (user sessions): `no-cache, must-revalidate`
   - Rarity table: `max-age=604800` (1 week, updates Monday)

3. **Supabase Realtime**
   ```typescript
   supabase
     .channel('workout-updates')
     .on('postgres_changes',
       { event: 'UPDATE', schema: 'public', table: 'workout_sessions' },
       payload => { /* invalidate cache */ }
     )
     .subscribe();
   ```

---

## Seed Data Examples

### Scenarios

```typescript
const scenarios = [
  { code: 'office', name: 'Office', noiseTolerance: 'SILENT', spaceRequirement: 'SMALL' },
  { code: 'home', name: 'Home', noiseTolerance: 'NORMAL', spaceRequirement: 'MEDIUM' },
  { code: 'gym', name: 'Gym', noiseTolerance: 'NORMAL', spaceRequirement: 'LARGE' },
  { code: 'park', name: 'Park', noiseTolerance: 'NORMAL', spaceRequirement: 'LARGE' },
];
```

### Equipment

```typescript
const equipment = [
  {
    code: 'chair',
    name: 'Chair',
    category: 'FURNITURE',
    recognizable: true,
    recognitionLabels: ['chair', 'office chair', 'stool'],
    iconUrl: 'https://cdn.snaprep.app/icons/chair.svg',
  },
  {
    code: 'wall',
    name: 'Wall',
    category: 'WALL',
    recognizable: false,
    iconUrl: 'https://cdn.snaprep.app/icons/wall.svg',
  },
  {
    code: 'none',
    name: 'No Equipment',
    category: 'NONE',
    recognizable: false,
    iconUrl: 'https://cdn.snaprep.app/icons/bodyweight.svg',
  },
];
```

### Exercises

```typescript
const exercises = [
  {
    code: 'wall_chest_opener',
    name: 'Wall Chest Opener',
    primaryMuscle: 'CHEST',
    secondaryMuscles: ['SHOULDERS'],
    intentType: 'STRETCH',
    difficulty: 'GREEN',
    defaultDuration: 30,
    durationType: 'TIME',
    description: {
      keyPoints: ['Keep back straight', 'Breathe deeply'],
      steps: [
        'Stand facing a wall',
        'Place palm flat on wall at shoulder height',
        'Slowly turn body away from wall',
      ],
      warnings: ['Stop if sharp pain occurs'],
    },
    tags: ['silent', 'small-space', 'office-friendly'],
  },
];
```

---

## Migration Guide

### From Local Development to Supabase

1. **Export Prisma schema**
   ```bash
   npx prisma migrate diff \
     --from-empty \
     --to-schema-datamodel prisma/schema.prisma \
     --script > migration.sql
   ```

2. **Enhance with RLS policies**
   - Add RLS policies from `supabase_migration.sql`
   - Enable RLS on all user-facing tables

3. **Test RLS policies**
   ```sql
   -- Create test users via Supabase Dashboard
   -- Verify data isolation with SET LOCAL commands
   ```

4. **Configure Supabase Storage**
   - Bucket: `share-cards` (public read)
   - Bucket: `user-uploads` (private, RLS-protected)

---

## Monitoring & Observability

### Key Metrics to Track

1. **Performance**
   - Query latency (p50, p95, p99)
   - Connection pool usage
   - Slow query log (>100ms)

2. **Business KPIs**
   - Daily Active Users (DAU)
   - Workout completion rate
   - Share card generation rate
   - Theme week participation rate

3. **Errors**
   - RLS policy violations
   - Constraint violations (unique, foreign key)
   - Timeout errors (>5s)

### Logging Strategy

```typescript
// Structured logging example
logger.info('workout_session_completed', {
  userId: session.userId,
  sessionId: session.id,
  duration: session.actualDuration,
  exerciseCount: session.sessionExercises.length,
  completionRate: session.sessionExercises.filter(e => e.isCompleted).length / session.sessionExercises.length,
});
```

---

## FAQ

### Q: Why use Supabase Auth UUID instead of CUID for users?

**A**: Supabase Auth automatically generates UUIDs. Using the same ID ensures seamless integration with `auth.uid()` in RLS policies.

### Q: How does the rarity system work?

**A**: Every Monday, a cron job analyzes the past week's workout data and updates `rarity_table` with new rankings. Share cards created during the week reference the latest `weekStart` entry.

### Q: Can I use this schema without Supabase?

**A**: Yes, but you'll need to:
1. Remove RLS policies (handle authorization in application code)
2. Replace `auth.uid()` with your own user context mechanism
3. Implement your own Auth system (Supabase Auth is tightly coupled)

### Q: What's the difference between `WEEKLY_TABLE` and `ON_THE_FLY_ESTIMATE`?

**A**:
- `WEEKLY_TABLE`: Authoritative data updated every Monday via batch job
- `ON_THE_FLY_ESTIMATE`: Real-time approximation for preview purposes (not persisted)

---

## Contributing

### Schema Changes

1. Update `prisma/schema.prisma`
2. Generate migration: `npx prisma migrate dev --name your_change`
3. Update `supabase_migration.sql` with RLS changes
4. Update this README.md
5. Run tests: `npm test`

### Testing

```bash
# Unit tests
npm run test

# Integration tests (requires test database)
npm run test:integration

# E2E tests (requires Supabase project)
npm run test:e2e
```

---

## Files

- [prisma/schema.prisma](prisma/schema.prisma) - Main Prisma schema (unified production version)
- [supabase_migration.sql](supabase_migration.sql) - Complete SQL migration with RLS policies
- [_backup_old_versions/](_backup_old_versions/) - Backup directory for previous schema versions

---

## Support

- **Documentation**: See this README and inline comments in schema files
- **Issues**: Report issues via your project's issue tracker
- **API Documentation**: See [API_IMPROVEMENTS.md](API_IMPROVEMENTS.md) for detailed API design patterns

---

## License

[Your License Here]

---

**Generated with**: Prisma 5.x + Supabase
**Schema Version**: Unified (Production Ready)
**Last Reviewed**: 2025-10-30
