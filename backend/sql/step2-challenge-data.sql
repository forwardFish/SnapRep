-- ==========================================
-- Step 2: Challenge 挑战系统数据生成
-- ==========================================
-- 前置条件：equipment 表必须先有数据 (执行 step1-equipment-data.sql)

-- 验证 equipment 数据是否存在
DO $$
DECLARE
    equipment_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO equipment_count FROM equipment WHERE is_active = true;

    IF equipment_count < 10 THEN
        RAISE EXCEPTION 'Equipment 表数据不足 (当前: %, 需要: >=10). 请先执行 step1-equipment-data.sql', equipment_count;
    END IF;

    RAISE NOTICE 'Equipment 数据验证成功，共 % 条记录', equipment_count;
END $$;

-- 清理旧的挑战数据 (按依赖关系顺序)
DELETE FROM challenge_completions;
DELETE FROM challenge_items;

-- 插入挑战数据 (12个挑战，使用3x4网格展示，英文界面，简化设计)
INSERT INTO challenge_items (
  id, code, title,
  equipment_id, time_limit, target_count,
  description, instructions,
  is_popular, trending_score, is_active, display_order,
  created_at, updated_at
)
VALUES
  -- Row 1 (Easy challenges)
  ('cuid_challenge_umbrella', 'umbrella_challenge', 'Umbrella Fitness Challenge',
   'cuid_equipment_umbrella', NULL, 3,
   'Complete workouts using an umbrella as your fitness tool', 'Use the umbrella for resistance training and balance exercises. Focus on proper posture and controlled movements.',
   true, 0.85, true, 1, NOW(), NOW()),

  ('cuid_challenge_book', 'book_challenge', 'Book Balance Challenge',
   'cuid_equipment_book', 10, 3,
   'Use a book as workout equipment for strength training', 'Hold the book for resistance exercises. Perfect for office or study room workouts.',
   false, 0.72, true, 2, NOW(), NOW()),

  ('cuid_challenge_chair', 'chair_challenge', 'Chair Power Workout',
   'cuid_equipment_chair', NULL, 3,
   'Transform your chair into a complete fitness station', 'Use the chair for support, resistance, and strength training. Great for office workers.',
   true, 0.89, true, 3, NOW(), NOW()),

  ('cuid_challenge_bottle', 'bottle_challenge', 'Water Bottle Strength',
   'cuid_equipment_water_bottle', 15, 3,
   'Turn your water bottle into a weight for strength training', 'Use filled water bottle as resistance for arm and shoulder exercises.',
   true, 0.76, true, 4, NOW(), NOW()),

  -- Row 2 (Medium challenges)
  ('cuid_challenge_backpack', 'backpack_challenge', 'Backpack Adventure Workout',
   'cuid_equipment_backpack', 20, 4,
   'Use your backpack for a traveling fitness routine', 'Perfect for travelers. Use the backpack weight for full body exercises.',
   false, 0.65, true, 5, NOW(), NOW()),

  ('cuid_challenge_towel', 'towel_challenge', 'Towel Flexibility Flow',
   'cuid_equipment_towel', NULL, 3,
   'Enhance your flexibility using a simple towel', 'Great for stretching and resistance exercises. Focus on flexibility and mobility.',
   false, 0.58, true, 6, NOW(), NOW()),

  ('cuid_challenge_wall', 'wall_challenge', 'Wall Warrior Training',
   'cuid_equipment_wall', NULL, 4,
   'Master wall-based exercises for strength and flexibility', 'Use the wall for support, resistance, and handstand preparation.',
   true, 0.82, true, 7, NOW(), NOW()),

  ('cuid_challenge_stairs', 'stairs_challenge', 'Stair Climbing Power',
   'cuid_equipment_stairs', 12, 4,
   'High-intensity stair climbing and step exercises', 'Cardio and leg strength focused. Use stairs for explosive movements.',
   true, 0.73, true, 8, NOW(), NOW()),

  -- Row 3 (Hard challenges)
  ('cuid_challenge_tree', 'tree_challenge', 'Nature Tree Workout',
   'cuid_equipment_tree', NULL, 5,
   'Outdoor fitness using tree branches and trunk', 'Connect with nature while building strength. Perfect for park workouts.',
   false, 0.34, true, 9, NOW(), NOW()),

  ('cuid_challenge_sofa', 'sofa_challenge', 'Couch Crusher Challenge',
   'cuid_equipment_sofa', 25, 4,
   'Transform couch time into productive fitness time', 'No more excuses! Turn your sofa into a fitness equipment.',
   false, 0.45, true, 10, NOW(), NOW()),

  ('cuid_challenge_desk', 'desk_challenge', 'Desktop Fitness Revolution',
   'cuid_equipment_desk', 18, 4,
   'Professional desk-based workout routine', 'Perfect for office workers. Combat sitting all day with active movements.',
   false, 0.67, true, 11, NOW(), NOW()),

  ('cuid_challenge_none', 'none_challenge', 'Pure Body Challenge',
   'cuid_equipment_none', NULL, 5,
   'Ultimate bodyweight-only fitness challenge', 'No equipment needed. Pure bodyweight mastery. The ultimate minimalist challenge.',
   true, 0.91, true, 12, NOW(), NOW())
ON CONFLICT (code) DO NOTHING;

-- 验证插入结果
SELECT
  'Challenge Items 统计' as category,
  COUNT(*) as total_challenges,
  COUNT(CASE WHEN is_popular = true THEN 1 END) as popular_challenges,
  COUNT(CASE WHEN time_limit IS NOT NULL THEN 1 END) as timed_challenges,
  AVG(target_count) as avg_target_count
FROM challenge_items;

-- 显示挑战与器材的关联
SELECT
  ci.title as challenge_title,
  e.name as equipment_name,
  e.category as equipment_category,
  ci.time_limit as time_limit_minutes,
  ci.target_count,
  ci.is_popular,
  ci.trending_score
FROM challenge_items ci
LEFT JOIN equipment e ON ci.equipment_id = e.id
ORDER BY ci.display_order;