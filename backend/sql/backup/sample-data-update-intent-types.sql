-- Sample Data Update: Convert existing exercises to use intent_type array
-- Purpose: Update your current exercise data to use the new array format
-- Run this AFTER running migration-intent-type-to-array.sql
-- Date: 2025-11-26

-- ============================================================================
-- STRATEGY: Make exercises more flexible with multiple intents
-- ============================================================================

-- 1. RELAX exercises can also work for STRETCH (they overlap)
UPDATE "exercises"
SET "intent_type" = ARRAY['RELAX', 'STRETCH']::"IntentType"[]
WHERE code IN (
    'neck_stretch',
    'shoulder_roll',
    'chair_spinal_twist',
    'wall_chest_stretch',
    'towel_overhead_stretch'
);

-- 2. STRETCH exercises can also work for RELAX
UPDATE "exercises"
SET "intent_type" = ARRAY['STRETCH', 'RELAX']::"IntentType"[]
WHERE code IN (
    'chair_spinal_twist',
    'wall_chest_stretch',
    'towel_overhead_stretch'
) AND NOT ('RELAX' = ANY("intent_type"));

-- 3. MODERATE cardio exercises can work for both MODERATE and STRENGTH (light strength training)
UPDATE "exercises"
SET "intent_type" = ARRAY['MODERATE', 'STRENGTH']::"IntentType"[]
WHERE code IN (
    'jumping_jacks',
    'chair_marching',
    'marching_in_place',
    'sofa_stepup',
    'stairs_stepup'
);

-- 4. STRENGTH exercises that are bodyweight can also work for MODERATE
UPDATE "exercises"
SET "intent_type" = ARRAY['STRENGTH', 'MODERATE']::"IntentType"[]
WHERE code IN (
    'burpees',
    'plank',
    'standard_pushup',
    'wall_pushup',
    'chair_squat',
    'wall_squat'
);

-- 5. Simple, versatile exercises suitable for ALL intents (empty array)
-- These are basic movements everyone can do
UPDATE "exercises"
SET "intent_type" = ARRAY[]::"IntentType"[]
WHERE code IN (
    'neck_stretch',
    'shoulder_roll',
    'marching_in_place',
    'chair_marching'
);

-- 6. Equipment-based exercises typically for STRENGTH only
UPDATE "exercises"
SET "intent_type" = ARRAY['STRENGTH']::"IntentType"[]
WHERE code IN (
    'backpack_deadlift',
    'bottle_bicep_curl',
    'bottle_russian_twist',
    'bottle_shoulder_press',
    'chair_dips',
    'sofa_incline_pushup',
    'wall_handstand_prep'
);

-- ============================================================================
-- VERIFICATION: Check the distribution
-- ============================================================================

-- See exercises with multiple intents
SELECT
    code,
    name,
    intent_type,
    array_length(intent_type, 1) as intent_count,
    CASE
        WHEN intent_type = ARRAY[]::"IntentType"[] THEN '✓ All intents'
        WHEN array_length(intent_type, 1) > 1 THEN '✓ Multiple intents'
        ELSE 'Single intent'
    END as flexibility
FROM exercises
WHERE is_active = true
ORDER BY
    CASE WHEN intent_type = ARRAY[]::"IntentType"[] THEN 0 ELSE 1 END,
    array_length(intent_type, 1) DESC,
    name;

-- Count exercises by intent (including overlaps)
WITH intent_counts AS (
    SELECT
        unnest(intent_type) as intent,
        code
    FROM exercises
    WHERE is_active = true AND array_length(intent_type, 1) > 0

    UNION ALL

    -- Include exercises with empty array for all intents
    SELECT
        intent_value as intent,
        code
    FROM exercises,
    unnest(ARRAY['RELAX', 'STRETCH', 'MODERATE', 'STRENGTH']::"IntentType"[]) as intent_value
    WHERE is_active = true AND intent_type = ARRAY[]::"IntentType"[]
)
SELECT
    intent,
    COUNT(DISTINCT code) as exercise_count
FROM intent_counts
GROUP BY intent
ORDER BY intent;

-- Show sample exercises for each intent
SELECT
    'RELAX' as intent,
    array_agg(name ORDER BY name) FILTER (WHERE 'RELAX' = ANY(intent_type) OR intent_type = ARRAY[]::"IntentType"[]) as exercises
FROM exercises
WHERE is_active = true

UNION ALL

SELECT
    'STRETCH' as intent,
    array_agg(name ORDER BY name) FILTER (WHERE 'STRETCH' = ANY(intent_type) OR intent_type = ARRAY[]::"IntentType"[]) as exercises
FROM exercises
WHERE is_active = true

UNION ALL

SELECT
    'MODERATE' as intent,
    array_agg(name ORDER BY name) FILTER (WHERE 'MODERATE' = ANY(intent_type) OR intent_type = ARRAY[]::"IntentType"[]) as exercises
FROM exercises
WHERE is_active = true

UNION ALL

SELECT
    'STRENGTH' as intent,
    array_agg(name ORDER BY name) FILTER (WHERE 'STRENGTH' = ANY(intent_type) OR intent_type = ARRAY[]::"IntentType"[]) as exercises
FROM exercises
WHERE is_active = true;

-- ============================================================================
-- NOTES
-- ============================================================================

-- Intent Flexibility Guidelines:
--
-- 1. Empty Array ([]) = Universal exercises suitable for any intent
--    Example: neck_stretch, shoulder_roll, basic marching
--
-- 2. Single Intent = Specialized exercises
--    Example: burpees (STRENGTH only), heavy weight training
--
-- 3. Multiple Intents = Versatile exercises
--    Example: wall_pushup (STRENGTH + MODERATE), jumping_jacks (MODERATE + STRENGTH)
--
-- Benefits of this approach:
-- - More exercise matches when users search
-- - Better workout variety
-- - Flexible workout planning
-- - Empty array exercises work as "fillers" for any workout
