-- ==========================================
-- SnapRep 完整业务流程测试数据初始化脚本
-- 支持7大业务流程 + 29个API端点的完整测试
-- ==========================================

-- 清理现有测试数据 (可选，谨慎使用)
-- DELETE FROM theme_week_participations;
-- DELETE FROM share_cards;
-- DELETE FROM session_exercises;
-- DELETE FROM workout_sessions;
-- DELETE FROM exercise_equipment;
-- DELETE FROM exercises;
-- DELETE FROM theme_weeks;
-- DELETE FROM equipment;
-- DELETE FROM scenarios;
-- DELETE FROM users WHERE email LIKE '%test%' OR email LIKE '%example%';

-- ==========================================
-- 1. 基础场景数据 (5个场景)
-- ==========================================
INSERT INTO scenarios (id, code, name, description, icon_url, is_active, display_order, created_at, updated_at)
VALUES
  (gen_random_uuid(), 'office', '办公室', 'Perfect for desk breaks', 'https://example.com/office.svg', true, 1, NOW(), NOW()),
  (gen_random_uuid(), 'living_room', '客厅/沙发', 'Relax on your couch', 'https://example.com/living_room.svg', true, 2, NOW(), NOW()),
  (gen_random_uuid(), 'park', '公园/户外', 'Outdoor fitness', 'https://example.com/park.svg', true, 3, NOW(), NOW()),
  (gen_random_uuid(), 'bedroom', '卧室/起床后', 'Morning or bedtime', 'https://example.com/bedroom.svg', true, 4, NOW(), NOW()),
  (gen_random_uuid(), 'travel', '旅途中', 'On the go workouts', 'https://example.com/travel.svg', true, 5, NOW(), NOW())
ON CONFLICT (code) DO NOTHING;

-- ==========================================
-- 2. 器材数据 (15个器材)
-- ==========================================
INSERT INTO equipment (id, code, name, category, icon_url, is_active, display_order, created_at, updated_at)
VALUES
  -- 基础器材
  (gen_random_uuid(), 'hands_free', '空手', 'BODYWEIGHT', 'https://example.com/hands_free.svg', true, 1, NOW(), NOW()),
  (gen_random_uuid(), 'chair', '椅子', 'FURNITURE', 'https://example.com/chair.svg', true, 2, NOW(), NOW()),
  (gen_random_uuid(), 'wall', '墙面', 'FURNITURE', 'https://example.com/wall.svg', true, 3, NOW(), NOW()),
  (gen_random_uuid(), 'desk', '桌子', 'FURNITURE', 'https://example.com/desk.svg', true, 4, NOW(), NOW()),
  (gen_random_uuid(), 'sofa', '沙发', 'FURNITURE', 'https://example.com/sofa.svg', true, 5, NOW(), NOW()),

  -- 便携器材
  (gen_random_uuid(), 'water_bottle', '水瓶', 'PORTABLE', 'https://example.com/water_bottle.svg', true, 6, NOW(), NOW()),
  (gen_random_uuid(), 'backpack', '背包', 'PORTABLE', 'https://example.com/backpack.svg', true, 7, NOW(), NOW()),
  (gen_random_uuid(), 'towel', '毛巾', 'PORTABLE', 'https://example.com/towel.svg', true, 8, NOW(), NOW()),
  (gen_random_uuid(), 'book', '书本', 'PORTABLE', 'https://example.com/book.svg', true, 9, NOW(), NOW()),

  -- 环境器材
  (gen_random_uuid(), 'stairs', '台阶', 'ENVIRONMENT', 'https://example.com/stairs.svg', true, 10, NOW(), NOW()),
  (gen_random_uuid(), 'bed', '床', 'FURNITURE', 'https://example.com/bed.svg', true, 11, NOW(), NOW()),
  (gen_random_uuid(), 'door', '门', 'FURNITURE', 'https://example.com/door.svg', true, 12, NOW(), NOW()),
  (gen_random_uuid(), 'tree', '树', 'ENVIRONMENT', 'https://example.com/tree.svg', true, 13, NOW(), NOW()),
  (gen_random_uuid(), 'bench', '长椅', 'FURNITURE', 'https://example.com/bench.svg', true, 14, NOW(), NOW()),
  (gen_random_uuid(), 'luggage', '行李箱', 'PORTABLE', 'https://example.com/luggage.svg', true, 15, NOW(), NOW())
ON CONFLICT (code) DO NOTHING;

-- ==========================================
-- 3. 动作数据 (50+个动作)
-- ==========================================
DO $$
DECLARE
  v_chair_id UUID;
  v_wall_id UUID;
  v_hands_free_id UUID;
  v_water_bottle_id UUID;
  v_sofa_id UUID;
  v_desk_id UUID;
  v_backpack_id UUID;
  v_towel_id UUID;
  v_stairs_id UUID;
  v_bed_id UUID;
