-- ==========================================
-- Add missing PrimaryMuscle enum values
-- Run this in Supabase SQL Editor
-- ==========================================

-- Add CHEST_BACK to the PrimaryMuscle enum
ALTER TYPE "PrimaryMuscle" ADD VALUE IF NOT EXISTS 'CHEST_BACK';

-- Add CALVES to the PrimaryMuscle enum
ALTER TYPE "PrimaryMuscle" ADD VALUE IF NOT EXISTS 'CALVES';

-- Verify the enum values
SELECT enum_range(NULL::"PrimaryMuscle");

-- Success message
SELECT '✅ PrimaryMuscle enum values added successfully' as status;
