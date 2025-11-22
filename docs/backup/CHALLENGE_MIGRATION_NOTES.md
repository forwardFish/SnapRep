# Challenge System Migration

## Database Schema Updates

The challenge system requires two new database tables. When your database is available, run:

```bash
cd backend
npx prisma migrate dev --name add_challenge_system
```

## New Tables Added:

### 1. `challenge_items` table
- Stores challenge item information (umbrella, book, guitar, etc.)
- Includes difficulty, rarity levels, and participation statistics
- Uses existing RarityLevel enum for badge consistency

### 2. `challenge_completions` table
- Tracks user challenge progress and completions
- Links to users and workout sessions
- Stores badge awards and XP earned

## API Endpoints Created:

- `GET /rest/v1/challenges` - Get challenge items list (with pagination)
- `GET /rest/v1/challenges/:id` - Get single challenge item
- `GET /rest/v1/challenges/code/:code` - Get challenge by code
- `GET /rest/v1/challenges/completions/user/:userId` - Get user completions
- `POST /rest/v1/challenges/completions/start` - Start a challenge
- `PATCH /rest/v1/challenges/completions/:id/complete` - Complete challenge
- `GET /rest/v1/challenges/stats/count` - Get challenge count

## Frontend Features:

1. **Homepage Enhancement**: Added English "Item Challenges" entry card
2. **Challenge Grid Page**: 3x4 grid showing 12 challenge items with:
   - Emoji icons and names
   - Difficulty stars (1-5)
   - Rarity badges with color coding
   - Participant counts
3. **Routing**: Added `/challenges` route with navigation

## Usage:

Users can now:
1. See "Item Challenges" card on homepage
2. Tap "Explore" to view challenge grid
3. See 12 different item challenges with difficulty and popularity
4. Tap challenges to start them (currently shows success message)

The system is ready for database setup and can be extended with actual challenge execution workflow.