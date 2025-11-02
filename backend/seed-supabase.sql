-- SnapRep Database Seed SQL Script
-- 可以直接在Supabase SQL Editor中执行

-- 首先创建枚举类型（如果不存在）
DO $$ BEGIN
    CREATE TYPE "NoiseLevel" AS ENUM ('SILENT', 'QUIET', 'NORMAL');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "SpaceSize" AS ENUM ('SMALL', 'MEDIUM', 'LARGE');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "EquipmentCategory" AS ENUM ('NONE', 'FURNITURE', 'WALL', 'BOTTLE', 'BAG', 'STAIRS', 'FABRIC', 'STICK', 'OUTDOOR', 'CREATIVE');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "PrimaryMuscle" AS ENUM ('CHEST', 'BACK', 'LEGS', 'GLUTES', 'SHOULDERS', 'ARMS', 'CORE', 'FULL_BODY', 'NECK_SHOULDER');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "IntentType" AS ENUM ('RELAX', 'STRETCH', 'MODERATE', 'STRENGTH');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "Difficulty" AS ENUM ('GREEN', 'BLUE', 'RED');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "DurationType" AS ENUM ('TIME', 'REPS');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "RarityLevel" AS ENUM ('COMMON', 'UNCOMMON', 'RARE', 'EPIC', 'LEGENDARY');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE "DataSource" AS ENUM ('WEEKLY_TABLE', 'ON_THE_FLY_ESTIMATE');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 清理现有数据（按依赖关系倒序）
DELETE FROM "exercise_equipment";
DELETE FROM "exercise_scenarios";
DELETE FROM "rarity_table";
DELETE FROM "exercises";
DELETE FROM "equipment";
DELETE FROM "scenarios";
DELETE FROM "users" WHERE email = 'test@snaprep.app';  -- 根据email删除测试用户

-- 插入场景数据
INSERT INTO "scenarios" (id, code, name, noise_tolerance, space_requirement, icon_url, is_active, created_at, updated_at) VALUES
('cuid_scenario_office', 'office', 'Office', 'SILENT', 'SMALL', '/icons/office.svg', true, NOW(), NOW()),
('cuid_scenario_home', 'home', 'Home', 'NORMAL', 'MEDIUM', '/icons/home.svg', true, NOW(), NOW()),
('cuid_scenario_gym', 'gym', 'Gym', 'NORMAL', 'LARGE', '/icons/gym.svg', true, NOW(), NOW()),
('cuid_scenario_park', 'park', 'Park', 'NORMAL', 'LARGE', '/icons/park.svg', true, NOW(), NOW());

-- 插入器材数据
INSERT INTO "equipment" (id, code, name, category, recognizable, recognition_labels, recognition_confidence, icon_url, display_order, is_active, created_at, updated_at) VALUES
('cuid_equipment_none', 'none', 'No Equipment', 'NONE', false, '{}', 0.85, '/equipment/none.jpg', 0, true, NOW(), NOW()),
('cuid_equipment_chair', 'chair', 'Chair', 'FURNITURE', true, '{"chair", "stool", "seat"}', 0.85, '/equipment/chair.jpg', 1, true, NOW(), NOW()),
('cuid_equipment_wall', 'wall', 'Wall', 'WALL', true, '{"wall"}', 0.85, '/equipment/wall.jpg', 2, true, NOW(), NOW()),
('cuid_equipment_bottle', 'bottle', 'Water Bottle', 'BOTTLE', true, '{"bottle", "water bottle"}', 0.85, '/equipment/bottle.jpg', 3, true, NOW(), NOW());