BEGIN
  -- 获取器材ID
  SELECT id INTO v_chair_id FROM equipment WHERE code = 'chair' LIMIT 1;
  SELECT id INTO v_wall_id FROM equipment WHERE code = 'wall' LIMIT 1;
  SELECT id INTO v_hands_free_id FROM equipment WHERE code = 'hands_free' LIMIT 1;
  SELECT id INTO v_water_bottle_id FROM equipment WHERE code = 'water_bottle' LIMIT 1;
  SELECT id INTO v_sofa_id FROM equipment WHERE code = 'sofa' LIMIT 1;
  SELECT id INTO v_desk_id FROM equipment WHERE code = 'desk' LIMIT 1;
  SELECT id INTO v_backpack_id FROM equipment WHERE code = 'backpack' LIMIT 1;
  SELECT id INTO v_towel_id FROM equipment WHERE code = 'towel' LIMIT 1;
  SELECT id INTO v_stairs_id FROM equipment WHERE code = 'stairs' LIMIT 1;
  SELECT id INTO v_bed_id FROM equipment WHERE code = 'bed' LIMIT 1;

  -- 插入动作数据
  INSERT INTO exercises (id, code, name, intent_type, difficulty, primary_muscle, secondary_muscles, default_duration, default_sets, duration_type, tags, safety_notes, contraindications, is_active, created_at, updated_at)
  VALUES
    -- ========== 椅子系列动作 (10个) ==========
    -- 放松类 (RELAX)
    (gen_random_uuid(), 'chair_shoulder_roll', '椅上肩部放松', 'RELAX', 'GREEN', 'SHOULDERS', ARRAY['NECK'], 20, 1, 'TIME', ARRAY['chair', 'office', 'silent'], '保持颈部中立，不要过度后仰', '颈椎急性损伤', true, NOW(), NOW()),
    (gen_random_uuid(), 'chair_neck_stretch', '椅上颈部拉伸', 'RELAX', 'GREEN', 'NECK', ARRAY['SHOULDERS'], 20, 1, 'TIME', ARRAY['chair', 'office', 'silent'], '动作轻柔，避免强迫拉伸', '颈椎病急性期', true, NOW(), NOW()),
    (gen_random_uuid(), 'chair_back_stretch', '椅背脊椎拉伸', 'RELAX', 'GREEN', 'BACK', ARRAY['CORE'], 30, 1, 'TIME', ARRAY['chair', 'office'], '保持自然呼吸', '腰椎间盘突出急性期', true, NOW(), NOW()),

    -- 舒展类 (STRETCH)
    (gen_random_uuid(), 'chair_torso_twist', '椅上躯干扭转', 'STRETCH', 'GREEN', 'CORE', ARRAY['BACK'], 20, 1, 'TIME', ARRAY['chair', 'office'], '转动幅度适中，不要强迫', '腰椎手术史', true, NOW(), NOW()),
    (gen_random_uuid(), 'chair_leg_extension', '椅上腿部伸展', 'STRETCH', 'GREEN', 'LEGS', ARRAY['GLUTES'], 20, 1, 'TIME', ARRAY['chair'], '保持上身挺直', '膝关节炎急性期', true, NOW(), NOW()),
    (gen_random_uuid(), 'chair_hip_circles', '椅上髋部环绕', 'STRETCH', 'GREEN', 'HIPS', ARRAY['CORE'], 30, 1, 'TIME', ARRAY['chair', 'silent'], '动作缓慢控制', '髋关节损伤', true, NOW(), NOW()),

    -- 适当运动类 (CARDIO)
    (gen_random_uuid(), 'chair_marching', '椅上原地踏步', 'CARDIO', 'BLUE', 'LEGS', ARRAY['CORE'], 30, 1, 'TIME', ARRAY['chair'], '保持节奏稳定', '心脏病', true, NOW(), NOW()),
    (gen_random_uuid(), 'chair_arm_swings', '椅上手臂摆动', 'CARDIO', 'BLUE', 'ARMS', ARRAY['SHOULDERS'], 30, 1, 'TIME', ARRAY['chair', 'office'], '避免碰撞周围物品', '肩关节脱位史', true, NOW(), NOW()),

    -- 主体锻炼类 (STRENGTH)
    (gen_random_uuid(), 'chair_squat', '椅子深蹲', 'STRENGTH', 'BLUE', 'LEGS', ARRAY['GLUTES', 'CORE'], 30, 3, 'REPS', ARRAY['chair'], '膝盖不要超过脚尖', '膝关节损伤', true, NOW(), NOW()),
    (gen_random_uuid(), 'chair_dip', '椅子臂屈伸', 'STRENGTH', 'BLUE', 'ARMS', ARRAY['CHEST', 'SHOULDERS'], 30, 3, 'REPS', ARRAY['chair'], '椅子要稳固', '肩关节损伤', true, NOW(), NOW()),

    -- ========== 墙面系列动作 (8个) ==========
    -- 放松类
    (gen_random_uuid(), 'wall_child_pose', '靠墙婴儿式', 'RELAX', 'GREEN', 'BACK', ARRAY['SHOULDERS'], 30, 1, 'TIME', ARRAY['wall', 'silent'], '呼吸保持自然', '膝关节疾病', true, NOW(), NOW()),
    (gen_random_uuid(), 'wall_spinal_wave', '靠墙脊椎波浪', 'RELAX', 'GREEN', 'SPINE', ARRAY['CORE'], 30, 1, 'TIME', ARRAY['wall', 'silent'], '动作轻柔缓慢', '脊柱手术史', true, NOW(), NOW()),

    -- 舒展类
    (gen_random_uuid(), 'wall_chest_opener', '靠墙胸椎打开', 'STRETCH', 'GREEN', 'CHEST', ARRAY['SHOULDERS'], 20, 1, 'TIME', ARRAY['wall', 'silent'], '肩胛下沉不耸肩', '肩关节脱位', true, NOW(), NOW()),
    (gen_random_uuid(), 'wall_calf_stretch', '靠墙小腿拉伸', 'STRETCH', 'GREEN', 'LEGS', ARRAY[], 20, 1, 'TIME', ARRAY['wall'], '保持脚跟着地', '跟腱炎', true, NOW(), NOW()),
    (gen_random_uuid(), 'wall_hip_flexor_stretch', '靠墙髋屈肌拉伸', 'STRETCH', 'BLUE', 'HIPS', ARRAY['LEGS'], 30, 1, 'TIME', ARRAY['wall'], '后腿保持伸直', '髋关节损伤', true, NOW(), NOW()),

    -- 适当运动类
    (gen_random_uuid(), 'wall_slides', '靠墙滑动', 'CARDIO', 'BLUE', 'LEGS', ARRAY['GLUTES'], 30, 3, 'REPS', ARRAY['wall'], '保持背部贴墙', '膝关节疾病', true, NOW(), NOW()),

    -- 主体锻炼类
    (gen_random_uuid(), 'wall_push_up', '靠墙俯卧撑', 'STRENGTH', 'BLUE', 'CHEST', ARRAY['ARMS', 'CORE'], 30, 3, 'REPS', ARRAY['wall'], '保持身体一条线', '腕关节损伤', true, NOW(), NOW()),
    (gen_random_uuid(), 'wall_handstand_prep', '靠墙倒立预备', 'STRENGTH', 'RED', 'SHOULDERS', ARRAY['CORE', 'ARMS'], 20, 1, 'TIME', ARRAY['wall'], '有人指导下进行', '高血压', true, NOW(), NOW()),

    -- ========== 空手系列动作 (12个) ==========
    -- 放松类
    (gen_random_uuid(), 'neck_tilt', '颈部侧倾', 'RELAX', 'GREEN', 'NECK', ARRAY[], 20, 1, 'TIME', ARRAY['silent', 'anywhere'], '不要用手施力', '颈椎病', true, NOW(), NOW()),
    (gen_random_uuid(), 'shoulder_shrug', '肩部耸动', 'RELAX', 'GREEN', 'SHOULDERS', ARRAY['NECK'], 20, 1, 'TIME', ARRAY['silent', 'anywhere'], '动作缓慢有控制', '肩关节炎', true, NOW(), NOW()),
    (gen_random_uuid(), 'deep_breathing', '深呼吸放松', 'RELAX', 'GREEN', 'CORE', ARRAY[], 30, 1, 'TIME', ARRAY['silent', 'anywhere'], '专注呼吸节奏', '无', true, NOW(), NOW()),

    -- 舒展类
    (gen_random_uuid(), 'arm_circles', '手臂环绕', 'STRETCH', 'GREEN', 'SHOULDERS', ARRAY['ARMS'], 20, 1, 'TIME', ARRAY['anywhere'], '保持挺胸收腹', '肩关节损伤', true, NOW(), NOW()),
    (gen_random_uuid(), 'torso_side_bend', '躯干侧弯', 'STRETCH', 'GREEN', 'CORE', ARRAY['BACK'], 20, 1, 'TIME', ARRAY['anywhere'], '避免前倾后仰', '腰椎侧弯', true, NOW(), NOW()),
    (gen_random_uuid(), 'leg_swings', '腿部摆动', 'STRETCH', 'BLUE', 'HIPS', ARRAY['LEGS'], 30, 1, 'TIME', ARRAY['anywhere'], '保持平衡', '髋关节炎', true, NOW(), NOW()),

    -- 适当运动类
    (gen_random_uuid(), 'marching_in_place', '原地踏步', 'CARDIO', 'BLUE', 'LEGS', ARRAY['CORE'], 30, 1, 'TIME', ARRAY['anywhere'], '膝盖抬到舒适高度', '膝关节损伤', true, NOW(), NOW()),
    (gen_random_uuid(), 'jumping_jacks', '开合跳', 'CARDIO', 'BLUE', 'FULL_BODY', ARRAY['LEGS', 'ARMS'], 30, 1, 'TIME', ARRAY['anywhere'], '着地轻柔', '膝关节疾病', true, NOW(), NOW()),
    (gen_random_uuid(), 'high_knees', '高抬腿', 'CARDIO', 'RED', 'LEGS', ARRAY['CORE'], 20, 1, 'TIME', ARRAY['anywhere'], '保持上身挺直', '心脏病', true, NOW(), NOW()),

    -- 主体锻炼类
    (gen_random_uuid(), 'push_up', '标准俯卧撑', 'STRENGTH', 'BLUE', 'CHEST', ARRAY['ARMS', 'CORE'], 30, 3, 'REPS', ARRAY['anywhere'], '保持身体一条线', '腕关节损伤', true, NOW(), NOW()),
    (gen_random_uuid(), 'plank', '平板支撑', 'STRENGTH', 'BLUE', 'CORE', ARRAY['SHOULDERS'], 30, 1, 'TIME', ARRAY['anywhere', 'silent'], '避免塌腰', '腰椎间盘突出', true, NOW(), NOW()),
    (gen_random_uuid(), 'burpees', '波比跳', 'STRENGTH', 'RED', 'FULL_BODY', ARRAY['LEGS', 'ARMS', 'CORE'], 30, 3, 'REPS', ARRAY['anywhere'], '循序渐进', '心脏病', true, NOW(), NOW()),

    -- ========== 水瓶系列动作 (6个) ==========
    (gen_random_uuid(), 'bottle_shoulder_press', '水瓶肩上推举', 'STRENGTH', 'BLUE', 'SHOULDERS', ARRAY['ARMS'], 30, 3, 'REPS', ARRAY['water_bottle'], '选择适当重量', '肩关节损伤', true, NOW(), NOW()),
    (gen_random_uuid(), 'bottle_bicep_curl', '水瓶二头弯举', 'STRENGTH', 'BLUE', 'ARMS', ARRAY[], 30, 3, 'REPS', ARRAY['water_bottle'], '避免借力摆动', '肘关节炎', true, NOW(), NOW()),
    (gen_random_uuid(), 'bottle_russian_twist', '水瓶俄式转体', 'STRENGTH', 'BLUE', 'CORE', ARRAY['OBLIQUES'], 30, 3, 'REPS', ARRAY['water_bottle'], '保持背部挺直', '腰椎疾病', true, NOW(), NOW()),
    (gen_random_uuid(), 'bottle_squat_hold', '水瓶深蹲支撑', 'STRENGTH', 'BLUE', 'LEGS', ARRAY['GLUTES'], 20, 1, 'TIME', ARRAY['water_bottle'], '膝盖与脚尖同向', '膝关节损伤', true, NOW(), NOW()),
    (gen_random_uuid(), 'bottle_overhead_stretch', '水瓶过顶拉伸', 'STRETCH', 'GREEN', 'SHOULDERS', ARRAY['BACK'], 20, 1, 'TIME', ARRAY['water_bottle'], '动作轻柔', '肩袖损伤', true, NOW(), NOW()),
    (gen_random_uuid(), 'bottle_side_bend', '水瓶侧弯', 'STRETCH', 'GREEN', 'CORE', ARRAY['OBLIQUES'], 20, 1, 'TIME', ARRAY['water_bottle'], '避免前后倾斜', '腰椎侧弯', true, NOW(), NOW()),

    -- ========== 背包系列动作 (4个) ==========
    (gen_random_uuid(), 'backpack_deadlift', '背包硬拉', 'STRENGTH', 'BLUE', 'BACK', ARRAY['LEGS', 'GLUTES'], 30, 3, 'REPS', ARRAY['backpack'], '保持背部挺直', '腰椎间盘突出', true, NOW(), NOW()),
    (gen_random_uuid(), 'backpack_farmer_walk', '背包农夫行走', 'CARDIO', 'BLUE', 'FULL_BODY', ARRAY['CORE'], 30, 1, 'TIME', ARRAY['backpack'], '保持良好姿态', '腰背疼痛', true, NOW(), NOW()),
    (gen_random_uuid(), 'backpack_overhead_press', '背包过顶推举', 'STRENGTH', 'RED', 'SHOULDERS', ARRAY['CORE'], 30, 3, 'REPS', ARRAY['backpack'], '确保背包重量适中', '肩关节疾病', true, NOW(), NOW()),
    (gen_random_uuid(), 'backpack_squat', '背包深蹲', 'STRENGTH', 'BLUE', 'LEGS', ARRAY['GLUTES'], 30, 3, 'REPS', ARRAY['backpack'], '背包贴近身体', '膝关节疾病', true, NOW(), NOW()),

    -- ========== 沙发系列动作 (3个) ==========
    (gen_random_uuid(), 'sofa_step_up', '沙发踏步', 'CARDIO', 'BLUE', 'LEGS', ARRAY['GLUTES'], 30, 3, 'REPS', ARRAY['sofa'], '确保沙发稳固', '膝关节疾病', true, NOW(), NOW()),
    (gen_random_uuid(), 'sofa_incline_push_up', '沙发斜板俯卧撑', 'STRENGTH', 'BLUE', 'CHEST', ARRAY['ARMS'], 30, 3, 'REPS', ARRAY['sofa'], '手部位置稳定', '腕关节损伤', true, NOW(), NOW()),
    (gen_random_uuid(), 'sofa_tricep_dip', '沙发三头肌撑体', 'STRENGTH', 'BLUE', 'ARMS', ARRAY['SHOULDERS'], 30, 3, 'REPS', ARRAY['sofa'], '沙发边缘要稳固', '肩关节损伤', true, NOW(), NOW()),

    -- ========== 台阶系列动作 (3个) ==========
    (gen_random_uuid(), 'stair_step_up', '台阶踏步', 'CARDIO', 'BLUE', 'LEGS', ARRAY['GLUTES'], 30, 3, 'REPS', ARRAY['stairs'], '全脚掌着地', '膝关节炎', true, NOW(), NOW()),
    (gen_random_uuid(), 'stair_calf_raise', '台阶提踵', 'STRENGTH', 'GREEN', 'LEGS', ARRAY[], 30, 3, 'REPS', ARRAY['stairs'], '保持平衡', '跟腱炎', true, NOW(), NOW()),
    (gen_random_uuid(), 'stair_incline_push_up', '台阶斜板俯卧撑', 'STRENGTH', 'BLUE', 'CHEST', ARRAY['ARMS'], 30, 3, 'REPS', ARRAY['stairs'], '手部稳定支撑', '腕关节疾病', true, NOW(), NOW());

  -- 插入器材关联
  INSERT INTO exercise_equipment (exercise_id, equipment_id)
  SELECT e.id, v_chair_id FROM exercises e WHERE e.tags @> ARRAY['chair']
  UNION ALL
  SELECT e.id, v_wall_id FROM exercises e WHERE e.tags @> ARRAY['wall']
  UNION ALL
  SELECT e.id, v_hands_free_id FROM exercises e WHERE e.tags @> ARRAY['anywhere']
  UNION ALL
  SELECT e.id, v_water_bottle_id FROM exercises e WHERE e.tags @> ARRAY['water_bottle']
  UNION ALL
  SELECT e.id, v_sofa_id FROM exercises e WHERE e.tags @> ARRAY['sofa']
  UNION ALL
  SELECT e.id, v_backpack_id FROM exercises e WHERE e.tags @> ARRAY['backpack']
  UNION ALL
  SELECT e.id, v_stairs_id FROM exercises e WHERE e.tags @> ARRAY['stairs'];

