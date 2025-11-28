-- ==========================================
-- SnapRep 补充缺失数据脚本
-- 基于 supabase_data.sql 中已有数据进行补充
-- 包含 exercise_scenarios 等关联表数据
-- ==========================================

-- ==========================================
-- 1. exercise_scenarios - 动作与场景关联表
-- ==========================================

DELETE FROM exercise_scenarios;

INSERT INTO exercise_scenarios (exercise_id, scenario_id, created_at)
VALUES
  -- office 场景 - 静音、小空间动作
  ('cuid_exercise_neck_stretch', 'cuid_scenario_office', NOW()),
  ('cuid_exercise_shoulder_roll', 'cuid_scenario_office', NOW()),
  ('cuid_exercise_chair_squat', 'cuid_scenario_office', NOW()),
  ('cuid_exercise_chair_dips', 'cuid_scenario_office', NOW()),
  ('cuid_exercise_chair_spinal_twist', 'cuid_scenario_office', NOW()),
  ('cuid_exercise_chair_marching', 'cuid_scenario_office', NOW()),
  ('cuid_exercise_wall_pushup', 'cuid_scenario_office', NOW()),
  ('cuid_exercise_wall_chest_stretch', 'cuid_scenario_office', NOW()),
  ('cuid_exercise_wall_squat', 'cuid_scenario_office', NOW()),

  -- home 场景 - 客厅动作
  ('cuid_exercise_sofa_incline_pushup', 'cuid_scenario_home', NOW()),
  ('cuid_exercise_sofa_stepup', 'cuid_scenario_home', NOW()),
  ('cuid_exercise_towel_overhead_stretch', 'cuid_scenario_home', NOW()),
  ('cuid_exercise_standard_pushup', 'cuid_scenario_home', NOW()),
  ('cuid_exercise_plank', 'cuid_scenario_home', NOW()),
  ('cuid_exercise_jumping_jacks', 'cuid_scenario_home', NOW()),
  ('cuid_exercise_wall_squat', 'cuid_scenario_home', NOW()),
  ('cuid_exercise_wall_pushup', 'cuid_scenario_home', NOW()),
  ('cuid_exercise_stairs_stepup', 'cuid_scenario_home', NOW()),
  ('cuid_exercise_chair_squat', 'cuid_scenario_home', NOW()),

  -- park 场景 - 户外动作
  ('cuid_exercise_standard_pushup', 'cuid_scenario_park', NOW()),
  ('cuid_exercise_plank', 'cuid_scenario_park', NOW()),
  ('cuid_exercise_burpees', 'cuid_scenario_park', NOW()),
  ('cuid_exercise_jumping_jacks', 'cuid_scenario_park', NOW()),
  ('cuid_exercise_marching_in_place', 'cuid_scenario_park', NOW()),
  ('cuid_exercise_stairs_stepup', 'cuid_scenario_park', NOW()),

  -- gym 场景 - 力量训练
  ('cuid_exercise_standard_pushup', 'cuid_scenario_gym', NOW()),
  ('cuid_exercise_plank', 'cuid_scenario_gym', NOW()),
  ('cuid_exercise_burpees', 'cuid_scenario_gym', NOW()),
  ('cuid_exercise_wall_handstand_prep', 'cuid_scenario_gym', NOW()),
  ('cuid_exercise_wall_pushup', 'cuid_scenario_gym', NOW()),
  ('cuid_exercise_bottle_bicep_curl', 'cuid_scenario_gym', NOW()),
  ('cuid_exercise_bottle_shoulder_press', 'cuid_scenario_gym', NOW()),
  ('cuid_exercise_bottle_russian_twist', 'cuid_scenario_gym', NOW()),
  ('cuid_exercise_backpack_deadlift', 'cuid_scenario_gym', NOW()),

  -- hotel 场景 - 安静、小空间
  ('cuid_exercise_neck_stretch', 'cuid_scenario_hotel', NOW()),
  ('cuid_exercise_shoulder_roll', 'cuid_scenario_hotel', NOW()),
  ('cuid_exercise_wall_pushup', 'cuid_scenario_hotel', NOW()),
  ('cuid_exercise_wall_chest_stretch', 'cuid_scenario_hotel', NOW()),
  ('cuid_exercise_wall_squat', 'cuid_scenario_hotel', NOW()),
  ('cuid_exercise_towel_overhead_stretch', 'cuid_scenario_hotel', NOW()),
  ('cuid_exercise_plank', 'cuid_scenario_hotel', NOW()),
  ('cuid_exercise_chair_squat', 'cuid_scenario_hotel', NOW())
ON CONFLICT (exercise_id, scenario_id) DO NOTHING;

-- ==========================================
-- 2. 补充 scenario_equipment - 场景与器材关联表
-- (如果你的 supabase 已经有这个表的数据,可以跳过)
-- ==========================================

-- 注意:从 supabase_data.sql 看不到 scenario_equipment 的数据
-- 如果需要补充,取消下面的注释:

/*
DELETE FROM scenario_equipment WHERE scenario_id IN (
  'cuid_scenario_office', 'cuid_scenario_home', 'cuid_scenario_park',
  'cuid_scenario_gym', 'cuid_scenario_hotel'
);

INSERT INTO scenario_equipment (scenario_id, equipment_id, is_common, created_at)
VALUES
  -- 办公室场景
  ('cuid_scenario_office', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_chair', true, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_desk', true, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_wall', true, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_water_bottle', true, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_backpack', false, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_book', false, NOW()),

  -- 居家客厅场景
  ('cuid_scenario_home', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_sofa', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_chair', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_wall', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_towel', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_stairs', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_water_bottle', false, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_book', false, NOW()),

  -- 公园户外场景
  ('cuid_scenario_park', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_bench', true, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_tree', true, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_rock', true, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_water_bottle', true, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_backpack', false, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_towel', false, NOW()),

  -- 健身房场景
  ('cuid_scenario_gym', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_gym', 'cuid_equipment_wall', true, NOW()),
  ('cuid_scenario_gym', 'cuid_equipment_bench', true, NOW()),
  ('cuid_scenario_gym', 'cuid_equipment_water_bottle', true, NOW()),
  ('cuid_scenario_gym', 'cuid_equipment_towel', true, NOW()),
  ('cuid_scenario_gym', 'cuid_equipment_backpack', false, NOW()),

  -- 酒店房间场景
  ('cuid_scenario_hotel', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_bed', true, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_chair', true, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_wall', true, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_towel', true, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_suitcase', false, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_water_bottle', false, NOW())
ON CONFLICT (scenario_id, equipment_id) DO NOTHING;
*/

-- ==========================================
-- 3. exercise_equipment - 动作与器材关联表
-- ==========================================

DELETE FROM exercise_equipment;

INSERT INTO exercise_equipment (exercise_id, equipment_id, is_required, created_at)
VALUES
  -- 墙面动作
  ('cuid_exercise_wall_pushup', 'cuid_equipment_wall', true, NOW()),
  ('cuid_exercise_wall_squat', 'cuid_equipment_wall', true, NOW()),
  ('cuid_exercise_wall_handstand_prep', 'cuid_equipment_wall', true, NOW()),
  ('cuid_exercise_wall_chest_stretch', 'cuid_equipment_wall', true, NOW()),

  -- 椅子动作
  ('cuid_exercise_chair_squat', 'cuid_equipment_chair', true, NOW()),
  ('cuid_exercise_chair_dips', 'cuid_equipment_chair', true, NOW()),
  ('cuid_exercise_chair_spinal_twist', 'cuid_equipment_chair', true, NOW()),
  ('cuid_exercise_chair_marching', 'cuid_equipment_chair', true, NOW()),

  -- 沙发动作
  ('cuid_exercise_sofa_incline_pushup', 'cuid_equipment_sofa', true, NOW()),
  ('cuid_exercise_sofa_stepup', 'cuid_equipment_sofa', true, NOW()),

  -- 水瓶动作
  ('cuid_exercise_bottle_bicep_curl', 'cuid_equipment_water_bottle', true, NOW()),
  ('cuid_exercise_bottle_russian_twist', 'cuid_equipment_water_bottle', true, NOW()),
  ('cuid_exercise_bottle_shoulder_press', 'cuid_equipment_water_bottle', true, NOW()),

  -- 背包动作
  ('cuid_exercise_backpack_deadlift', 'cuid_equipment_backpack', true, NOW()),

  -- 台阶动作
  ('cuid_exercise_stairs_stepup', 'cuid_equipment_stairs', true, NOW()),

  -- 毛巾动作
  ('cuid_exercise_towel_overhead_stretch', 'cuid_equipment_towel', true, NOW()),

  -- 徒手动作 (无器材)
  ('cuid_exercise_standard_pushup', 'cuid_equipment_none', true, NOW()),
  ('cuid_exercise_plank', 'cuid_equipment_none', true, NOW()),
  ('cuid_exercise_burpees', 'cuid_equipment_none', true, NOW()),
  ('cuid_exercise_jumping_jacks', 'cuid_equipment_none', true, NOW()),
  ('cuid_exercise_neck_stretch', 'cuid_equipment_none', true, NOW()),
  ('cuid_exercise_shoulder_roll', 'cuid_equipment_none', true, NOW()),
  ('cuid_exercise_marching_in_place', 'cuid_equipment_none', true, NOW())
ON CONFLICT (exercise_id, equipment_id) DO NOTHING;

-- ==========================================
-- 验证关联数据
-- ==========================================

SELECT
  'exercise_scenarios 关联验证' as check_name,
  s.name as scenario_name,
  COUNT(es.exercise_id) as exercise_count
FROM scenarios s
LEFT JOIN exercise_scenarios es ON s.id = es.scenario_id
GROUP BY s.id, s.name
ORDER BY exercise_count DESC;

SELECT
  'exercise_equipment 关联验证' as check_name,
  e.name as equipment_name,
  COUNT(ee.exercise_id) as exercise_count
FROM equipment e
LEFT JOIN exercise_equipment ee ON e.id = ee.equipment_id
GROUP BY e.id, e.name
ORDER BY exercise_count DESC;

-- ==========================================
-- 数据补充完成
-- ==========================================
SELECT '✅ exercise_scenarios 和 exercise_equipment 关联数据已补充完成' as status;
