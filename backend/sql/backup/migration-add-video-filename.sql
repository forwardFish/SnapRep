-- Migration: Add video_filename field to exercises table
-- Purpose: Store local video file names for exercise demonstrations
-- Date: 2025-11-26
-- Author: Claude Code

-- ============================================================================
-- 1. ADD COLUMN: video_filename
-- ============================================================================
-- Add video_filename column to store local video file names
-- This field will store the filename (e.g., "wall_chest_opener.mp4")
-- The backend will construct the full URL when serving the data

ALTER TABLE "exercises"
ADD COLUMN IF NOT EXISTS "video_filename" TEXT;

-- Add comment to the column
COMMENT ON COLUMN "exercises"."video_filename" IS 'Local video filename for exercise demonstration (e.g., wall_chest_opener.mp4)';

-- ============================================================================
-- 2. CREATE INDEX: For faster video lookup
-- ============================================================================
CREATE INDEX IF NOT EXISTS "exercises_video_filename_idx"
ON "exercises"("video_filename")
WHERE "video_filename" IS NOT NULL;

-- ============================================================================
-- 3. UPDATE EXISTING DATA: Map video files to exercises
-- ============================================================================
-- Based on existing video files in backend/asset/videos/
-- Mapping exercise codes to video filenames

-- Update exercises with existing video files
UPDATE "exercises"
SET "video_filename" = 'wall_chest_opener.mp4'
WHERE "code" = 'wall_chest_opener';

UPDATE "exercises"
SET "video_filename" = 'chair_sit_to_stand.mp4'
WHERE "code" = 'chair_sit_to_stand';

UPDATE "exercises"
SET "video_filename" = 'core_three_point_support.mp4'
WHERE "code" = 'core_three_point_support';

-- ============================================================================
-- 4. VERIFICATION QUERY
-- ============================================================================
-- Run this to verify the migration
-- SELECT id, code, name, video_filename, demo_video_url
-- FROM exercises
-- WHERE video_filename IS NOT NULL;
