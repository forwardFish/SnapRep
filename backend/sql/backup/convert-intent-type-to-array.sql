-- ==========================================
-- Convert intent_type from single string to array
-- Run this in Supabase SQL Editor
-- ==========================================

-- Step 1: Add new column as array
ALTER TABLE "exercises"
ADD COLUMN IF NOT EXISTS "intent_types_new" "IntentType"[] DEFAULT ARRAY[]::"IntentType"[];

-- Step 2: Convert existing single values to arrays
-- RELAX exercises
UPDATE "exercises"
SET "intent_types_new" = ARRAY['RELAX']::"IntentType"[]
WHERE "intent_type" = 'RELAX';

-- STRETCH exercises
UPDATE "exercises"
SET "intent_types_new" = ARRAY['STRETCH']::"IntentType"[]
WHERE "intent_type" = 'STRETCH';

-- MODERATE exercises
UPDATE "exercises"
SET "intent_types_new" = ARRAY['MODERATE']::"IntentType"[]
WHERE "intent_type" = 'MODERATE';

-- STRENGTH exercises
UPDATE "exercises"
SET "intent_types_new" = ARRAY['STRENGTH']::"IntentType"[]
WHERE "intent_type" = 'STRENGTH';

-- Step 3: Make RELAX exercises also support STRETCH (they're similar)
UPDATE "exercises"
SET "intent_types_new" = ARRAY['RELAX', 'STRETCH']::"IntentType"[]
WHERE 'RELAX' = ANY("intent_types_new");

-- Step 4: Make simple neck/shoulder exercises suitable for all intents (empty array)
UPDATE "exercises"
SET "intent_types_new" = ARRAY[]::"IntentType"[]
WHERE "code" IN (
    'neck_stretch',
    'shoulder_roll',
    'marching_in_place',
    'chair_marching'
);

-- Step 5: Drop old column
ALTER TABLE "exercises"
DROP COLUMN IF EXISTS "intent_type";

-- Step 6: Rename new column to old name
ALTER TABLE "exercises"
RENAME COLUMN "intent_types_new" TO "intent_type";

-- Step 7: Create GIN index for efficient array searching
DROP INDEX IF EXISTS "exercises_intent_type_gin_idx";
CREATE INDEX "exercises_intent_type_gin_idx"
ON "exercises" USING GIN ("intent_type");

-- Step 8: Verify the migration
SELECT
    code,
    name,
    intent_type,
    array_length(intent_type, 1) as intent_count,
    CASE
        WHEN intent_type = ARRAY[]::"IntentType"[] THEN 'All intents (empty array)'
        ELSE array_to_string(intent_type, ', ')
    END as intent_display
FROM exercises
WHERE is_active = true
ORDER BY
    CASE WHEN intent_type = ARRAY[]::"IntentType"[] THEN 0 ELSE 1 END,
    array_length(intent_type, 1) DESC NULLS LAST,
    name;

-- Migration completed
SELECT '✅ intent_type column successfully converted to array format' as status;
