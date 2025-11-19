-- ==========================================
-- Step 3: Challenge Completions 挑战完成记录数据生成
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
    SELECT COUNT(*) INTO users;

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

-- 获取现有用户ID和挑战ID用于测试数据
-- 修复版本：使用更简单的方式生成测试数据
WITH user_data AS (
  SELECT id, ROW_NUMBER() OVER() as user_seq FROM users
),
challenge_data AS (
  SELECT
    id,
    target_count,
    time_limit,
    ROW_NUMBER() OVER() as challenge_seq
  FROM challenge_items
  WHERE is_active = true
),
completion_records AS (
  SELECT
    cd.id as challenge_item_id,
    cd.target_count,
    cd.time_limit,
    ud.id as user_id,
    -- 为每个挑战生成多个完成记录
    generate_series(1, 3) as completion_seq
  FROM challenge_data cd
  CROSS JOIN user_data ud
  WHERE ud.user_seq <= 3  -- 限制前3个用户
)
INSERT INTO challenge_completions (
  id, user_id, challenge_item_id, workout_session_id,
  status, started_at, completed_at, abandoned_at,
  actual_duration, completed_count, progress_percent,
  difficulty_felt, enjoyment_rating, feedback,
  badge_earned, xp_earned, bonus_rewards,
  created_at, updated_at
)
SELECT
  'cuid_completion_' || cr.challenge_item_id || '_' || cr.user_id || '_' || cr.completion_seq as id,
  cr.user_id,
  cr.challenge_item_id,
  NULL as workout_session_id, -- 暂时不关联训练会话
  CASE
    WHEN (cr.completion_seq + ABS(HASHTEXT(cr.user_id::text))) % 10 < 6 THEN 'COMPLETED'::challenge_status
    WHEN (cr.completion_seq + ABS(HASHTEXT(cr.user_id::text))) % 10 < 8 THEN 'IN_PROGRESS'::challenge_status
    WHEN (cr.completion_seq + ABS(HASHTEXT(cr.user_id::text))) % 10 < 9 THEN 'STARTED'::challenge_status
    ELSE 'ABANDONED'::challenge_status
  END as status,
  NOW() - ((ABS(HASHTEXT(cr.user_id::text)) % 7) || ' days')::interval as started_at,
  CASE
    WHEN (cr.completion_seq + ABS(HASHTEXT(cr.user_id::text))) % 10 < 6 THEN
      NOW() - ((ABS(HASHTEXT(cr.user_id::text)) % 6) || ' days')::interval
    ELSE NULL
  END as completed_at,
  CASE
    WHEN (cr.completion_seq + ABS(HASHTEXT(cr.user_id::text))) % 10 = 9 THEN
      NOW() - ((ABS(HASHTEXT(cr.user_id::text)) % 5) || ' days')::interval
    ELSE NULL
  END as abandoned_at,
  -- 实际完成时长（秒数）
  CASE
    WHEN cr.time_limit IS NOT NULL THEN cr.time_limit * 60 + (ABS(HASHTEXT(cr.user_id::text)) % 300)
    ELSE 300 + (ABS(HASHTEXT(cr.user_id::text)) % 1200)
  END as actual_duration,
  -- 完成次数
  CASE
    WHEN (cr.completion_seq + ABS(HASHTEXT(cr.user_id::text))) % 10 < 6 THEN cr.target_count
    ELSE GREATEST(1, (ABS(HASHTEXT(cr.user_id::text)) % cr.target_count) + 1)
  END as completed_count,
  -- 完成百分比
  CASE
    WHEN (cr.completion_seq + ABS(HASHTEXT(cr.user_id::text))) % 10 < 6 THEN 100.0
    ELSE (ABS(HASHTEXT(cr.user_id::text)) % 100)::numeric(5,2)
  END as progress_percent,
  -- 难度感受 (1-5)
  (ABS(HASHTEXT(cr.user_id::text)) % 5) + 1 as difficulty_felt,
  -- 享受度评分 (1-5)
  (ABS(HASHTEXT(cr.user_id::text || cr.completion_seq::text)) % 5) + 1 as enjoyment_rating,
  -- 反馈
  CASE (ABS(HASHTEXT(cr.user_id::text)) % 6)
    WHEN 0 THEN 'Great workout! Really enjoyed it.'
    WHEN 1 THEN 'Challenging but rewarding experience.'
    WHEN 2 THEN 'Perfect for beginners like me.'
    WHEN 3 THEN 'Good exercise, will do it again.'
    WHEN 4 THEN 'Amazing equipment usage ideas!'
    ELSE NULL
  END as feedback,
  -- 获得徽章
  CASE
    WHEN (ABS(HASHTEXT(cr.user_id::text)) % 100) < 30 THEN 'COMMON'::rarity_level
    WHEN (ABS(HASHTEXT(cr.user_id::text)) % 100) < 50 THEN 'UNCOMMON'::rarity_level
    WHEN (ABS(HASHTEXT(cr.user_id::text)) % 100) < 70 THEN 'FINE'::rarity_level
    WHEN (ABS(HASHTEXT(cr.user_id::text)) % 100) < 85 THEN 'RARE'::rarity_level
    WHEN (ABS(HASHTEXT(cr.user_id::text)) % 100) < 95 THEN 'ELITE'::rarity_level
    ELSE 'EPIC'::rarity_level
  END as badge_earned,
  -- 经验值
  50 + (ABS(HASHTEXT(cr.user_id::text)) % 200) as xp_earned,
  -- 额外奖励 (JSON)
  CASE
    WHEN (ABS(HASHTEXT(cr.user_id::text)) % 10) < 2 THEN '{"specialAchievement": "first_time_completion", "bonusXP": 50}'::jsonb
    WHEN (ABS(HASHTEXT(cr.user_id::text)) % 10) < 3 THEN '{"specialAchievement": "speed_demon", "bonusXP": 75}'::jsonb
    ELSE NULL
  END as bonus_rewards,
  NOW() - ((ABS(HASHTEXT(cr.user_id::text)) % 7) || ' days')::interval as created_at,
  NOW() as updated_at
FROM completion_records cr;

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