-- 插入练习数据
INSERT INTO "exercises" (id, code, name, primary_muscle, secondary_muscles, intent_type, difficulty, description, default_duration, default_sets, duration_type, demo_image_url, tags, is_active, created_at, updated_at) VALUES
(
  'cuid_exercise_wall_chest_opener',
  'wall_chest_opener',
  'Wall Chest Opener',
  'NECK_SHOULDER',
  '{"CHEST", "SHOULDERS"}',
  'STRETCH',
  'GREEN',
  '{"keyPoints": ["Keep spine neutral", "Arms extended upward", "Breathe naturally"], "steps": ["Stand against wall", "Raise arms overhead", "Hold for 20 seconds"], "warnings": ["Keep neck neutral, no hyperextension", "Lower shoulders, no shrugging"]}',
  20,
  1,
  'TIME',
  '/demos/wall_chest_opener.jpg',
  '{"standing", "wall", "stretch", "silent", "small_space"}',
  true,
  NOW(),
  NOW()
),
(
  'cuid_exercise_chair_dips',
  'chair_dips',
  'Chair Dips',
  'ARMS',
  '{"CHEST", "SHOULDERS"}',
  'STRENGTH',
  'BLUE',
  '{"keyPoints": ["Keep body close to chair", "Lower with control", "Push through palms"], "steps": ["Sit on chair edge", "Hands beside hips", "Lower body down", "Push back up"], "warnings": ["No shoulder impingement history", "Ensure chair stability"]}',
  12,
  3,
  'REPS',
  '/demos/chair_dips.jpg',
  '{"sitting", "chair", "strength", "arms"}',
  true,
  NOW(),
  NOW()
),
(
  'cuid_exercise_bottle_press',
  'bottle_overhead_press',
  'Bottle Overhead Press',
  'SHOULDERS',
  '{"ARMS", "CORE"}',
  'MODERATE',
  'GREEN',
  '{"keyPoints": ["Keep core engaged", "Press straight overhead", "Control the weight"], "steps": ["Hold bottle with both hands", "Press overhead", "Lower with control", "Repeat"], "warnings": ["Use filled water bottle (500ml-1L)", "Ensure cap is tightly closed"]}',
  10,
  2,
  'REPS',
  '/demos/bottle_press.jpg',
  '{"standing", "bottle", "strength", "shoulders"}',
  true,
  NOW(),
  NOW()
),
(
  'cuid_exercise_bodyweight_squat',
  'bodyweight_squat',
  'Bodyweight Squat',
  'LEGS',
  '{"GLUTES", "CORE"}',
  'STRENGTH',
  'GREEN',
  '{"keyPoints": ["Keep chest up", "Knees track over toes", "Full range of motion"], "steps": ["Stand with feet shoulder-width apart", "Lower by bending knees", "Descend until thighs parallel", "Push through heels to stand"], "warnings": ["Avoid knee cave", "Keep weight on heels"]}',
  15,
  3,
  'REPS',
  '/demos/bodyweight_squat.jpg',
  '{"standing", "bodyweight", "strength", "legs"}',
  true,
  NOW(),
  NOW()
);

-- 创建练习-场景关联
INSERT INTO "exercise_scenarios" (exercise_id, scenario_id, created_at) VALUES
('cuid_exercise_wall_chest_opener', 'cuid_scenario_office', NOW()),
('cuid_exercise_wall_chest_opener', 'cuid_scenario_home', NOW()),
('cuid_exercise_chair_dips', 'cuid_scenario_office', NOW()),
('cuid_exercise_chair_dips', 'cuid_scenario_home', NOW()),
('cuid_exercise_bottle_press', 'cuid_scenario_home', NOW()),
('cuid_exercise_bottle_press', 'cuid_scenario_gym', NOW()),
('cuid_exercise_bottle_press', 'cuid_scenario_park', NOW()),
('cuid_exercise_bodyweight_squat', 'cuid_scenario_office', NOW()),
('cuid_exercise_bodyweight_squat', 'cuid_scenario_home', NOW()),
('cuid_exercise_bodyweight_squat', 'cuid_scenario_gym', NOW()),
('cuid_exercise_bodyweight_squat', 'cuid_scenario_park', NOW());

