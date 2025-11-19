-- ==========================================
-- Step 3 (Simple): Challenge Completions 挑战完成记录数据生成
-- ==========================================
-- 前置条件：equipment 表和 challenge_items 表必须先有数据

-- 验证前置数据
DO $$
DECLARE
    equipment_count INTEGER;
    challenge_count INTEGER;
    user_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO equipment_count FROM equipment WHERE is_active = true;
    SELECT COUNT(*) INTO challenge_count FROM challenge_items WHERE is_active = true;
    SELECT COUNT(*) INTO user_count FROM users;

    IF equipment_count < 10 THEN
        RAISE EXCEPTION 'Equipment 表数据不足 (当前: %, 需要: >=10)', equipment_count;
    END IF;

    IF challenge_count < 5 THEN
        RAISE EXCEPTION 'Challenge Items 表数据不足 (当前: %, 需要: >=5)', challenge_count;
    END IF;

    IF user_count < 3 THEN
        RAISE EXCEPTION 'Users 表数据不足 (当前: %, 需要: >=3)', user_count;
    END IF;

    RAISE NOTICE '前置数据验证成功：Equipment %, Challenge Items %, Users %',
                 equipment_count, challenge_count, user_count;
END $$;

-- 清理旧的挑战完成记录
DELETE FROM challenge_completions;

