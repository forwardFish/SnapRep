-- 插入测试用户数据 (如果不存在的话)
INSERT INTO "User" (
  id, email, password_hash, name, avatar_url,
  total_workouts, total_duration_sec, current_streak, longest_streak,
  preferred_intents, preferred_difficulty, preferred_duration,
  avoid_equipment, streak_reminder, theme_week_reminder,
  quiet_hours_start, quiet_hours_end, hide_real_photos, auto_blur_faces, allow_data_sync,
  language, theme, created_at, updated_at
) VALUES
(
  'test-user-001',
  'test@snaprep.com',
  '$2b$10$hashedpassword',
  'Test User',
  'https://api.dicebear.com/7.x/avataaars/svg?seed=test',
  5, 1200, 3, 7,
  '{"STRETCH", "RELAX"}',
  'GREEN',
  60,
  '{}',
  true, true,
  '22:00', '08:00',
  false, false, false,
  'en', 'auto',
  NOW(), NOW()
)
ON CONFLICT (id) DO NOTHING;

-- 插入当前活跃的主题周
INSERT INTO "ThemeWeek" (
  id, title, code, description,
  equipment_code, target_exercise_count,
  start_date, end_date,
  reward_type, reward_data,
  status, is_visible, display_order,
  total_participants, total_completions, completion_rate,
  created_at, updated_at
) VALUES
(
  'theme-week-chair-001',
  'Chair Challenge Week',
  'chair_week_2024_46',
  'Complete 3 chair exercises to unlock exclusive sticker skin! Perfect for office breaks and home workouts.',
  'CHAIR',
  3,
  CURRENT_DATE - INTERVAL '2 days',  -- 2天前开始
  CURRENT_DATE + INTERVAL '5 days',  -- 5天后结束
  'skin',
  '{"skinName": "Chair Master", "rarityBoost": 0.1}',
  'ACTIVE',
  true,
  1,
  1250,  -- 总参与人数
  975,   -- 总完成人数
  78.0,  -- 完成率
  NOW() - INTERVAL '2 days',
  NOW()
),
(
  'theme-week-bottle-002',
  'Water Bottle Week',
  'bottle_week_2024_47',
  'Hydrate and exercise on the go! Use your water bottle for a refreshing workout experience.',
  'WATER_BOTTLE',
  3,
  CURRENT_DATE + INTERVAL '6 days',   -- 6天后开始（upcoming）
  CURRENT_DATE + INTERVAL '13 days',  -- 13天后结束
  'badge',
  '{"badgeName": "Hydration Hero", "color": "blue"}',
  'UPCOMING',
  true,
  2,
  0, 0, 0.0,  -- 还没开始，所以都是0
  NOW(),
  NOW()
),
(
  'theme-week-backpack-003',
  'Backpack Adventure',
  'backpack_week_2024_48',
  'Your fitness companion on the road. Turn your backpack into the ultimate workout tool!',
  'BACKPACK',
  5,
  CURRENT_DATE + INTERVAL '14 days',  -- 14天后开始（upcoming）
  CURRENT_DATE + INTERVAL '21 days',  -- 21天后结束
  'rarity_boost',
  '{"boostMultiplier": 1.5, "duration": "24h"}',
  'UPCOMING',
  true,
  3,
  0, 0, 0.0,  -- 还没开始，所以都是0
  NOW(),
  NOW()
)
ON CONFLICT (id) DO NOTHING;

-- 插入测试用户的主题周参与记录
INSERT INTO "ThemeWeekParticipation" (
  id, user_id, theme_week_id,
  status, joined_at, completed_at,
  exercises_completed, target_exercises, progress_percent,
  reward_earned, reward_claimed_at,
  related_sessions, created_at, updated_at
) VALUES
(
  'participation-001',
  'test-user-001',
  'theme-week-chair-001',
  'IN_PROGRESS',
  NOW() - INTERVAL '1 day',  -- 1天前加入
  NULL,  -- 还没完成
  2,     -- 已完成2个练习
  3,     -- 目标3个
  66.7,  -- 进度66.7%
  false, NULL,
  '{"session-001", "session-002"}',
  NOW() - INTERVAL '1 day',
  NOW()
)
ON CONFLICT (user_id, theme_week_id) DO NOTHING;

-- 更新主题周统计信息
UPDATE "ThemeWeek"
SET
  total_participants = (
    SELECT COUNT(*) FROM "ThemeWeekParticipation"
    WHERE theme_week_id = 'theme-week-chair-001'
  ),
  total_completions = (
    SELECT COUNT(*) FROM "ThemeWeekParticipation"
    WHERE theme_week_id = 'theme-week-chair-001' AND status = 'COMPLETED'
  ),
  updated_at = NOW()
WHERE id = 'theme-week-chair-001';

-- 再次计算完成率
UPDATE "ThemeWeek"
SET
  completion_rate = CASE
    WHEN total_participants > 0 THEN (total_completions::float / total_participants::float) * 100
    ELSE 0
  END,
  updated_at = NOW()
WHERE id = 'theme-week-chair-001';

-- 验证数据插入
SELECT
  tw.id,
  tw.title,
  tw.status,
  tw.start_date,
  tw.end_date,
  tw.total_participants,
  tw.total_completions,
  tw.completion_rate
FROM "ThemeWeek" tw
WHERE tw.status IN ('ACTIVE', 'UPCOMING')
ORDER BY tw.start_date;