END $$;

-- ==========================================
-- 4. 主题周数据 (5个主题周)
-- ==========================================
INSERT INTO theme_weeks (id, name, description, equipment_series, start_date, end_date, target_count, reward_description, is_active, created_at, updated_at)
VALUES
  -- 当前活跃主题周
  (gen_random_uuid(), '#椅子日', '用椅子动三下·完成解锁贴纸皮肤', 'chair',
   NOW() - INTERVAL '2 days', NOW() + INTERVAL '5 days', 3, '解锁椅子系列特殊皮肤', true, NOW(), NOW()),

  -- 即将开始的主题周
  (gen_random_uuid(), '#水瓶周', '随身水瓶变健身器材', 'water_bottle',
   NOW() + INTERVAL '5 days', NOW() + INTERVAL '12 days', 3, '解锁水瓶系列卡片', false, NOW(), NOW()),

  -- 未来主题周
  (gen_random_uuid(), '#背包周', '旅行路上不放弃健身', 'backpack',
   NOW() + INTERVAL '12 days', NOW() + INTERVAL '19 days', 5, '解锁旅行者徽章', false, NOW(), NOW()),

  -- 历史主题周
  (gen_random_uuid(), '#墙面周', '靠墙就能练出好身材', 'wall',
   NOW() - INTERVAL '14 days', NOW() - INTERVAL '7 days', 3, '墙面大师称号', false, NOW(), NOW()),

  (gen_random_uuid(), '#无器械周', '徒手训练挑战', 'hands_free',
   NOW() - INTERVAL '21 days', NOW() - INTERVAL '14 days', 7, '极简主义者徽章', false, NOW(), NOW())
