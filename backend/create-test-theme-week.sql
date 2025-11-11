-- Create test theme week data for current week
-- This script creates an active theme week that covers the current date

INSERT INTO "ThemeWeek" (
  id,
  title,
  code,
  description,
  "equipmentCode",
  "targetExerciseCount",
  "startDate",
  "endDate",
  "rewardType",
  "rewardData",
  status,
  "isVisible",
  "createdAt",
  "updatedAt"
) VALUES (
  'tw_test_current_week',
  '办公室健身挑战周',
  'OFFICE_FITNESS_WEEK',
  '利用办公室常见物品进行健身训练，提升工作期间的身体活力',
  'OFFICE_CHAIR',
  5,
  -- 本周一开始
  DATE_TRUNC('week', NOW()),
  -- 下周一结束
  DATE_TRUNC('week', NOW()) + INTERVAL '7 days',
  'POINTS',
  '{"points": 100, "badge": "办公室健身达人"}',
  'ACTIVE',
  true,
  NOW(),
  NOW()
);

-- 查看插入结果
SELECT
  id,
  title,
  code,
  status,
  "startDate",
  "endDate",
  "isVisible",
  "createdAt"
FROM "ThemeWeek"
WHERE status = 'ACTIVE'
ORDER BY "createdAt" DESC;