-- ==========================================
-- SnapRep E2E测试数据初始化脚本
-- ==========================================

-- 1. 插入场景数据
INSERT INTO scenarios (id, code, name, description, icon_url, is_active, display_order, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'office', 'Office', 'Perfect for desk breaks', 'https://example.com/office.svg', true, 1, NOW(), NOW()),
  (gen_random_uuid(), 'living_room', 'Living Room', 'Relax on your couch', 'https://example.com/living_room.svg', true, 2, NOW(), NOW()),
  (gen_random_uuid(), 'park', 'Park', 'Outdoor fitness', 'https://example.com/park.svg', true, 3, NOW(), NOW()),
  (gen_random_uuid(), 'bedroom', 'Bedroom', 'Morning or bedtime', 'https://example.com/bedroom.svg', true, 4, NOW(), NOW())
ON CONFLICT (code) DO NOTHING;

-- 2. 插入器材数据
INSERT INTO equipment (id, code, name, category, icon_url, is_active, display_order, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'hands_free', 'No Equipment', 'BODYWEIGHT', 'https://example.com/hands_free.svg', true, 1, NOW(), NOW()),
  (gen_random_uuid(), 'chair', 'Chair', 'FURNITURE', 'https://example.com/chair.svg', true, 2, NOW(), NOW()),
  (gen_random_uuid(), 'wall', 'Wall', 'FURNITURE', 'https://example.com/wall.svg', true, 3, NOW(), NOW()),
  (gen_random_uuid(), 'desk', 'Desk', 'FURNITURE', 'https://example.com/desk.svg', true, 4, NOW(), NOW()),
  (gen_random_uuid(), 'sofa', 'Sofa', 'FURNITURE', 'https://example.com/sofa.svg', true, 5, NOW(), NOW())
ON CONFLICT (code) DO NOTHING;

-- 3. 插入动作数据 (精选30个测试动作)
DO $$
DECLARE
  v_chair_id UUID;
  v_wall_id UUID;
  v_hands_free_id UUID;
  v_office_id UUID;
BEGIN
  -- 获取器材ID
  SELECT id INTO v_chair_id FROM equipment WHERE code = 'chair' LIMIT 1;
  SELECT id INTO v_wall_id FROM equipment WHERE code = 'wall' LIMIT 1;
  SELECT id INTO v_hands_free_id FROM equipment WHERE code = 'hands_free' LIMIT 1;
  SELECT id INTO v_office_id FROM scenarios WHERE code = 'office' LIMIT 1;

  -- 插入动作
  INSERT INTO exercises (id, code, name, intent_type, difficulty, primary_muscle, secondary_muscles, default_duration, default_sets, duration_type, tags, is_active, created_at, updated_at)
  VALUES
    -- 椅子动作 (STRETCH, GREEN)
    (gen_random_uuid(), 'chair_shoulder_roll', 'Chair Shoulder Roll', 'STRETCH', 'GREEN', 'SHOULDERS', ARRAY['NECK'], 20, 1, 'TIME', ARRAY['chair', 'office', 'silent'], true, NOW(), NOW()),
    (gen_random_uuid(), 'chair_torso_twist', 'Seated Torso Twist', 'STRETCH', 'GREEN', 'CORE', ARRAY['BACK'], 20, 1, 'TIME', ARRAY['chair', 'office'], true, NOW(), NOW()),
    (gen_random_uuid(), 'chair_leg_extension', 'Seated Leg Extension', 'STRETCH', 'GREEN', 'LEGS', ARRAY['GLUTES'], 20, 1, 'TIME', ARRAY['chair'], true, NOW(), NOW()),

    -- 墙壁动作 (STRETCH, GREEN)
    (gen_random_uuid(), 'wall_chest_opener', 'Wall Chest Opener', 'STRETCH', 'GREEN', 'CHEST', ARRAY['SHOULDERS'], 20, 1, 'TIME', ARRAY['wall', 'silent'], true, NOW(), NOW()),
    (gen_random_uuid(), 'wall_calf_stretch', 'Wall Calf Stretch', 'STRETCH', 'GREEN', 'LEGS', ARRAY[], 20, 1, 'TIME', ARRAY['wall'], true, NOW(), NOW()),

    -- 无器材动作 (STRETCH, GREEN)
    (gen_random_uuid(), 'neck_tilt', 'Neck Tilt', 'STRETCH', 'GREEN', 'NECK', ARRAY[], 20, 1, 'TIME', ARRAY['silent', 'anywhere'], true, NOW(), NOW()),
    (gen_random_uuid(), 'arm_circles', 'Arm Circles', 'STRETCH', 'GREEN', 'SHOULDERS', ARRAY['ARMS'], 20, 1, 'TIME', ARRAY['anywhere'], true, NOW(), NOW()),

    -- 椅子动作 (STRENGTH, BLUE)
    (gen_random_uuid(), 'chair_squat', 'Chair Squat', 'STRENGTH', 'BLUE', 'LEGS', ARRAY['GLUTES', 'CORE'], 30, 3, 'REPS', ARRAY['chair'], true, NOW(), NOW()),
    (gen_random_uuid(), 'chair_dip', 'Chair Dips', 'STRENGTH', 'BLUE', 'ARMS', ARRAY['CHEST', 'SHOULDERS'], 30, 3, 'REPS', ARRAY['chair'], true, NOW(), NOW()),

    -- 无器材动作 (STRENGTH, BLUE)
    (gen_random_uuid(), 'push_up', 'Push-ups', 'STRENGTH', 'BLUE', 'CHEST', ARRAY['ARMS', 'CORE'], 30, 3, 'REPS', ARRAY['anywhere'], true, NOW(), NOW()),
    (gen_random_uuid(), 'plank', 'Plank Hold', 'STRENGTH', 'BLUE', 'CORE', ARRAY['SHOULDERS'], 30, 1, 'TIME', ARRAY['anywhere', 'silent'], true, NOW(), NOW())
  ON CONFLICT (code) DO NOTHING;
END $$;

-- 4. 插入主题周数据
INSERT INTO theme_weeks (id, name, description, equipment_series, start_date, end_date, target_count, reward_description, is_active, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'Chair Champion Week', 'Complete 3 chair workouts this week!', 'chair',
   NOW(), NOW() + INTERVAL '7 days', 3, 'Unlock special chair workout card skin', true, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- 5. 创建测试用户
INSERT INTO users (id, email, password, role, is_anonymous, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'test@snaprep.com', '$2b$10$abcdefghijklmnopqrstuvwxyz', 'USER', false, NOW(), NOW()),
  (gen_random_uuid(), 'anonymous@snaprep.com', '', 'USER', true, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- 6. 验证数据插入
SELECT
  (SELECT COUNT(*) FROM scenarios) as scenarios_count,
  (SELECT COUNT(*) FROM equipment) as equipment_count,
  (SELECT COUNT(*) FROM exercises) as exercises_count,
  (SELECT COUNT(*) FROM theme_weeks) as theme_weeks_count,
  (SELECT COUNT(*) FROM users WHERE email LIKE '%snaprep.com') as test_users_count;