ON CONFLICT DO NOTHING;

-- ==========================================
-- 5. 测试用户数据 (10个用户)
-- ==========================================
INSERT INTO users (id, email, password, role, is_anonymous, nickname, streak_count, total_sessions, created_at, updated_at)
VALUES
  -- 管理员用户
  (gen_random_uuid(), 'admin@snaprep.com', '$2b$10$YourHashedPasswordHere', 'ADMIN', false, 'SnapRep管理员', 0, 0, NOW(), NOW()),

  -- 测试用户 (邮箱用户)
  (gen_random_uuid(), 'test@snaprep.com', '$2b$10$YourHashedPasswordHere', 'USER', false, '测试用户', 7, 15, NOW(), NOW()),
  (gen_random_uuid(), 'alice@example.com', '$2b$10$YourHashedPasswordHere', 'USER', false, 'Alice', 3, 8, NOW(), NOW()),
  (gen_random_uuid(), 'bob@example.com', '$2b$10$YourHashedPasswordHere', 'USER', false, 'Bob', 5, 12, NOW(), NOW()),
  (gen_random_uuid(), 'charlie@example.com', '$2b$10$YourHashedPasswordHere', 'USER', false, 'Charlie', 1, 3, NOW(), NOW()),

  -- 匿名用户
  (gen_random_uuid(), 'anon1@temp.snaprep.com', '', 'USER', true, '游客1', 2, 5, NOW(), NOW()),
  (gen_random_uuid(), 'anon2@temp.snaprep.com', '', 'USER', true, '游客2', 0, 1, NOW(), NOW()),

  -- 高级用户 (用于测试长连击)
  (gen_random_uuid(), 'premium@example.com', '$2b$10$YourHashedPasswordHere', 'USER', false, '高级用户', 21, 45, NOW(), NOW()),

  -- 新用户 (用于测试首次体验)
  (gen_random_uuid(), 'newbie@example.com', '$2b$10$YourHashedPasswordHere', 'USER', false, '新手', 0, 0, NOW(), NOW()),

  -- 复刻测试用户
  (gen_random_uuid(), 'copytest@example.com', '$2b$10$YourHashedPasswordHere', 'USER', false, '复刻测试', 4, 10, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;

-- ==========================================
-- 6. 训练会话数据 (20个会话)
-- ==========================================
DO $$
DECLARE
  v_user1_id UUID;
  v_user2_id UUID;
  v_user3_id UUID;
  v_anon1_id UUID;
  v_exercise1_id UUID;
  v_exercise2_id UUID;
  v_exercise3_id UUID;
  v_session_id UUID;
  exercise_ids UUID[];
  i INTEGER;
BEGIN
  -- 获取用户ID
  SELECT id INTO v_user1_id FROM users WHERE email = 'test@snaprep.com' LIMIT 1;
  SELECT id INTO v_user2_id FROM users WHERE email = 'alice@example.com' LIMIT 1;
  SELECT id INTO v_user3_id FROM users WHERE email = 'bob@example.com' LIMIT 1;
  SELECT id INTO v_anon1_id FROM users WHERE email = 'anon1@temp.snaprep.com' LIMIT 1;

  -- 获取一些动作ID
  SELECT ARRAY_AGG(id) INTO exercise_ids FROM exercises LIMIT 20;

  -- 为每个用户创建多个会话
  FOR i IN 1..5 LOOP
    -- 用户1的会话
    INSERT INTO workout_sessions (id, user_id, intent_type, difficulty, total_duration, status, completed_at, created_at, updated_at)
    VALUES (gen_random_uuid(), v_user1_id,
           CASE WHEN i % 4 = 0 THEN 'RELAX' WHEN i % 4 = 1 THEN 'STRETCH' WHEN i % 4 = 2 THEN 'CARDIO' ELSE 'STRENGTH' END,
           CASE WHEN i % 3 = 0 THEN 'GREEN' WHEN i % 3 = 1 THEN 'BLUE' ELSE 'RED' END,
           60, 'COMPLETED', NOW() - INTERVAL '1 day' * i, NOW() - INTERVAL '1 day' * i, NOW());

    -- 用户2的会话
    INSERT INTO workout_sessions (id, user_id, intent_type, difficulty, total_duration, status, completed_at, created_at, updated_at)
    VALUES (gen_random_uuid(), v_user2_id,
           CASE WHEN i % 4 = 0 THEN 'STRETCH' WHEN i % 4 = 1 THEN 'CARDIO' WHEN i % 4 = 2 THEN 'STRENGTH' ELSE 'RELAX' END,
           CASE WHEN i % 3 = 0 THEN 'BLUE' WHEN i % 3 = 1 THEN 'GREEN' ELSE 'RED' END,
           90, 'COMPLETED', NOW() - INTERVAL '2 days' * i, NOW() - INTERVAL '2 days' * i, NOW());
  END LOOP;

  -- 创建一些未完成的会话
  INSERT INTO workout_sessions (id, user_id, intent_type, difficulty, total_duration, status, created_at, updated_at)
  VALUES
    (gen_random_uuid(), v_user3_id, 'STRETCH', 'GREEN', 60, 'IN_PROGRESS', NOW() - INTERVAL '1 hour', NOW()),
    (gen_random_uuid(), v_anon1_id, 'RELAX', 'GREEN', 60, 'CREATED', NOW() - INTERVAL '30 minutes', NOW());

  -- 为已完成的会话添加动作
  FOR v_session_id IN (SELECT id FROM workout_sessions WHERE status = 'COMPLETED' LIMIT 10)
  LOOP
    -- 每个会话添加3个动作
    INSERT INTO session_exercises (id, session_id, exercise_id, order_in_session, duration, sets, is_completed, created_at, updated_at)
    VALUES
      (gen_random_uuid(), v_session_id, exercise_ids[1], 1, 20, 1, true, NOW(), NOW()),
      (gen_random_uuid(), v_session_id, exercise_ids[2], 2, 20, 1, true, NOW(), NOW()),
      (gen_random_uuid(), v_session_id, exercise_ids[3], 3, 20, 1, true, NOW(), NOW());
  END LOOP;
END $$;

-- ==========================================
-- 7. 分享卡片数据 (15张卡片)
-- ==========================================
DO $$
DECLARE
  v_user1_id UUID;
  v_user2_id UUID;
  v_user3_id UUID;
  session_ids UUID[];
  equipment_codes TEXT[] := ARRAY['chair', 'wall', 'hands_free', 'water_bottle', 'sofa'];
  rarity_levels TEXT[] := ARRAY['COMMON', 'UNCOMMON', 'RARE', 'EPIC', 'LEGENDARY'];
  i INTEGER;
BEGIN
  -- 获取用户ID
  SELECT id INTO v_user1_id FROM users WHERE email = 'test@snaprep.com' LIMIT 1;
  SELECT id INTO v_user2_id FROM users WHERE email = 'alice@example.com' LIMIT 1;
  SELECT id INTO v_user3_id FROM users WHERE email = 'bob@example.com' LIMIT 1;

  -- 获取已完成的会话ID
  SELECT ARRAY_AGG(id) INTO session_ids FROM workout_sessions WHERE status = 'COMPLETED' LIMIT 15;

  -- 为每个用户创建卡片
  FOR i IN 1..15 LOOP
    INSERT INTO share_cards (id, user_id, session_id, equipment_code, rarity_level, card_image_url, deep_link, view_count, share_count, created_at, updated_at)
    VALUES (
      gen_random_uuid(),
      CASE WHEN i % 3 = 0 THEN v_user1_id WHEN i % 3 = 1 THEN v_user2_id ELSE v_user3_id END,
      session_ids[i],
      equipment_codes[(i % 5) + 1],
      rarity_levels[(i % 5) + 1],
      'https://storage.supabase.co/snaprep/cards/' || gen_random_uuid() || '.png',
      'snaprep://workout/copy/' || session_ids[i],
      FLOOR(RANDOM() * 100),
      FLOOR(RANDOM() * 20),
      NOW() - INTERVAL '1 day' * FLOOR(RANDOM() * 30),
      NOW()
    );
  END LOOP;
END $$;

-- ==========================================
-- 8. 主题周参与数据 (测试不同状态)
-- ==========================================
DO $$
DECLARE
  v_user1_id UUID;
  v_user2_id UUID;
  v_user3_id UUID;
  v_theme_week_id UUID;
BEGIN
  -- 获取用户ID
  SELECT id INTO v_user1_id FROM users WHERE email = 'test@snaprep.com' LIMIT 1;
  SELECT id INTO v_user2_id FROM users WHERE email = 'alice@example.com' LIMIT 1;
  SELECT id INTO v_user3_id FROM users WHERE email = 'bob@example.com' LIMIT 1;

  -- 获取当前活跃主题周ID
  SELECT id INTO v_theme_week_id FROM theme_weeks WHERE is_active = true LIMIT 1;

  -- 创建不同状态的参与记录
  INSERT INTO theme_week_participations (id, user_id, theme_week_id, target_exercises, exercises_completed, progress_percent, status, completed_at, created_at, updated_at)
  VALUES
    -- 已完成
    (gen_random_uuid(), v_user1_id, v_theme_week_id, 3, 3, 100.0, 'COMPLETED', NOW() - INTERVAL '1 day', NOW() - INTERVAL '3 days', NOW()),

    -- 进行中
    (gen_random_uuid(), v_user2_id, v_theme_week_id, 3, 2, 66.7, 'ACTIVE', NULL, NOW() - INTERVAL '2 days', NOW()),

    -- 刚开始
    (gen_random_uuid(), v_user3_id, v_theme_week_id, 3, 1, 33.3, 'ACTIVE', NULL, NOW() - INTERVAL '1 day', NOW());
END $$;

-- ==========================================
-- 9. 用户偏好数据
-- ==========================================
DO $$
DECLARE
  v_user1_id UUID;
  v_user2_id UUID;
  equipment_codes TEXT[] := ARRAY['chair', 'wall', 'hands_free', 'water_bottle'];
  intent_types TEXT[] := ARRAY['RELAX', 'STRETCH', 'CARDIO', 'STRENGTH'];
  i INTEGER;
BEGIN
  -- 获取用户ID
  SELECT id INTO v_user1_id FROM users WHERE email = 'test@snaprep.com' LIMIT 1;
  SELECT id INTO v_user2_id FROM users WHERE email = 'alice@example.com' LIMIT 1;

  -- 创建用户偏好数据 (AI推荐系统训练数据)
  FOR i IN 1..20 LOOP
    INSERT INTO user_preferences (id, user_id, equipment_code, intent_type, preference_score, usage_count, last_used, created_at, updated_at)
    VALUES (
      gen_random_uuid(),
      CASE WHEN i % 2 = 0 THEN v_user1_id ELSE v_user2_id END,
      equipment_codes[(i % 4) + 1],
      intent_types[(i % 4) + 1],
      RANDOM() * 10, -- 0-10分偏好评分
      FLOOR(RANDOM() * 20) + 1, -- 1-20次使用次数
      NOW() - INTERVAL '1 day' * FLOOR(RANDOM() * 30),
      NOW() - INTERVAL '30 days',
      NOW()
    );
  END LOOP;
END $$;

-- ==========================================
-- 10. 稀有度统计数据 (用于计算卡片稀有度)
-- ==========================================
INSERT INTO rarity_stats (id, equipment_code, usage_count_7d, usage_count_30d, global_percentile, rarity_level, last_calculated, created_at, updated_at)
VALUES
  -- 常见器材
  ('chair_stats', 'chair', 1500, 6000, 85.0, 'COMMON', NOW(), NOW(), NOW()),
  ('hands_free_stats', 'hands_free', 2000, 8000, 90.0, 'COMMON', NOW(), NOW(), NOW()),
  ('wall_stats', 'wall', 800, 3200, 70.0, 'UNCOMMON', NOW(), NOW(), NOW()),

  -- 稀有器材
  ('water_bottle_stats', 'water_bottle', 200, 800, 45.0, 'RARE', NOW(), NOW(), NOW()),
  ('backpack_stats', 'backpack', 50, 200, 15.0, 'EPIC', NOW(), NOW(), NOW()),
  ('luggage_stats', 'luggage', 10, 40, 5.0, 'LEGENDARY', NOW(), NOW(), NOW()),

  -- 其他器材
  ('sofa_stats', 'sofa', 300, 1200, 55.0, 'UNCOMMON', NOW(), NOW(), NOW()),
  ('stairs_stats', 'stairs', 150, 600, 30.0, 'RARE', NOW(), NOW(), NOW()),
  ('bed_stats', 'bed', 100, 400, 25.0, 'RARE', NOW(), NOW(), NOW()),
  ('desk_stats', 'desk', 400, 1600, 60.0, 'UNCOMMON', NOW(), NOW(), NOW())
ON CONFLICT (id) DO UPDATE SET
  usage_count_7d = EXCLUDED.usage_count_7d,
  usage_count_30d = EXCLUDED.usage_count_30d,
  global_percentile = EXCLUDED.global_percentile,
  rarity_level = EXCLUDED.rarity_level,
  last_calculated = EXCLUDED.last_calculated,
  updated_at = NOW();

-- ==========================================
-- 11. 每日训练统计数据
-- ==========================================
DO $$
DECLARE
  v_user1_id UUID;
  v_user2_id UUID;
  i INTEGER;
BEGIN
  -- 获取用户ID
  SELECT id INTO v_user1_id FROM users WHERE email = 'test@snaprep.com' LIMIT 1;
  SELECT id INTO v_user2_id FROM users WHERE email = 'alice@example.com' LIMIT 1;

  -- 创建过去30天的训练统计
  FOR i IN 0..29 LOOP
    INSERT INTO daily_trainings (id, user_id, training_date, sessions_count, total_duration, exercises_completed, difficulty_distribution, created_at, updated_at)
    VALUES (
      gen_random_uuid(),
      v_user1_id,
      (NOW() - INTERVAL '1 day' * i)::DATE,
      CASE WHEN i % 7 = 0 THEN 0 ELSE FLOOR(RANDOM() * 3) + 1 END, -- 周日休息
      CASE WHEN i % 7 = 0 THEN 0 ELSE FLOOR(RANDOM() * 120) + 60 END,
      CASE WHEN i % 7 = 0 THEN 0 ELSE FLOOR(RANDOM() * 9) + 3 END,
      CASE WHEN i % 7 = 0 THEN '{}' ELSE '{"GREEN": 1, "BLUE": 1, "RED": 0}' END,
      NOW(),
      NOW()
    );

    -- 用户2的数据 (参与度较低)
    IF i % 3 = 0 THEN
      INSERT INTO daily_trainings (id, user_id, training_date, sessions_count, total_duration, exercises_completed, difficulty_distribution, created_at, updated_at)
      VALUES (
        gen_random_uuid(),
        v_user2_id,
        (NOW() - INTERVAL '1 day' * i)::DATE,
        1,
        60,
        3,
        '{"GREEN": 2, "BLUE": 1, "RED": 0}',
        NOW(),
        NOW()
      );
    END IF;
  END LOOP;
END $$;

-- ==========================================
-- 验证数据插入结果
-- ==========================================
SELECT
  '基础数据统计' as category,
  (SELECT COUNT(*) FROM scenarios) as scenarios_count,
  (SELECT COUNT(*) FROM equipment) as equipment_count,
  (SELECT COUNT(*) FROM exercises) as exercises_count,
  (SELECT COUNT(*) FROM theme_weeks) as theme_weeks_count

UNION ALL

SELECT
  '用户数据统计' as category,
  (SELECT COUNT(*) FROM users) as users_count,
  (SELECT COUNT(*) FROM workout_sessions) as sessions_count,
  (SELECT COUNT(*) FROM session_exercises) as session_exercises_count,
  (SELECT COUNT(*) FROM share_cards) as cards_count

UNION ALL

SELECT
  '活动数据统计' as category,
  (SELECT COUNT(*) FROM theme_week_participations) as participations_count,
  (SELECT COUNT(*) FROM user_preferences) as preferences_count,
  (SELECT COUNT(*) FROM rarity_stats) as rarity_stats_count,
  (SELECT COUNT(*) FROM daily_trainings) as daily_trainings_count;

-- ==========================================
-- 测试数据验证查询 (验证关键业务流程数据)
-- ==========================================

-- 验证推荐系统数据完整性
SELECT
  '推荐系统数据验证' as check_name,
  COUNT(DISTINCT intent_type) as intent_types_count,
  COUNT(DISTINCT difficulty) as difficulty_levels_count,
  COUNT(DISTINCT primary_muscle) as muscle_groups_count,
  COUNT(*) as total_exercises
FROM exercises WHERE is_active = true;

-- 验证主题周数据
SELECT
  '主题周数据验证' as check_name,
  name,
  is_active,
  start_date::date,
  end_date::date,
  target_count
FROM theme_weeks
ORDER BY start_date DESC;

-- 验证用户训练完整性
SELECT
  '用户训练数据验证' as check_name,
  u.email,
  u.streak_count,
  COUNT(ws.id) as session_count,
  COUNT(sc.id) as card_count
FROM users u
LEFT JOIN workout_sessions ws ON u.id = ws.user_id
LEFT JOIN share_cards sc ON u.id = sc.user_id
WHERE u.email LIKE '%snaprep.com' OR u.email LIKE '%example.com'
GROUP BY u.id, u.email, u.streak_count
ORDER BY session_count DESC;

-- 验证器材和动作关联
SELECT
  '器材动作关联验证' as check_name,
  e.name as equipment_name,
  COUNT(ex.id) as exercises_count,
  string_agg(DISTINCT ex.intent_type, ', ') as available_intents
FROM equipment e
LEFT JOIN exercise_equipment ee ON e.id = ee.equipment_id
LEFT JOIN exercises ex ON ee.exercise_id = ex.id
WHERE e.is_active = true
GROUP BY e.id, e.name
ORDER BY exercises_count DESC;

COMMIT;