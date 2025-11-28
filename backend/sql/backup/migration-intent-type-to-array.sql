-- Migration: Change intent_type from single enum to array
-- Purpose: Allow exercises to support multiple intents (RELAX, STRETCH, MODERATE, STRENGTH)
-- Empty array [] means the exercise is suitable for all intents
-- Date: 2025-11-26
-- Author: Claude Code

-- ============================================================================
-- 1. ALTER COLUMN: Change intent_type to array type
-- ============================================================================

-- Step 1: Add new column as array
ALTER TABLE "exercises"
ADD COLUMN IF NOT EXISTS "intent_types" "IntentType"[] DEFAULT ARRAY[]::"IntentType"[];

-- Step 2: Migrate data from old single column to new array column
-- Convert existing single intent_type values to arrays
UPDATE "exercises"
SET "intent_types" = ARRAY[intent_type]::"IntentType"[]
WHERE "intent_type" IS NOT NULL;

-- Step 3: Drop old column
ALTER TABLE "exercises"
DROP COLUMN IF EXISTS "intent_type";

-- Step 4: Rename new column to old name
ALTER TABLE "exercises"
RENAME COLUMN "intent_types" TO "intent_type";

-- Step 5: Add comment
COMMENT ON COLUMN "exercises"."intent_type" IS 'Array of intent types this exercise supports. Empty array means suitable for all intents. Values: RELAX, STRETCH, MODERATE, STRENGTH';

-- ============================================================================
-- 2. UPDATE INDEX: Recreate index for array column
-- ============================================================================

-- Drop old index if exists
DROP INDEX IF EXISTS "exercises_primary_muscle_difficulty_intent_type_idx";

-- Create new GIN index for array searching
CREATE INDEX IF NOT EXISTS "exercises_intent_type_gin_idx"
ON "exercises" USING GIN ("intent_type");

-- Create composite index for common queries
CREATE INDEX IF NOT EXISTS "exercises_primary_muscle_difficulty_idx"
ON "exercises"("primary_muscle", "difficulty")
WHERE "is_active" = true;

-- ============================================================================
-- 3. UPDATE EXISTING DATA: Make exercises more flexible
-- ============================================================================

-- Update all RELAX exercises to also support STRETCH (they're often similar)
UPDATE "exercises"
SET "intent_type" = ARRAY['RELAX', 'STRETCH']::"IntentType"[]
WHERE 'RELAX' = ANY("intent_type") AND NOT ('STRETCH' = ANY("intent_type"));

-- Make simple bodyweight exercises suitable for all intents (empty array)
-- These are basic movements that work for any workout goal
UPDATE "exercises"
SET "intent_type" = ARRAY[]::"IntentType"[]
WHERE "code" IN (
    'neck_stretch',
    'shoulder_roll',
    'marching_in_place',
    'chair_marching'
);

-- Log changes
DO $$
DECLARE
    empty_intent_count INTEGER;
    multi_intent_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO empty_intent_count
    FROM "exercises"
    WHERE "intent_type" = ARRAY[]::"IntentType"[];

    SELECT COUNT(*) INTO multi_intent_count
    FROM "exercises"
    WHERE array_length("intent_type", 1) > 1;

    RAISE NOTICE 'Migration completed:';
    RAISE NOTICE '  - Exercises with all intents (empty array): %', empty_intent_count;
    RAISE NOTICE '  - Exercises with multiple specific intents: %', multi_intent_count;
END $$;

-- ============================================================================
-- 4. VERIFICATION QUERIES
-- ============================================================================

-- Verify the migration
-- SELECT
--     code,
--     name,
--     intent_type,
--     array_length(intent_type, 1) as intent_count,
--     CASE
--         WHEN intent_type = ARRAY[]::"IntentType"[] THEN 'All intents'
--         ELSE array_to_string(intent_type, ', ')
--     END as intent_display
-- FROM exercises
-- ORDER BY
--     CASE WHEN intent_type = ARRAY[]::"IntentType"[] THEN 0 ELSE 1 END,
--     array_length(intent_type, 1) DESC,
--     name;

-- ============================================================================
-- 5. EXAMPLE QUERIES: How to query with the new array field
-- ============================================================================

-- Find exercises that support RELAX intent (including those with empty array)
-- SELECT * FROM exercises
-- WHERE 'RELAX' = ANY(intent_type) OR intent_type = ARRAY[]::"IntentType"[];

-- Find exercises that support multiple intents
-- SELECT * FROM exercises
-- WHERE array_length(intent_type, 1) > 1;

-- Find exercises suitable for all intents
-- SELECT * FROM exercises
-- WHERE intent_type = ARRAY[]::"IntentType"[];