-- 基于实际用户数据的挑战完成记录
INSERT INTO challenge_completions (
  id, user_id, challenge_item_id, workout_session_id,
  status, started_at, completed_at, abandoned_at,
  actual_duration, completed_count, progress_percent,
  difficulty_felt, enjoyment_rating, feedback,
  badge_earned, xp_earned, bonus_rewards,
  created_at, updated_at
)
VALUES
  -- Alice 的记录 (已有用户，ID: 550e8400-e29b-41d4-a716-446655440003)
  ('cuid_completion_001', '550e8400-e29b-41d4-a716-446655440003',
   (SELECT id FROM challenge_items WHERE code = 'umbrella_challenge'), NULL,
   'COMPLETED', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour 55 minutes', NULL,
   320, 3, 100.0, 3, 5, 'Great workout! Really enjoyed using the umbrella for resistance.',
   'COMMON', 150, '{"specialAchievement": "first_umbrella_challenge", "bonusXP": 50}',
   NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour 55 minutes'),

  ('cuid_completion_002', '550e8400-e29b-41d4-a716-446655440003',
   (SELECT id FROM challenge_items WHERE code = 'book_challenge'), NULL,
   'COMPLETED', NOW() - INTERVAL '1 day', NOW() - INTERVAL '23 hours 56 minutes', NULL,
   240, 3, 100.0, 2, 4, 'Simple but effective. Good for beginners.',
   'COMMON', 120, NULL,
   NOW() - INTERVAL '1 day', NOW() - INTERVAL '23 hours 56 minutes'),

  ('cuid_completion_003', '550e8400-e29b-41d4-a716-446655440003',
   (SELECT id FROM challenge_items WHERE code = 'chair_challenge'), NULL,
   'COMPLETED', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '2 hours 56 minutes', NULL,
   240, 3, 100.0, 1, 5, 'Perfect for office breaks! Highly recommend.',
   'COMMON', 140, '{"specialAchievement": "office_warrior"}',
   NOW() - INTERVAL '3 hours', NOW() - INTERVAL '2 hours 56 minutes'),

  -- Bob 的记录 (已有用户，ID: 550e8400-e29b-41d4-a716-446655440004)
  ('cuid_completion_004', '550e8400-e29b-41d4-a716-446655440004',
   (SELECT id FROM challenge_items WHERE code = 'backpack_challenge'), NULL,
   'COMPLETED', NOW() - INTERVAL '5 hours', NOW() - INTERVAL '4 hours 55 minutes', NULL,
   1200, 4, 100.0, 4, 3, 'Challenging but rewarding. Good for travel.',
   'FINE', 200, '{"specialAchievement": "travel_fitness_expert", "bonusXP": 75}',
   NOW() - INTERVAL '5 hours', NOW() - INTERVAL '4 hours 55 minutes'),

  ('cuid_completion_005', '550e8400-e29b-41d4-a716-446655440004',
   (SELECT id FROM challenge_items WHERE code = 'wall_challenge'), NULL,
   'COMPLETED', NOW() - INTERVAL '1 day 2 hours', NOW() - INTERVAL '1 day 1 hour 45 minutes', NULL,
   900, 4, 100.0, 3, 4, 'Wall exercises are underrated. Great workout!',
   'UNCOMMON', 180, NULL,
   NOW() - INTERVAL '1 day 2 hours', NOW() - INTERVAL '1 day 1 hour 45 minutes'),

  ('cuid_completion_006', '550e8400-e29b-41d4-a716-446655440004',
   (SELECT id FROM challenge_items WHERE code = 'bottle_challenge'), NULL,
   'COMPLETED', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '15 minutes', NULL,
   900, 3, 100.0, 2, 4, 'Good hydration reminder too!',
   'COMMON', 130, NULL,
   NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '15 minutes'),

  -- Charlie 的记录 (已有用户，ID: 550e8400-e29b-41d4-a716-446655440005)
  ('cuid_completion_007', '550e8400-e29b-41d4-a716-446655440005',
   (SELECT id FROM challenge_items WHERE code = 'none_challenge'), NULL,
   'IN_PROGRESS', NOW() - INTERVAL '30 minutes', NULL, NULL,
   NULL, 2, 40.0, NULL, NULL, NULL,
   NULL, 0, NULL,
   NOW() - INTERVAL '30 minutes', NOW()),

  ('cuid_completion_008', '550e8400-e29b-41d4-a716-446655440005',
   (SELECT id FROM challenge_items WHERE code = 'towel_challenge'), NULL,
   'COMPLETED', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days' + INTERVAL '12 minutes', NULL,
   720, 3, 100.0, 2, 5, 'Great for flexibility. Feel much better!',
   'UNCOMMON', 160, '{"specialAchievement": "flexibility_master"}',
   NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days' + INTERVAL '12 minutes'),

  -- 高级用户的记录 (已有用户，ID: 550e8400-e29b-41d4-a716-446655440008)
  ('cuid_completion_009', '550e8400-e29b-41d4-a716-446655440008',
   (SELECT id FROM challenge_items WHERE code = 'tree_challenge'), NULL,
   'COMPLETED', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '25 minutes', NULL,
   1500, 5, 100.0, 5, 5, 'Amazing outdoor experience! Nature workout is the best.',
   'RARE', 300, '{"specialAchievement": "nature_warrior", "bonusXP": 100}',
   NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '25 minutes'),

  ('cuid_completion_010', '550e8400-e29b-41d4-a716-446655440008',
   (SELECT id FROM challenge_items WHERE code = 'stairs_challenge'), NULL,
   'COMPLETED', NOW() - INTERVAL '1 week', NOW() - INTERVAL '1 week' + INTERVAL '12 minutes', NULL,
   720, 4, 100.0, 4, 4, 'High intensity cardio at its best!',
   'ELITE', 250, '{"specialAchievement": "cardio_master", "bonusXP": 125}',
   NOW() - INTERVAL '1 week', NOW() - INTERVAL '1 week' + INTERVAL '12 minutes'),

  ('cuid_completion_011', '550e8400-e29b-41d4-a716-446655440008',
   (SELECT id FROM challenge_items WHERE code = 'desk_challenge'), NULL,
   'COMPLETED', NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '18 minutes', NULL,
   1080, 4, 100.0, 3, 5, 'Perfect for busy professionals!',
   'FINE', 190, NULL,
   NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days' + INTERVAL '18 minutes'),

  -- 放弃的挑战示例 (Alice)
  ('cuid_completion_012', '550e8400-e29b-41d4-a716-446655440003',
   (SELECT id FROM challenge_items WHERE code = 'stairs_challenge'), NULL,
   'ABANDONED', NOW() - INTERVAL '6 hours', NULL, NOW() - INTERVAL '5 hours 30 minutes',
   1800, 2, 50.0, 5, 2, 'Too intense for me right now. Will try again later.',
   NULL, 0, NULL,
   NOW() - INTERVAL '6 hours', NOW() - INTERVAL '5 hours 30 minutes'),

  -- 进行中的挑战 (Bob)
  ('cuid_completion_013', '550e8400-e29b-41d4-a716-446655440004',
   (SELECT id FROM challenge_items WHERE code = 'sofa_challenge'), NULL,
   'IN_PROGRESS', NOW() - INTERVAL '1 hour', NULL, NULL,
   NULL, 2, 50.0, NULL, NULL, NULL,
   NULL, 0, NULL,
   NOW() - INTERVAL '1 hour', NOW()),

  -- Charlie 开始的新挑战
  ('cuid_completion_014', '550e8400-e29b-41d4-a716-446655440005',
   (SELECT id FROM challenge_items WHERE code = 'umbrella_challenge'), NULL,
   'STARTED', NOW() - INTERVAL '10 minutes', NULL, NULL,
   NULL, 0, 0.0, NULL, NULL, NULL,
   NULL, 0, NULL,
   NOW() - INTERVAL '10 minutes', NOW());

-- 验证插入结果
SELECT
  'Challenge Completions 统计' as category,
  COUNT(*) as total_completions,
  COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed_count,
  COUNT(CASE WHEN status = 'IN_PROGRESS' THEN 1 END) as in_progress_count,
  COUNT(CASE WHEN status = 'ABANDONED' THEN 1 END) as abandoned_count,
  ROUND(AVG(actual_duration)::numeric, 0) as avg_duration_seconds,
  ROUND(AVG(progress_percent)::numeric, 1) as avg_progress_percent
FROM challenge_completions;

-- 显示挑战完成情况统计
SELECT
  ci.title as challenge_title,
  COUNT(cc.*) as total_attempts,
  COUNT(CASE WHEN cc.status = 'COMPLETED' THEN 1 END) as completions,
  ROUND(
    COUNT(CASE WHEN cc.status = 'COMPLETED' THEN 1 END)::numeric /
    NULLIF(COUNT(cc.*), 0) * 100, 1
  ) as completion_rate_percent,
  ROUND(AVG(CASE WHEN cc.status = 'COMPLETED' THEN cc.actual_duration END)::numeric, 0) as avg_completion_time_seconds
FROM challenge_items ci
LEFT JOIN challenge_completions cc ON ci.id = cc.challenge_item_id
GROUP BY ci.id, ci.title, ci.display_order
ORDER BY ci.display_order;

-- 显示用户挑战参与情况
SELECT
  u.name as user_name,
  COUNT(cc.*) as total_attempts,
  COUNT(CASE WHEN cc.status = 'COMPLETED' THEN 1 END) as completions,
  SUM(cc.xp_earned) as total_xp_earned
FROM users u
LEFT JOIN challenge_completions cc ON u.id = cc.user_id
GROUP BY u.id, u.name
ORDER BY total_xp_earned DESC;

-- 显示最新活动
SELECT
  u.name as user_name,
  ci.title as challenge_title,
  cc.status,
  cc.started_at,
  cc.completed_at,
  cc.progress_percent,
  cc.xp_earned
FROM challenge_completions cc
JOIN users u ON cc.user_id = u.id
JOIN challenge_items ci ON cc.challenge_item_id = ci.id
ORDER BY COALESCE(cc.completed_at, cc.started_at) DESC
LIMIT 10;