-- 创建练习-器材关联
INSERT INTO "exercise_equipment" (exercise_id, equipment_id, is_required, created_at) VALUES
('cuid_exercise_wall_chest_opener', 'cuid_equipment_wall', true, NOW()),
('cuid_exercise_chair_dips', 'cuid_equipment_chair', true, NOW()),
('cuid_exercise_bottle_press', 'cuid_equipment_bottle', true, NOW()),
('cuid_exercise_bodyweight_squat', 'cuid_equipment_none', true, NOW());

-- 创建测试用户（使用正确的UUID格式）
INSERT INTO "users" (
  id, email, name, avatar_url, language, theme,
  total_workouts, total_duration_sec, current_streak, longest_streak,
  preferred_intents, preferred_difficulty, preferred_duration, avoid_equipment,
  streak_reminder, theme_week_reminder, hide_real_photos, auto_blur_faces, allow_data_sync,
  created_at, updated_at
) VALUES (
  gen_random_uuid(),  -- 生成随机UUID
  'test@snaprep.app',
  'Test User',
  '/avatars/test.jpg',
  'zh',
  'auto',
  0,
  0,
  0,
  0,
  '{"STRETCH", "MODERATE"}',
  'GREEN',
  300,
  '{}',
  true,
  true,
  true,
  true,
  false,
  NOW(),
  NOW()
);

-- 创建稀有度表数据
INSERT INTO "rarity_table" (
  id, equipment_id, equipment_code, week_start,
  rarity_score, rarity_level, data_source, created_at, updated_at
) VALUES
(
  'cuid_rarity_none',
  'cuid_equipment_none',
  'none',
  DATE_TRUNC('week', NOW()),
  0.95,
  'COMMON',
  'WEEKLY_TABLE',
  NOW(),
  NOW()
),
(
  'cuid_rarity_chair',
  'cuid_equipment_chair',
  'chair',
  DATE_TRUNC('week', NOW()),
  0.65,
  'COMMON',
  'WEEKLY_TABLE',
  NOW(),
  NOW()
),
(
  'cuid_rarity_wall',
  'cuid_equipment_wall',
  'wall',
  DATE_TRUNC('week', NOW()),
  0.45,
  'UNCOMMON',
  'WEEKLY_TABLE',
  NOW(),
  NOW()
),
(
  'cuid_rarity_bottle',
  'cuid_equipment_bottle',
  'bottle',
  DATE_TRUNC('week', NOW()),
  0.25,
  'UNCOMMON',
  'WEEKLY_TABLE',
  NOW(),
  NOW()
);

-- 显示插入结果统计
SELECT
  'scenarios' as table_name,
  COUNT(*) as record_count
FROM "scenarios"
WHERE code IN ('office', 'home', 'gym', 'park')

UNION ALL

SELECT
  'equipment' as table_name,
  COUNT(*) as record_count
FROM "equipment"
WHERE code IN ('none', 'chair', 'wall', 'bottle')

UNION ALL

SELECT
  'exercises' as table_name,
  COUNT(*) as record_count
FROM "exercises"
WHERE code IN ('wall_chest_opener', 'chair_dips', 'bottle_overhead_press', 'bodyweight_squat')

UNION ALL

SELECT
  'exercise_scenarios' as table_name,
  COUNT(*) as record_count
FROM "exercise_scenarios"
WHERE exercise_id IN (
  'cuid_exercise_wall_chest_opener',
  'cuid_exercise_chair_dips',
  'cuid_exercise_bottle_press',
  'cuid_exercise_bodyweight_squat'
)

UNION ALL

SELECT
  'exercise_equipment' as table_name,
  COUNT(*) as record_count
FROM "exercise_equipment"
WHERE exercise_id IN (
  'cuid_exercise_wall_chest_opener',
  'cuid_exercise_chair_dips',
  'cuid_exercise_bottle_press',
  'cuid_exercise_bodyweight_squat'
)

UNION ALL

SELECT
  'rarity_table' as table_name,
  COUNT(*) as record_count
FROM "rarity_table"
WHERE equipment_code IN ('none', 'chair', 'wall', 'bottle');

-- 成功提示
SELECT '🎉 SnapRep种子数据执行成功！数据已插入到Supabase数据库。' as message;