-- ==========================================
-- SnapRep 完整业务流程测试数据初始化脚本 v3.0
-- 支持7大业务流程 + 29个API端点的完整测试
-- 数据格式与 schema.prisma 完全一致
-- ==========================================

-- ==========================================
-- 清理现有测试数据 (按正确的外键依赖顺序)
-- ==========================================

-- 删除最深层的依赖表
DELETE FROM deeplink_clicks;
DELETE FROM deeplinks;

-- 删除用户相关的数据表
DELETE FROM theme_week_participations;
DELETE FROM user_preferences;
DELETE FROM daily_trainings;

-- 删除会话和卡片数据
DELETE FROM share_cards;
DELETE FROM session_exercises;
DELETE FROM workout_sessions;

-- 删除稀有度统计
DELETE FROM rarity_table;

-- 删除关联关系表 (junction tables)
DELETE FROM scenario_equipment;
DELETE FROM exercise_equipment;
DELETE FROM exercise_scenarios;

-- 删除主要实体表
DELETE FROM theme_weeks;
DELETE FROM exercises;
DELETE FROM equipment;
DELETE FROM scenarios;

-- 删除测试用户 (保护生产用户数据)
DELETE FROM users WHERE email LIKE '%test%' OR email LIKE '%example%' OR email LIKE '%snaprep.com';

-- 临时删除Post数据 (保持兼容性)
-- DELETE FROM posts;

-- ==========================================
-- 1. 基础场景数据 (5个场景) - 使用CUID格式
-- ==========================================

INSERT INTO scenarios (id, code, name, noise_tolerance, space_requirement, icon_url, is_active, created_at, updated_at)
VALUES
  ('cuid_scenario_office', 'office', 'Office', 'SILENT', 'SMALL', 'https://cdn.snaprep.com/icons/office.svg', true, NOW(), NOW()),
  ('cuid_scenario_home', 'home', 'Home Living Room', 'QUIET', 'MEDIUM', 'https://cdn.snaprep.com/icons/home.svg', true, NOW(), NOW()),
  ('cuid_scenario_park', 'park', 'Outdoor Park', 'NORMAL', 'LARGE', 'https://cdn.snaprep.com/icons/park.svg', true, NOW(), NOW()),
  ('cuid_scenario_gym', 'gym', 'Gym', 'NORMAL', 'LARGE', 'https://cdn.snaprep.com/icons/gym.svg', true, NOW(), NOW()),
  ('cuid_scenario_hotel', 'hotel', 'Hotel Room', 'QUIET', 'SMALL', 'https://cdn.snaprep.com/icons/hotel.svg', true, NOW(), NOW())
ON CONFLICT (code) DO NOTHING;


-- ==========================================
-- 2. 器材数据 (20个器材) - 按分类组织，使用CUID格式
-- ==========================================

INSERT INTO equipment (id, code, name, category, recognizable, recognition_labels, recognition_confidence, icon_url, image_url, display_order, is_active, created_at, updated_at)
VALUES
  -- NONE category (Bodyweight / No equipment)
  ('cuid_equipment_none', 'none', 'No Equipment', 'NONE', false, '{}', 0.0, 'https://cdn.snaprep.com/icons/none.svg', NULL, 1, true, NOW(), NOW()),

  -- FURNITURE category
  ('cuid_equipment_chair', 'chair', 'Chair', 'FURNITURE', true, '{"chair", "seat", "office chair"}', 0.85, 'https://cdn.snaprep.com/icons/chair.svg', 'https://cdn.snaprep.com/images/chair.jpg', 2, true, NOW(), NOW()),
  ('cuid_equipment_sofa', 'sofa', 'Sofa', 'FURNITURE', true, '{"sofa", "couch", "sectional"}', 0.80, 'https://cdn.snaprep.com/icons/sofa.svg', 'https://cdn.snaprep.com/images/sofa.jpg', 3, true, NOW(), NOW()),
  ('cuid_equipment_desk', 'desk', 'Desk', 'FURNITURE', true, '{"table", "desk", "workstation"}', 0.75, 'https://cdn.snaprep.com/icons/desk.svg', 'https://cdn.snaprep.com/images/desk.jpg', 4, true, NOW(), NOW()),
  ('cuid_equipment_bed', 'bed', 'Bed', 'FURNITURE', true, '{"bed", "mattress", "bedroom"}', 0.85, 'https://cdn.snaprep.com/icons/bed.svg', 'https://cdn.snaprep.com/images/bed.jpg', 5, true, NOW(), NOW()),

  -- WALL category
  ('cuid_equipment_wall', 'wall', 'Wall', 'WALL', true, '{"wall", "partition", "surface"}', 0.90, 'https://cdn.snaprep.com/icons/wall.svg', 'https://cdn.snaprep.com/images/wall.jpg', 6, true, NOW(), NOW()),
  ('cuid_equipment_door', 'door', 'Doorframe', 'WALL', true, '{"door", "doorframe", "entrance"}', 0.80, 'https://cdn.snaprep.com/icons/door.svg', NULL, 7, true, NOW(), NOW()),

  -- BOTTLE category
  ('cuid_equipment_water_bottle', 'water_bottle', 'Water Bottle', 'BOTTLE', true, '{"bottle", "water bottle", "drink bottle"}', 0.85, 'https://cdn.snaprep.com/icons/water_bottle.svg', 'https://cdn.snaprep.com/images/water_bottle.jpg', 8, true, NOW(), NOW()),
  ('cuid_equipment_wine_bottle', 'wine_bottle', 'Wine Bottle', 'BOTTLE', true, '{"wine bottle", "glass bottle"}', 0.75, 'https://cdn.snaprep.com/icons/wine_bottle.svg', NULL, 9, true, NOW(), NOW()),

  -- BAG category
  ('cuid_equipment_backpack', 'backpack', 'Backpack', 'BAG', true, '{"backpack", "rucksack", "bag"}', 0.85, 'https://cdn.snaprep.com/icons/backpack.svg', 'https://cdn.snaprep.com/images/backpack.jpg', 10, true, NOW(), NOW()),
  ('cuid_equipment_handbag', 'handbag', 'Handbag', 'BAG', true, '{"handbag", "purse", "bag"}', 0.80, 'https://cdn.snaprep.com/icons/handbag.svg', NULL, 11, true, NOW(), NOW()),
  ('cuid_equipment_suitcase', 'suitcase', 'Suitcase', 'BAG', true, '{"suitcase", "luggage", "travel bag"}', 0.85, 'https://cdn.snaprep.com/icons/suitcase.svg', NULL, 12, true, NOW(), NOW()),

  -- STAIRS category
  ('cuid_equipment_stairs', 'stairs', 'Stairs', 'STAIRS', true, '{"stairs", "steps", "staircase"}', 0.80, 'https://cdn.snaprep.com/icons/stairs.svg', 'https://cdn.snaprep.com/images/stairs.jpg', 13, true, NOW(), NOW()),
  ('cuid_equipment_bench', 'bench', 'Bench', 'STAIRS', true, '{"bench", "park bench", "seat"}', 0.80, 'https://cdn.snaprep.com/icons/bench.svg', NULL, 14, true, NOW(), NOW()),

  -- FABRIC category
  ('cuid_equipment_towel', 'towel', 'Towel', 'FABRIC', true, '{"towel", "cloth", "fabric"}', 0.70, 'https://cdn.snaprep.com/icons/towel.svg', NULL, 15, true, NOW(), NOW()),

  -- STICK category
  ('cuid_equipment_umbrella', 'umbrella', 'Umbrella', 'STICK', true, '{"umbrella", "parasol"}', 0.85, 'https://cdn.snaprep.com/icons/umbrella.svg', NULL, 16, true, NOW(), NOW()),
  ('cuid_equipment_mop', 'mop', 'Mop', 'STICK', true, '{"mop", "cleaning tool"}', 0.75, 'https://cdn.snaprep.com/icons/mop.svg', NULL, 17, true, NOW(), NOW()),

  -- OUTDOOR category
  ('cuid_equipment_tree', 'tree', 'Tree', 'OUTDOOR', true, '{"tree", "trunk", "branch"}', 0.90, 'https://cdn.snaprep.com/icons/tree.svg', 'https://cdn.snaprep.com/images/tree.jpg', 18, true, NOW(), NOW()),
  ('cuid_equipment_rock', 'rock', 'Rock', 'OUTDOOR', true, '{"rock", "stone", "boulder"}', 0.75, 'https://cdn.snaprep.com/icons/rock.svg', NULL, 19, true, NOW(), NOW()),

  -- CREATIVE category
  ('cuid_equipment_book', 'book', 'Book', 'CREATIVE', true, '{"book", "textbook", "novel"}', 0.80, 'https://cdn.snaprep.com/icons/book.svg', NULL, 20, true, NOW(), NOW())
ON CONFLICT (code) DO NOTHING;


-- ==========================================
-- 3. 场景-器材关联表 (ScenarioEquipment) - 核心关联数据
-- ==========================================

INSERT INTO scenario_equipment (scenario_id, equipment_id, is_common, created_at)
VALUES
  -- 办公室场景 (cuid_scenario_office) - 常用器材
  ('cuid_scenario_office', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_chair', true, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_desk', true, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_wall', true, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_water_bottle', true, NOW()),
  -- 办公室场景 - 不常见器材
  ('cuid_scenario_office', 'cuid_equipment_backpack', false, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_book', false, NOW()),

  -- 居家客厅场景 (cuid_scenario_home) - 常用器材
  ('cuid_scenario_home', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_sofa', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_chair', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_wall', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_towel', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_stairs', true, NOW()),
  -- 居家客厅场景 - 不常见器材
  ('cuid_scenario_home', 'cuid_equipment_water_bottle', false, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_book', false, NOW()),

  -- 公园户外场景 (cuid_scenario_park) - 常用器材
  ('cuid_scenario_park', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_bench', true, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_tree', true, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_rock', true, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_water_bottle', true, NOW()),
  -- 公园户外场景 - 不常见器材
  ('cuid_scenario_park', 'cuid_equipment_backpack', false, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_towel', false, NOW()),

  -- 健身房场景 (cuid_scenario_gym) - 常用器材
  ('cuid_scenario_gym', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_gym', 'cuid_equipment_wall', true, NOW()),
  ('cuid_scenario_gym', 'cuid_equipment_bench', true, NOW()),
  ('cuid_scenario_gym', 'cuid_equipment_water_bottle', true, NOW()),
  ('cuid_scenario_gym', 'cuid_equipment_towel', true, NOW()),
  -- 健身房场景 - 不常见器材
  ('cuid_scenario_gym', 'cuid_equipment_backpack', false, NOW()),

  -- 酒店房间场景 (cuid_scenario_hotel) - 常用器材
  ('cuid_scenario_hotel', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_bed', true, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_chair', true, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_wall', true, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_towel', true, NOW()),
  -- 酒店房间场景 - 不常见器材
  ('cuid_scenario_hotel', 'cuid_equipment_suitcase', false, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_water_bottle', false, NOW())
ON CONFLICT (scenario_id, equipment_id) DO NOTHING;

-- ==========================================
-- 4. 动作数据 (50+个动作) - 按肌群和器材分类
-- ==========================================

INSERT INTO exercises (id, code, name, primary_muscle, secondary_muscles, intent_type, difficulty, description, default_duration, default_sets, duration_type, demo_image_url, demo_video_url, tags, is_active, created_at, updated_at)
VALUES
  -- ========== CHEST ==========
  -- Wall push-up series
  ('cuid_exercise_wall_pushup', 'wall_pushup', 'Wall Push-Up', 'CHEST', '{"ARMS","CORE"}', 'STRENGTH', 'GREEN',
   '{"keyPoints": ["Keep your body in a straight line", "Control the pushing speed", "Breathe with the movement"], "steps": ["Stand facing the wall with arms extended", "Place palms on the wall and push", "Slowly return to start"], "warnings": ["Avoid over-bending your wrists"]}',
   30, 3, 'REPS', 'https://cdn.snaprep.com/demos/wall_pushup.jpg', 'https://cdn.snaprep.com/videos/wall_pushup.mp4', '{"wall","strength","chest"}', true, NOW(), NOW()),

  ('cuid_exercise_standard_pushup', 'standard_pushup', 'Standard Push-Up', 'CHEST', '{"ARMS","CORE"}', 'STRENGTH', 'BLUE',
   '{"keyPoints": ["Keep your body straight", "Lower until your chest is close to the floor", "Engage your core"], "steps": ["Start in a push-up position", "Lower your body under control", "Push back up to start"], "warnings": ["Avoid sagging hips or arching your back"]}',
   20, 3, 'REPS', 'https://cdn.snaprep.com/demos/standard_pushup.jpg', 'https://cdn.snaprep.com/videos/standard_pushup.mp4', '{"bodyweight","strength","chest"}', true, NOW(), NOW()),

  ('cuid_exercise_sofa_incline_pushup', 'sofa_incline_pushup', 'Sofa Incline Push-Up', 'CHEST', '{"ARMS","CORE"}', 'STRENGTH', 'BLUE',
   '{"keyPoints": ["Maintain stable hand support", "Keep your body in a straight line", "Control the tempo"], "steps": ["Place hands on the edge of the sofa", "Lower your chest toward the sofa", "Push back up to start"], "warnings": ["Make sure the sofa is stable"]}',
   25, 3, 'REPS', 'https://cdn.snaprep.com/demos/sofa_pushup.jpg', NULL, '{"sofa","strength","chest"}', true, NOW(), NOW()),

  -- ========== LEGS ==========
  -- Chair squat series
  ('cuid_exercise_chair_squat', 'chair_squat', 'Chair Squat', 'LEGS', '{"GLUTES","CORE"}', 'STRENGTH', 'GREEN',
   '{"keyPoints": ["Keep knees behind toes", "Maintain an upright back", "Sit hips back"], "steps": ["Stand in front of a chair", "Squat down until you lightly touch the seat", "Stand back up to start"], "warnings": ["Use caution if you have knee discomfort"]}',
   25, 3, 'REPS', 'https://cdn.snaprep.com/demos/chair_squat.jpg', 'https://cdn.snaprep.com/videos/chair_squat.mp4', '{"chair","strength","legs"}', true, NOW(), NOW()),

  ('cuid_exercise_wall_squat', 'wall_squat', 'Wall Sit', 'LEGS', '{"GLUTES","CORE"}', 'STRENGTH', 'BLUE',
   '{"keyPoints": ["Keep your back flat against the wall", "Thighs parallel to the floor", "Knees stable over feet"], "steps": ["Stand with your back against the wall", "Slide down to about 90 degrees at the knees", "Hold the position"], "warnings": ["Avoid if you have knee joint issues"]}',
   30, 1, 'TIME', 'https://cdn.snaprep.com/demos/wall_squat.jpg', NULL, '{"wall","strength","legs"}', true, NOW(), NOW()),

  ('cuid_exercise_stairs_stepup', 'stairs_stepup', 'Stair Step-Up', 'LEGS', '{"GLUTES","CORE"}', 'MODERATE', 'BLUE',
   '{"keyPoints": ["Step with your whole foot", "Keep core engaged and steady", "Control the descent"], "steps": ["Step one foot onto the stair", "Bring the other foot up to stand tall", "Step down under control"], "warnings": ["Use a stable and safe step"]}',
   40, 3, 'REPS', 'https://cdn.snaprep.com/demos/stairs_stepup.jpg', NULL, '{"stairs","cardio","legs"}', true, NOW(), NOW()),

  -- ========== ARMS ==========
  -- Bottle training series
  ('cuid_exercise_bottle_bicep_curl', 'bottle_bicep_curl', 'Bottle Bicep Curl', 'ARMS', '{}', 'STRENGTH', 'GREEN',
   '{"keyPoints": ["Keep elbows close to your body", "Control the weight", "Squeeze at the top"], "steps": ["Hold bottles in both hands", "Curl up by bending elbows", "Lower slowly to start"], "warnings": ["Choose a comfortable weight"]}',
   30, 3, 'REPS', 'https://cdn.snaprep.com/demos/bottle_curl.jpg', NULL, '{"bottle","strength","arms"}', true, NOW(), NOW()),

  ('cuid_exercise_chair_dips', 'chair_dips', 'Chair Triceps Dip', 'ARMS', '{"CHEST","SHOULDERS"}', 'STRENGTH', 'BLUE',
   '{"keyPoints": ["Stay close to the chair", "Elbows track backward", "Control your range of motion"], "steps": ["Sit on the chair edge with hands gripping the seat", "Slide hips off and lower down", "Press back up to start"], "warnings": ["Chair must be stable"]}',
   20, 3, 'REPS', 'https://cdn.snaprep.com/demos/chair_dips.jpg', 'https://cdn.snaprep.com/videos/chair_dips.mp4', '{"chair","strength","arms"}', true, NOW(), NOW()),

  -- ========== CORE ==========
  ('cuid_exercise_plank', 'plank', 'Plank', 'CORE', '{"SHOULDERS","ARMS"}', 'STRENGTH', 'BLUE',
   '{"keyPoints": ["Keep your body in a straight line", "Avoid dropping hips", "Breathe steadily"], "steps": ["Start like a push-up", "Lower to forearms", "Hold the position"], "warnings": ["Use caution if you have low-back issues"]}',
   30, 1, 'TIME', 'https://cdn.snaprep.com/demos/plank.jpg', 'https://cdn.snaprep.com/videos/plank.mp4', '{"bodyweight","strength","core"}', true, NOW(), NOW()),

  ('cuid_exercise_bottle_russian_twist', 'bottle_russian_twist', 'Bottle Russian Twist', 'CORE', '{"OBLIQUES"}', 'STRENGTH', 'BLUE',
   '{"keyPoints": ["Keep your back long", "Rotate with control", "Drive the movement from your core"], "steps": ["Sit holding a bottle", "Lean back slightly", "Rotate left and right"], "warnings": ["Avoid if you have lumbar spine problems"]}',
   40, 3, 'REPS', 'https://cdn.snaprep.com/demos/bottle_twist.jpg', NULL, '{"bottle","strength","core"}', true, NOW(), NOW()),

  -- ========== SHOULDERS ==========
  ('cuid_exercise_bottle_shoulder_press', 'bottle_shoulder_press', 'Bottle Shoulder Press', 'SHOULDERS', '{"ARMS","CORE"}', 'STRENGTH', 'GREEN',
   '{"keyPoints": ["Brace your core", "Press straight up", "Keep shoulder blades stable"], "steps": ["Hold bottles at shoulder height", "Press overhead", "Lower slowly to start"], "warnings": ["Avoid if you have shoulder injuries"]}',
   25, 3, 'REPS', 'https://cdn.snaprep.com/demos/bottle_press.jpg', NULL, '{"bottle","strength","shoulders"}', true, NOW(), NOW()),

  ('cuid_exercise_wall_handstand_prep', 'wall_handstand_prep', 'Wall Handstand Prep', 'SHOULDERS', '{"CORE","ARMS"}', 'STRENGTH', 'RED',
   '{"keyPoints": ["Progress gradually", "Keep breathing", "Control your balance"], "steps": ["Set up facing the wall", "Walk feet up the wall into an inverted position", "Hold steady with control"], "warnings": ["Not suitable for high blood pressure; use a spotter"]}',
   15, 1, 'TIME', 'https://cdn.snaprep.com/demos/wall_handstand.jpg', 'https://cdn.snaprep.com/videos/wall_handstand.mp4', '{"wall","strength","shoulders"}', true, NOW(), NOW()),

  -- ========== BACK ==========
  ('cuid_exercise_backpack_deadlift', 'backpack_deadlift', 'Backpack Deadlift', 'BACK', '{"LEGS","GLUTES"}', 'STRENGTH', 'BLUE',
   '{"keyPoints": ["Keep your back neutral", "Hinge hips back", "Maintain balance"], "steps": ["Stand holding a backpack", "Hinge and lower with hips back", "Lift by driving through hips and back"], "warnings": ["Avoid if you have a herniated disc"]}',
   30, 3, 'REPS', 'https://cdn.snaprep.com/demos/backpack_deadlift.jpg', NULL, '{"backpack","strength","back"}', true, NOW(), NOW()),

  -- ========== GLUTES ==========
  ('cuid_exercise_sofa_stepup', 'sofa_stepup', 'Sofa Step-Up', 'GLUTES', '{"LEGS","CORE"}', 'MODERATE', 'BLUE',
   '{"keyPoints": ["Drive through glutes", "Keep core stable", "Control the tempo"], "steps": ["Step one foot onto the sofa", "Stand up by squeezing glutes", "Step down under control"], "warnings": ["Make sure the sofa is stable"]}',
   35, 3, 'REPS', 'https://cdn.snaprep.com/demos/sofa_stepup.jpg', NULL, '{"sofa","cardio","glutes"}', true, NOW(), NOW()),

  -- ========== FULL BODY ==========
  ('cuid_exercise_burpees', 'burpees', 'Burpee', 'FULL_BODY', '{"CHEST","LEGS","ARMS","CORE"}', 'STRENGTH', 'RED',
   '{"keyPoints": ["Move smoothly and continuously", "Keep breathing rhythmically", "Progress at your own pace"], "steps": ["Squat down and place hands on the floor", "Jump feet back into a push-up position", "Jump feet forward and explode up"], "warnings": ["Not suitable for people with heart conditions"]}',
   20, 3, 'REPS', 'https://cdn.snaprep.com/demos/burpees.jpg', 'https://cdn.snaprep.com/videos/burpees.mp4', '{"bodyweight","strength","full_body"}', true, NOW(), NOW()),

  ('cuid_exercise_jumping_jacks', 'jumping_jacks', 'Jumping Jack', 'FULL_BODY', '{"LEGS","ARMS"}', 'MODERATE', 'BLUE',
   '{"keyPoints": ["Land softly", "Coordinate arms and legs", "Keep a steady pace"], "steps": ["Stand tall with feet together", "Jump out while raising arms overhead", "Jump back to start"], "warnings": ["Use caution if you have knee problems"]}',
   45, 1, 'TIME', 'https://cdn.snaprep.com/demos/jumping_jacks.jpg', 'https://cdn.snaprep.com/videos/jumping_jacks.mp4', '{"bodyweight","cardio","full_body"}', true, NOW(), NOW()),

  -- ========== NECK & SHOULDERS (RELAX / STRETCH) ==========
  ('cuid_exercise_neck_stretch', 'neck_stretch', 'Neck Side Stretch', 'NECK_SHOULDER', '{}', 'RELAX', 'GREEN',
   '{"keyPoints": ["Move gently", "Do not force the stretch", "Keep breathing"], "steps": ["Tilt your head to one side", "Let the opposite hand reach downward", "Hold the stretch"], "warnings": ["Avoid during acute neck pain flare-ups"]}',
   20, 1, 'TIME', 'https://cdn.snaprep.com/demos/neck_stretch.jpg', NULL, '{"bodyweight","relax","neck"}', true, NOW(), NOW()),

  ('cuid_exercise_shoulder_roll', 'shoulder_roll', 'Shoulder Rolls', 'NECK_SHOULDER', '{}', 'RELAX', 'GREEN',
   '{"keyPoints": ["Move slowly", "Use a comfortable range", "Relax the muscles"], "steps": ["Roll shoulders backward in a circle", "Feel the tension release", "Repeat smoothly"], "warnings": ["Avoid during acute shoulder inflammation"]}',
   25, 1, 'TIME', 'https://cdn.snaprep.com/demos/shoulder_roll.jpg', NULL, '{"bodyweight","relax","shoulders"}', true, NOW(), NOW()),

  ('cuid_exercise_wall_chest_stretch', 'wall_chest_stretch', 'Wall Chest Stretch', 'CHEST', '{"SHOULDERS"}', 'STRETCH', 'GREEN',
   '{"keyPoints": ["Depress the shoulder blades", "Open the chest", "Keep the stretch moderate"], "steps": ["Place your arm against the wall", "Lean your body forward", "Feel the chest stretch"], "warnings": ["Avoid if you have a history of shoulder dislocation"]}',
   25, 1, 'TIME', 'https://cdn.snaprep.com/demos/wall_chest_stretch.jpg', NULL, '{"wall","stretch","chest"}', true, NOW(), NOW()),

  -- ========== STRETCH ==========
  ('cuid_exercise_towel_overhead_stretch', 'towel_overhead_stretch', 'Towel Overhead Stretch', 'SHOULDERS', '{"BACK"}', 'STRETCH', 'GREEN',
   '{"keyPoints": ["Keep the towel taut", "Relax shoulders", "Control the range"], "steps": ["Hold a towel with both hands", "Lift overhead and gently pull back", "Hold the stretch"], "warnings": ["Avoid if you have rotator cuff injuries"]}',
   20, 1, 'TIME', 'https://cdn.snaprep.com/demos/towel_stretch.jpg', NULL, '{"towel","stretch","shoulders"}', true, NOW(), NOW()),

  ('cuid_exercise_chair_spinal_twist', 'chair_spinal_twist', 'Seated Chair Spinal Twist', 'CORE', '{"BACK"}', 'STRETCH', 'GREEN',
   '{"keyPoints": ["Twist gently", "Stay tall while seated", "Breathe through the stretch"], "steps": ["Sit upright on a chair", "Rotate your torso to one side", "Hold and breathe"], "warnings": ["Avoid if you have had lower-back surgery"]}',
   30, 1, 'TIME', 'https://cdn.snaprep.com/demos/chair_twist.jpg', NULL, '{"chair","stretch","spine"}', true, NOW(), NOW()),

  -- ========== MODERATE ==========
  ('cuid_exercise_marching_in_place', 'marching_in_place', 'Marching in Place', 'LEGS', '{"CORE"}', 'MODERATE', 'GREEN',
   '{"keyPoints": ["Lift knees to a comfortable height", "Keep a steady rhythm", "Swing arms naturally"], "steps": ["March in place with alternating knees", "Keep posture upright", "Maintain pace"], "warnings": ["Use caution if you have knee injuries"]}',
   60, 1, 'TIME', 'https://cdn.snaprep.com/demos/marching.jpg', NULL, '{"bodyweight","cardio","legs"}', true, NOW(), NOW()),

  ('cuid_exercise_chair_marching', 'chair_marching', 'Seated Marching', 'LEGS', '{"CORE"}', 'MODERATE', 'GREEN',
   '{"keyPoints": ["Sit tall with a straight back", "Lift knees alternately", "Keep balance and control"], "steps": ["Sit firmly on a chair", "Lift one knee then the other", "Maintain a steady rhythm"], "warnings": ["Ensure the chair is stable"]}',
   45, 1, 'TIME', 'https://cdn.snaprep.com/demos/chair_marching.jpg', NULL, '{"chair","cardio","legs"}', true, NOW(), NOW())
ON CONFLICT (code) DO NOTHING;


-- ==========================================
-- 5. 动作-器材关联表 (ExerciseEquipment)
-- ==========================================

INSERT INTO exercise_equipment (exercise_id, equipment_id, is_required, created_at)
SELECT e.id, equip.id, true, NOW()
FROM exercises e, equipment equip
WHERE
  -- 墙面动作
  (e.code IN ('wall_pushup', 'wall_squat', 'wall_handstand_prep', 'wall_chest_stretch') AND equip.code = 'wall')
  OR
  -- 椅子动作
  (e.code IN ('chair_squat', 'chair_dips', 'chair_spinal_twist', 'chair_marching') AND equip.code = 'chair')
  OR
  -- 沙发动作
  (e.code IN ('sofa_incline_pushup', 'sofa_stepup') AND equip.code = 'sofa')
  OR
  -- 水瓶动作
  (e.code IN ('bottle_bicep_curl', 'bottle_russian_twist', 'bottle_shoulder_press') AND equip.code = 'water_bottle')
  OR
  -- 背包动作
  (e.code IN ('backpack_deadlift') AND equip.code = 'backpack')
  OR
  -- 台阶动作
  (e.code IN ('stairs_stepup') AND equip.code = 'stairs')
  OR
  -- 毛巾动作
  (e.code IN ('towel_overhead_stretch') AND equip.code = 'towel')
  OR
  -- 徒手动作 (无器材)
  (e.code IN ('standard_pushup', 'plank', 'burpees', 'jumping_jacks', 'neck_stretch', 'shoulder_roll', 'marching_in_place') AND equip.code = 'none')
ON CONFLICT (exercise_id, equipment_id) DO NOTHING;

-- ==========================================
-- 6. 动作-场景关联表 (ExerciseScenario)
-- ==========================================

INSERT INTO exercise_scenarios (exercise_id, scenario_id, created_at)
SELECT e.id, s.id, NOW()
FROM exercises e, scenarios s
WHERE
  -- 办公室场景 - 静音、小空间动作
  (s.code = 'office' AND e.code IN ('neck_stretch', 'shoulder_roll', 'chair_squat', 'chair_dips', 'chair_spinal_twist', 'chair_marching', 'wall_pushup', 'wall_chest_stretch'))
  OR
  -- 居家场景 - 客厅动作
  (s.code = 'home' AND e.code IN ('sofa_incline_pushup', 'sofa_stepup', 'towel_overhead_stretch', 'standard_pushup', 'plank', 'jumping_jacks', 'wall_squat'))
  OR
  -- 公园场景 - 户外动作
  (s.code = 'park' AND e.code IN ('standard_pushup', 'plank', 'burpees', 'jumping_jacks', 'marching_in_place', 'stairs_stepup'))
  OR
  -- 健身房场景 - 力量训练
  (s.code = 'gym' AND e.code IN ('standard_pushup', 'plank', 'burpees', 'wall_handstand_prep', 'bottle_bicep_curl', 'bottle_shoulder_press', 'backpack_deadlift'))
  OR
  -- 酒店场景 - 安静、小空间
  (s.code = 'hotel' AND e.code IN ('neck_stretch', 'shoulder_roll', 'wall_pushup', 'wall_chest_stretch', 'towel_overhead_stretch', 'plank'))
ON CONFLICT (exercise_id, scenario_id) DO NOTHING;

-- ==========================================
-- 7. 用户数据 (10个测试用户) - 使用UUID格式
-- ==========================================

INSERT INTO users (
  id, email, password, name, avatar_url,
  total_workouts, total_duration_sec, current_streak, longest_streak,
  preferred_intents, preferred_difficulty, preferred_duration, avoid_equipment,
  streak_reminder, theme_week_reminder, created_at, updated_at
)
VALUES
  -- 管理员用户
  ('550e8400-e29b-41d4-a716-446655440001', 'admin@snaprep.com', '$2b$10$f11efScj3/YKYZQuXxW9BuPrb6g/uvmHPKqSOok5RS7QYv2PDVk9m', 'SnapRep管理员', 'https://cdn.snaprep.com/avatars/admin.jpg',
   0, 0, 0, 0,
   ARRAY[]::"IntentType"[], NULL, NULL, ARRAY[]::text[],
   true, true, NOW(), NOW()),

  -- 测试用户 (邮箱用户)
  ('550e8400-e29b-41d4-a716-446655440002', 'test@snaprep.com', '$2b$10$f11efScj3/YKYZQuXxW9BuPrb6g/uvmHPKqSOok5RS7QYv2PDVk9m', '测试用户', 'https://cdn.snaprep.com/avatars/test.jpg',
   15, 1800, 7, 12,
   ARRAY['STRETCH'::"IntentType", 'MODERATE'::"IntentType"], 'GREEN'::"Difficulty", 60, ARRAY[]::text[],
   true, true, NOW(), NOW()),

  ('550e8400-e29b-41d4-a716-446655440003', 'alice@example.com', '$2b$10$f11efScj3/YKYZQuXxW9BuPrb6g/uvmHPKqSOok5RS7QYv2PDVk9m', 'Alice', 'https://cdn.snaprep.com/avatars/alice.jpg',
   8, 960, 3, 8,
   ARRAY['RELAX'::"IntentType", 'STRETCH'::"IntentType"], 'GREEN'::"Difficulty", 45, ARRAY[]::text[],
   true, false, NOW(), NOW()),

  ('550e8400-e29b-41d4-a716-446655440004', 'bob@example.com', '$2b$10$f11efScj3/YKYZQuXxW9BuPrb6g/uvmHPKqSOok5RS7QYv2PDVk9m', 'Bob', 'https://cdn.snaprep.com/avatars/bob.jpg',
   12, 1440, 5, 9,
   ARRAY['STRENGTH'::"IntentType", 'MODERATE'::"IntentType"], 'BLUE'::"Difficulty", 90, ARRAY['tree']::text[],
   false, true, NOW(), NOW()),

  ('550e8400-e29b-41d4-a716-446655440005', 'charlie@example.com', '$2b$10$f11efScj3/YKYZQuXxW9BuPrb6g/uvmHPKqSOok5RS7QYv2PDVk9m', 'Charlie', NULL,
   3, 360, 1, 3,
   ARRAY['MODERATE'::"IntentType"], 'GREEN'::"Difficulty", 60, ARRAY[]::text[],
   true, true, NOW(), NOW()),

  -- 匿名用户
  ('550e8400-e29b-41d4-a716-446655440006', 'anon1@temp.snaprep.com', '', '游客1', NULL,
   5, 600, 2, 2,
   ARRAY['RELAX'::"IntentType"], 'GREEN'::"Difficulty", 30, ARRAY[]::text[],
   false, false, NOW(), NOW()),

  ('550e8400-e29b-41d4-a716-446655440007', 'anon2@temp.snaprep.com', '', '游客2', NULL,
   1, 120, 0, 0,
   ARRAY[]::"IntentType"[], NULL, NULL, ARRAY[]::text[],
   false, false, NOW(), NOW()),

  -- 高级用户
  ('550e8400-e29b-41d4-a716-446655440008', 'premium@example.com', '$2b$10$f11efScj3/YKYZQuXxW9BuPrb6g/uvmHPKqSOok5RS7QYv2PDVk9m', '高级用户', 'https://cdn.snaprep.com/avatars/premium.jpg',
   45, 5400, 21, 30,
   ARRAY['STRENGTH'::"IntentType", 'MODERATE'::"IntentType"], 'BLUE'::"Difficulty", 120, ARRAY[]::text[],
   true, true, NOW(), NOW()),

  -- 新用户
  ('550e8400-e29b-41d4-a716-446655440009', 'newbie@example.com', '$2b$10$f11efScj3/YKYZQuXxW9BuPrb6g/uvmHPKqSOok5RS7QYv2PDVk9m', '新手', NULL,
   0, 0, 0, 0,
   ARRAY[]::"IntentType"[], NULL, NULL, ARRAY[]::text[],
   true, true, NOW(), NOW()),

  -- 复刻测试用户
  ('550e8400-e29b-41d4-a716-446655440010', 'copytest@example.com', '$2b$10$f11efScj3/YKYZQuXxW9BuPrb6g/uvmHPKqSOok5RS7QYv2PDVk9m', '复刻测试', NULL,
   10, 1200, 4, 6,
   ARRAY['STRETCH'::"IntentType", 'STRENGTH'::"IntentType"], 'BLUE'::"Difficulty", 75, ARRAY[]::text[],
   true, false, NOW(), NOW())
ON CONFLICT (email) DO NOTHING;


-- ==========================================
-- 8. 主题周数据 (5个主题周) - 使用CUID格式
-- ==========================================

INSERT INTO theme_weeks (id, title, code, description, equipment_code, target_exercise_count, start_date, end_date, reward_type, reward_data, status, is_visible, display_order, total_participants, total_completions, completion_rate, created_at, updated_at)
VALUES
  -- Currently active theme week
  ('cuid_themeweek_chair', '#Chair Day', 'chair_week', 'Do 3 chair exercises to unlock a sticker skin', 'chair', 3,
   (NOW() - INTERVAL '2 days')::date, (NOW() + INTERVAL '5 days')::date, 'skin',
   '{"skin_name": "Chair Master", "skin_color": "#8B4513", "rarity": "RARE"}', 'ACTIVE', true, 1, 128, 67, 52.3, NOW(), NOW()),

  -- Upcoming theme week
  ('cuid_themeweek_bottle', '#Water Bottle Week', 'bottle_week', 'Turn your everyday bottle into workout gear', 'water_bottle', 3,
   (NOW() + INTERVAL '5 days')::date, (NOW() + INTERVAL '12 days')::date, 'badge',
   '{"badge_name": "Bottle Warrior", "badge_icon": "bottle-badge", "description": "Complete the water bottle workout series"}', 'UPCOMING', true, 2, 0, 0, 0.0, NOW(), NOW()),

  -- Future theme week
  ('cuid_themeweek_backpack', '#Backpack Week', 'backpack_week', 'Stay fit even while traveling', 'backpack', 5,
   (NOW() + INTERVAL '12 days')::date, (NOW() + INTERVAL '19 days')::date, 'rarity_boost',
   '{"boost_multiplier": 1.5, "duration_days": 7, "description": "Increase all card rarities by 50%"}', 'UPCOMING', true, 3, 0, 0, 0.0, NOW(), NOW()),

  -- Past theme weeks
  ('cuid_themeweek_wall', '#Wall Week', 'wall_week', 'Get a great workout using just a wall', 'wall', 3,
   (NOW() - INTERVAL '14 days')::date, (NOW() - INTERVAL '7 days')::date, 'skin',
   '{"skin_name": "Wall Master", "skin_color": "#C0C0C0", "rarity": "UNCOMMON"}', 'COMPLETED', false, 4, 89, 72, 80.9, NOW(), NOW()),

  ('cuid_themeweek_none', '#No-Equipment Week', 'none_week', 'Bodyweight training challenge', 'none', 7,
   (NOW() - INTERVAL '21 days')::date, (NOW() - INTERVAL '14 days')::date, 'badge',
   '{"badge_name": "Minimalist", "badge_icon": "minimalist-badge", "description": "Completed the no-equipment training week"}', 'COMPLETED', false, 5, 156, 134, 85.9, NOW(), NOW())
ON CONFLICT (code) DO NOTHING;


-- ==========================================
-- 9. 训练会话数据 (25个会话) - 使用CUID格式
-- ==========================================

DO $$
DECLARE
  user_ids UUID[] := ARRAY[
    '550e8400-e29b-41d4-a716-446655440002'::UUID,  -- test@snaprep.com
    '550e8400-e29b-41d4-a716-446655440003'::UUID,  -- alice@example.com
    '550e8400-e29b-41d4-a716-446655440004'::UUID,  -- bob@example.com
    '550e8400-e29b-41d4-a716-446655440006'::UUID   -- anon1@temp.snaprep.com
  ];
  scenario_ids TEXT[] := ARRAY['cuid_scenario_office', 'cuid_scenario_home', 'cuid_scenario_park', 'cuid_scenario_gym'];
  intent_types TEXT[] := ARRAY['RELAX', 'STRETCH', 'MODERATE', 'STRENGTH'];
  difficulties TEXT[] := ARRAY['GREEN', 'BLUE', 'RED'];
  session_id TEXT;
  user_id UUID;
  i INTEGER;
BEGIN
  -- 为每个用户创建多个会话
  FOR i IN 1..25 LOOP
    user_id := user_ids[(i % 4) + 1];
    session_id := 'cuid_session_' || LPAD(i::text, 3, '0');

    INSERT INTO workout_sessions (
      id, user_id, intent_type, scenario_id, target_muscles, total_duration, difficulty,
      is_silent, status, started_at, completed_at, actual_duration, follow_mode,
      current_step, pause_count, skip_count, is_offline, ambient_noise, used_space,
      rating, feedback, created_at, updated_at
    )
    VALUES (
      session_id,
      user_id,
      intent_types[(i % 4) + 1]::"IntentType",
      scenario_ids[(i % 4) + 1],
      CASE WHEN i % 4 = 0 THEN '{"CHEST"}'
           WHEN i % 4 = 1 THEN '{"LEGS"}'
           WHEN i % 4 = 2 THEN '{"ARMS"}'
           ELSE '{"CORE"}' END::"PrimaryMuscle"[],
      60 + (i % 3) * 30, -- 60, 90, or 120 seconds
      difficulties[(i % 3) + 1]::"Difficulty",
      i % 5 = 0, -- 每5个会话中有1个静音
      CASE WHEN i <= 20 THEN 'COMPLETED'
           WHEN i <= 22 THEN 'IN_PROGRESS'
           ELSE 'PENDING' END::"SessionStatus",
      CASE WHEN i <= 22 THEN NOW() - INTERVAL '1 hour' * i
           ELSE NULL END,
      CASE WHEN i <= 20 THEN NOW() - INTERVAL '1 hour' * i + INTERVAL '1 minute' * (60 + (i % 3) * 30)
           ELSE NULL END,
      CASE WHEN i <= 20 THEN 60 + (i % 3) * 30 + (i % 10) - 5  -- 实际时长略有差异
           ELSE NULL END,
      i % 3 = 0, -- 每3个会话中有1个跟练模式
      CASE WHEN i <= 22 THEN (i % 5) + 1 ELSE 0 END,
      CASE WHEN i <= 22 THEN i % 3 ELSE 0 END,
      CASE WHEN i <= 22 THEN i % 2 ELSE 0 END,
      i % 7 = 0, -- 每7个会话中有1个离线
      CASE WHEN i % 4 = 0 THEN 'SILENT'
           WHEN i % 4 = 1 THEN 'QUIET'
           ELSE 'NORMAL' END::"NoiseLevel",
      CASE WHEN i % 3 = 0 THEN 'SMALL'
           WHEN i % 3 = 1 THEN 'MEDIUM'
           ELSE 'LARGE' END::"SpaceSize",
      CASE WHEN i <= 20 THEN (i % 5) + 1 ELSE NULL END, -- 1-5星评分
      CASE WHEN i <= 20 AND i % 4 = 0 THEN '很棒的训练体验！'
           WHEN i <= 20 AND i % 4 = 1 THEN '动作很有效果'
           WHEN i <= 20 AND i % 4 = 2 THEN '时间安排合理'
           ELSE NULL END,
      NOW() - INTERVAL '1 day' * ((i - 1) / 3),
      NOW()
    );
  END LOOP;
END $$;

-- ==========================================
-- 10. 会话动作关联数据 (SessionExercise)
-- ==========================================

DO $$
DECLARE
  completed_sessions CURSOR FOR
    SELECT id FROM workout_sessions WHERE status = 'COMPLETED' ORDER BY created_at DESC;
  exercise_ids TEXT[] := ARRAY[
    'cuid_exercise_wall_pushup', 'cuid_exercise_chair_squat', 'cuid_exercise_bottle_bicep_curl',
    'cuid_exercise_plank', 'cuid_exercise_neck_stretch', 'cuid_exercise_standard_pushup',
    'cuid_exercise_shoulder_roll', 'cuid_exercise_jumping_jacks', 'cuid_exercise_chair_dips'
  ];
  session_record RECORD;
  i INTEGER;
  exercise_id TEXT;
BEGIN
  i := 1;
  FOR session_record IN completed_sessions LOOP
    -- 每个会话添加3个动作
    FOR j IN 1..3 LOOP
      exercise_id := exercise_ids[(((i - 1) * 3 + j - 1) % 9) + 1];

      INSERT INTO session_exercises (
        id, session_id, exercise_id, sequence_order, duration, sets, is_completed,
        actual_duration, started_at, ended_at, paused_times, skip_reason,
        difficulty_felt, comfort_level, effectiveness_rating, created_at
      )
      VALUES (
        'cuid_sessionex_' || LPAD(((i - 1) * 3 + j)::text, 3, '0'),
        session_record.id,
        exercise_id,
        j,
        20 + (j % 3) * 10, -- 20, 30, 20
        CASE WHEN j % 2 = 1 THEN 3 ELSE 1 END,
        true,
        20 + (j % 3) * 10 + (j % 5) - 2, -- 实际时长略有差异
        NOW() - INTERVAL '1 day' * i + INTERVAL '1 minute' * ((j-1) * 25),
        NOW() - INTERVAL '1 day' * i + INTERVAL '1 minute' * (j * 25),
        CASE WHEN j % 4 = 0 THEN 1 ELSE 0 END,
        CASE WHEN j % 7 = 0 THEN '动作太难' ELSE NULL END,
        CASE WHEN j % 3 = 0 THEN 'GREEN'
             WHEN j % 3 = 1 THEN 'BLUE'
             ELSE 'RED' END::"Difficulty",
        (j % 5) + 1, -- 1-5分舒适度
        (j % 5) + 1, -- 1-5分有效性
        NOW() - INTERVAL '1 day' * i
      );
    END LOOP;

    i := i + 1;
    EXIT WHEN i > 20; -- 只为前20个完成的会话添加动作
  END LOOP;
END $$;

-- ==========================================
-- 11. 分享卡片数据 (ShareCard) - 使用CUID格式
-- ==========================================

DO $$
DECLARE
  completed_sessions CURSOR FOR
    SELECT id, user_id FROM workout_sessions WHERE status = 'COMPLETED' ORDER BY created_at DESC LIMIT 15;
  session_record RECORD;
  rarity_levels TEXT[] := ARRAY['COMMON', 'UNCOMMON', 'FINE', 'RARE', 'ELITE', 'EPIC', 'MYTHIC', 'LEGENDARY', 'APEX'];
  equipment_codes TEXT[] := ARRAY['chair', 'wall', 'none', 'water_bottle', 'sofa', 'backpack'];
  templates TEXT[] := ARRAY['classic', 'minimal', 'vibrant', 'elegant', 'sport'];
  i INTEGER := 1;
BEGIN
  FOR session_record IN completed_sessions LOOP
    INSERT INTO share_cards (
      id, user_id, session_id, card_image_url, card_template, card_data,
      rarity, personal_stars, equipment_series, rarity_score, data_source,
      special_tags, city_edition, theme_week, share_text, is_public,
      share_count, view_count, created_at, updated_at
    )
    VALUES (
      'cuid_sharecard_' || LPAD(i::text, 3, '0'),
      session_record.user_id,
      session_record.id,
      'https://cdn.snaprep.com/cards/card_' || i || '.png',
      templates[(i % 5) + 1],
      json_build_object(
        'duration', 60 + (i % 3) * 30,
        'exercises', 3,
        'difficulty', CASE WHEN i % 3 = 0 THEN 'GREEN' WHEN i % 3 = 1 THEN 'BLUE' ELSE 'RED' END,
        'scenario', 'office',
        'equipment', equipment_codes[(i % 6) + 1]
      ),
      rarity_levels[(i % 9) + 1]::"RarityLevel",
      (i % 5) + 1, -- 1-5星个人稀有度
      equipment_codes[(i % 6) + 1] || '_series',
      CASE WHEN i % 9 = 0 THEN 0.95  -- COMMON
           WHEN i % 9 = 1 THEN 0.85  -- UNCOMMON
           WHEN i % 9 = 2 THEN 0.70  -- FINE
           WHEN i % 9 = 3 THEN 0.50  -- RARE
           WHEN i % 9 = 4 THEN 0.25  -- ELITE
           WHEN i % 9 = 5 THEN 0.10  -- EPIC
           WHEN i % 9 = 6 THEN 0.03  -- MYTHIC
           WHEN i % 9 = 7 THEN 0.01  -- LEGENDARY
           ELSE 0.001 END,  -- APEX
      'WEEKLY_TABLE'::"DataSource",
      CASE WHEN i % 4 = 0 THEN ARRAY['streak_bonus']
           WHEN i % 4 = 1 THEN ARRAY['first_time', 'silent_mode']
           ELSE ARRAY[]::TEXT[] END,
      CASE WHEN i % 6 = 0 THEN '北京版'
           WHEN i % 6 = 1 THEN '上海版'
           ELSE NULL END,
      CASE WHEN i % 7 = 0 THEN 'chair_week'
           WHEN i % 7 = 1 THEN 'wall_week'
           ELSE NULL END,
      CASE WHEN i % 5 = 0 THEN '今日完成了椅子训练，感觉很棒！#椅子日 #SnapRep'
           WHEN i % 5 = 1 THEN '墙面俯卧撑挑战成功！💪 #健身 #坚持'
           ELSE NULL END,
      i % 8 != 0, -- 大部分卡片公开，少数私密
      FLOOR(RANDOM() * 50) + (CASE WHEN i % 9 < 3 THEN 50 ELSE 10 END), -- 稀有卡片分享更多
      FLOOR(RANDOM() * 200) + (CASE WHEN i % 9 < 3 THEN 200 ELSE 20 END), -- 稀有卡片浏览更多
      NOW() - INTERVAL '1 day' * FLOOR(RANDOM() * 30),
      NOW()
    );

    i := i + 1;
  END LOOP;
END $$;

-- ==========================================
-- 12. 稀有度统计数据 (RarityTable) - 使用CUID格式
-- ==========================================

INSERT INTO rarity_table (id, equipment_id, equipment_code, week_start, rarity_score, rarity_level, data_source, region, created_at, updated_at)
VALUES
  -- 常见器材 (COMMON 80-95%)
  ('cuid_rarity_chair_001', 'cuid_equipment_chair', 'chair', '2024-01-01'::date, 0.85, 'COMMON', 'WEEKLY_TABLE', '全国', NOW(), NOW()),
  ('cuid_rarity_none_001', 'cuid_equipment_none', 'none', '2024-01-01'::date, 0.95, 'COMMON', 'WEEKLY_TABLE', '全国', NOW(), NOW()),
  ('cuid_rarity_wall_001', 'cuid_equipment_wall', 'wall', '2024-01-01'::date, 0.80, 'COMMON', 'WEEKLY_TABLE', '全国', NOW(), NOW()),

  -- 不常见器材 (UNCOMMON 60-80%)
  ('cuid_rarity_sofa_001', 'cuid_equipment_sofa', 'sofa', '2024-01-01'::date, 0.70, 'UNCOMMON', 'WEEKLY_TABLE', '全国', NOW(), NOW()),
  ('cuid_rarity_desk_001', 'cuid_equipment_desk', 'desk', '2024-01-01'::date, 0.65, 'UNCOMMON', 'WEEKLY_TABLE', '全国', NOW(), NOW()),

  -- 精致器材 (FINE 40-60%)
  ('cuid_rarity_bottle_001', 'cuid_equipment_water_bottle', 'water_bottle', '2024-01-01'::date, 0.50, 'FINE', 'WEEKLY_TABLE', '全国', NOW(), NOW()),
  ('cuid_rarity_towel_001', 'cuid_equipment_towel', 'towel', '2024-01-01'::date, 0.45, 'FINE', 'WEEKLY_TABLE', '全国', NOW(), NOW()),

  -- 稀有器材 (RARE 20-40%)
  ('cuid_rarity_backpack_001', 'cuid_equipment_backpack', 'backpack', '2024-01-01'::date, 0.30, 'RARE', 'WEEKLY_TABLE', '全国', NOW(), NOW()),
  ('cuid_rarity_stairs_001', 'cuid_equipment_stairs', 'stairs', '2024-01-01'::date, 0.25, 'RARE', 'WEEKLY_TABLE', '全国', NOW(), NOW()),

  -- 精英器材 (ELITE 10-20%)
  ('cuid_rarity_bed_001', 'cuid_equipment_bed', 'bed', '2024-01-01'::date, 0.15, 'ELITE', 'WEEKLY_TABLE', '全国', NOW(), NOW()),
  ('cuid_rarity_umbrella_001', 'cuid_equipment_umbrella', 'umbrella', '2024-01-01'::date, 0.12, 'ELITE', 'WEEKLY_TABLE', '全国', NOW(), NOW()),

  -- 史诗器材 (EPIC 3-10%)
  ('cuid_rarity_tree_001', 'cuid_equipment_tree', 'tree', '2024-01-01'::date, 0.08, 'EPIC', 'WEEKLY_TABLE', '全国', NOW(), NOW()),
  ('cuid_rarity_bench_001', 'cuid_equipment_bench', 'bench', '2024-01-01'::date, 0.05, 'EPIC', 'WEEKLY_TABLE', '全国', NOW(), NOW()),

  -- 神话器材 (MYTHIC 1-3%)
  ('cuid_rarity_suitcase_001', 'cuid_equipment_suitcase', 'suitcase', '2024-01-01'::date, 0.02, 'MYTHIC', 'WEEKLY_TABLE', '全国', NOW(), NOW()),
  ('cuid_rarity_wine_001', 'cuid_equipment_wine_bottle', 'wine_bottle', '2024-01-01'::date, 0.015, 'MYTHIC', 'WEEKLY_TABLE', '全国', NOW(), NOW()),

  -- 传说器材 (LEGENDARY 0.3-1%)
  ('cuid_rarity_mop_001', 'cuid_equipment_mop', 'mop', '2024-01-01'::date, 0.008, 'LEGENDARY', 'WEEKLY_TABLE', '全国', NOW(), NOW()),
  ('cuid_rarity_rock_001', 'cuid_equipment_rock', 'rock', '2024-01-01'::date, 0.005, 'LEGENDARY', 'WEEKLY_TABLE', '全国', NOW(), NOW()),

  -- 顶点器材 (APEX <0.3%)
  ('cuid_rarity_book_001', 'cuid_equipment_book', 'book', '2024-01-01'::date, 0.002, 'APEX', 'WEEKLY_TABLE', '全国', NOW(), NOW()),
  ('cuid_rarity_handbag_001', 'cuid_equipment_handbag', 'handbag', '2024-01-01'::date, 0.001, 'APEX', 'WEEKLY_TABLE', '全国', NOW(), NOW())
ON CONFLICT (equipment_code, week_start) DO NOTHING;

-- ==========================================
-- 13. 主题周参与数据 (ThemeWeekParticipation)
-- ==========================================

DO $$
DECLARE
  user_ids UUID[] := ARRAY[
    '550e8400-e29b-41d4-a716-446655440002'::UUID,  -- test@snaprep.com
    '550e8400-e29b-41d4-a716-446655440003'::UUID,  -- alice@example.com
    '550e8400-e29b-41d4-a716-446655440004'::UUID,  -- bob@example.com
    '550e8400-e29b-41d4-a716-446655440008'::UUID   -- premium@example.com
  ];
  statuses TEXT[] := ARRAY['JOINED', 'IN_PROGRESS', 'COMPLETED', 'FAILED'];
  i INTEGER;
BEGIN
  FOR i IN 1..12 LOOP
    INSERT INTO theme_week_participations (
      id, user_id, theme_week_id, status, joined_at, completed_at,
      exercises_completed, target_exercises, progress_percent,
      reward_earned, reward_claimed_at, related_sessions, created_at, updated_at
    )
    VALUES (
      'cuid_themepart_' || LPAD(i::text, 3, '0'),
      user_ids[(i % 4) + 1],
      CASE WHEN i % 4 = 0 THEN 'cuid_themeweek_chair'
           WHEN i % 4 = 1 THEN 'cuid_themeweek_wall'
           WHEN i % 4 = 2 THEN 'cuid_themeweek_none'
           ELSE 'cuid_themeweek_chair' END,
      statuses[(i % 4) + 1]::TEXT,
      NOW() - INTERVAL '1 day' * (i % 7),
      CASE WHEN statuses[(i % 4) + 1] = 'COMPLETED'
           THEN NOW() - INTERVAL '1 day' * ((i % 7) - 2)
           ELSE NULL END,
      CASE WHEN statuses[(i % 4) + 1] = 'COMPLETED' THEN 3
           WHEN statuses[(i % 4) + 1] = 'IN_PROGRESS' THEN (i % 3) + 1
           WHEN statuses[(i % 4) + 1] = 'FAILED' THEN (i % 2) + 1
           ELSE 0 END,
      3, -- 所有主题周目标都是3个动作
      CASE WHEN statuses[(i % 4) + 1] = 'COMPLETED' THEN 100.0
           WHEN statuses[(i % 4) + 1] = 'IN_PROGRESS' THEN ROUND(((i % 3) + 1) * 33.33, 1)
           WHEN statuses[(i % 4) + 1] = 'FAILED' THEN ROUND(((i % 2) + 1) * 33.33, 1)
           ELSE 0.0 END,
      statuses[(i % 4) + 1] = 'COMPLETED',
      CASE WHEN statuses[(i % 4) + 1] = 'COMPLETED'
           THEN NOW() - INTERVAL '1 day' * ((i % 7) - 1)
           ELSE NULL END,
      CASE WHEN i % 3 = 0 THEN ARRAY['cuid_session_001', 'cuid_session_002']
           WHEN i % 3 = 1 THEN ARRAY['cuid_session_003']
           ELSE ARRAY[]::TEXT[] END,
      NOW() - INTERVAL '1 day' * (i % 7),
      NOW()
    )
    ON CONFLICT (user_id, theme_week_id) DO UPDATE
    SET status              = EXCLUDED.status,
        joined_at           = EXCLUDED.joined_at,
        completed_at        = EXCLUDED.completed_at,
        exercises_completed = EXCLUDED.exercises_completed,
        target_exercises    = EXCLUDED.target_exercises,
        progress_percent    = EXCLUDED.progress_percent,
        reward_earned       = EXCLUDED.reward_earned,
        reward_claimed_at   = EXCLUDED.reward_claimed_at,
        related_sessions    = EXCLUDED.related_sessions,
        updated_at          = NOW();
        -- 如果你不想覆盖已有数据，改成：DO NOTHING
  END LOOP;
END $$;


-- ==========================================
-- 14. 用户偏好数据 (UserPreference)
-- ==========================================

DO $$
DECLARE
  user_ids UUID[] := ARRAY[
    '550e8400-e29b-41d4-a716-446655440002'::UUID,  -- test@snaprep.com
    '550e8400-e29b-41d4-a716-446655440003'::UUID,  -- alice@example.com
    '550e8400-e29b-41d4-a716-446655440004'::UUID   -- bob@example.com
  ];
  preference_types TEXT[] := ARRAY['equipment', 'intent', 'difficulty', 'duration', 'scenario'];
  equipment_codes TEXT[] := ARRAY['chair', 'wall', 'none', 'water_bottle', 'sofa'];
  intent_types TEXT[] := ARRAY['RELAX', 'STRETCH', 'MODERATE', 'STRENGTH'];
  difficulties TEXT[] := ARRAY['GREEN', 'BLUE', 'RED'];
  scenarios TEXT[] := ARRAY['office', 'home', 'park', 'gym'];
  i INTEGER;
  j INTEGER;
  user_id UUID;
BEGIN
  FOR i IN 1..3 LOOP -- 为3个主要用户创建偏好
    user_id := user_ids[i];

    -- 器材偏好
    FOR j IN 1..5 LOOP
      INSERT INTO user_preferences (
        id, user_id, preference_type, preference_key, preference_value,
        usage_count, success_rate, average_rating, last_used_at, first_used_at,
        created_at, updated_at
      )
      VALUES (
        'cuid_userpref_' || i || '_equip_' || j,
        user_id,
        'equipment',
        equipment_codes[j],
        ROUND((RANDOM() * 0.8 + 0.2)::numeric, 2), -- 0.2-1.0
        FLOOR(RANDOM() * 20) + 5, -- 5-25次使用
        ROUND((RANDOM() * 0.3 + 0.7)::numeric, 2), -- 70-100%成功率
        ROUND((RANDOM() * 2 + 3)::numeric, 1), -- 3.0-5.0分评分
        NOW() - INTERVAL '1 day' * FLOOR(RANDOM() * 30),
        NOW() - INTERVAL '30 days',
        NOW() - INTERVAL '30 days',
        NOW()
      );
    END LOOP;

    -- 意图偏好
    FOR j IN 1..4 LOOP
      INSERT INTO user_preferences (
        id, user_id, preference_type, preference_key, preference_value,
        usage_count, success_rate, average_rating, last_used_at, first_used_at,
        created_at, updated_at
      )
      VALUES (
        'cuid_userpref_' || i || '_intent_' || j,
        user_id,
        'intent',
        intent_types[j],
        ROUND((RANDOM() * 0.8 + 0.2)::numeric, 2),
        FLOOR(RANDOM() * 15) + 3,
        ROUND((RANDOM() * 0.3 + 0.7)::numeric, 2),
        ROUND((RANDOM() * 2 + 3)::numeric, 1),
        NOW() - INTERVAL '1 day' * FLOOR(RANDOM() * 15),
        NOW() - INTERVAL '20 days',
        NOW() - INTERVAL '20 days',
        NOW()
      );
    END LOOP;
  END LOOP;
END $$;

-- ==========================================
-- 15. 每日训练统计 (DailyTraining)
-- ==========================================

DO $$
DECLARE
  user_ids UUID[] := ARRAY[
    '550e8400-e29b-41d4-a716-446655440002'::UUID,  -- test@snaprep.com
    '550e8400-e29b-41d4-a716-446655440003'::UUID   -- alice@example.com
  ];
  user_id UUID;
  train_date DATE;
  i INTEGER;
  j INTEGER;
BEGIN
  FOR i IN 1..2 LOOP -- 为2个用户创建统计
    user_id := user_ids[i];

    FOR j IN 0..29 LOOP -- 过去30天
      train_date := (NOW() - INTERVAL '1 day' * j)::DATE;

      -- 模拟训练模式：周日休息，其他天随机训练
      IF EXTRACT(DOW FROM train_date) != 0 THEN -- 非周日
        INSERT INTO daily_trainings (
          id, user_id, training_date, total_sessions, total_duration, total_exercises,
          completed_sessions, intent_breakdown, muscle_breakdown, is_streak_day,
          achievements, created_at, updated_at
        )
        VALUES (
          'cuid_daily_' || i || '_' || LPAD((30-j)::text, 2, '0'),
          user_id,
          train_date,
          CASE WHEN RANDOM() > 0.3 THEN FLOOR(RANDOM() * 2) + 1 ELSE 0 END, -- 70%概率训练
          CASE WHEN RANDOM() > 0.3 THEN FLOOR(RANDOM() * 60) + 60 ELSE 0 END,
          CASE WHEN RANDOM() > 0.3 THEN FLOOR(RANDOM() * 6) + 3 ELSE 0 END,
          CASE WHEN RANDOM() > 0.3 THEN FLOOR(RANDOM() * 2) + 1 ELSE 0 END,
          CASE WHEN RANDOM() > 0.3 THEN
            json_build_object(
              'RELAX', FLOOR(RANDOM() * 30),
              'STRETCH', FLOOR(RANDOM() * 30),
              'MODERATE', FLOOR(RANDOM() * 60),
              'STRENGTH', FLOOR(RANDOM() * 30)
            )
          ELSE '{}' END,
          CASE WHEN RANDOM() > 0.3 THEN
            json_build_object(
              'CHEST', FLOOR(RANDOM() * 2),
              'LEGS', FLOOR(RANDOM() * 3) + 1,
              'ARMS', FLOOR(RANDOM() * 2),
              'CORE', FLOOR(RANDOM() * 2)
            )
          ELSE '{}' END,
          RANDOM() > 0.3, -- 70%概率为连击日
          CASE WHEN j % 7 = 0 AND RANDOM() > 0.5 THEN ARRAY['weekly_warrior', 'consistency_king']
               WHEN j % 14 = 0 AND RANDOM() > 0.7 THEN ARRAY['fortnight_fighter']
               ELSE ARRAY[]::TEXT[] END,
          train_date,
          NOW()
        );
      ELSE
        -- 周日休息日记录
        INSERT INTO daily_trainings (
          id, user_id, training_date, total_sessions, total_duration, total_exercises,
          completed_sessions, intent_breakdown, muscle_breakdown, is_streak_day,
          achievements, created_at, updated_at
        )
        VALUES (
          'cuid_daily_' || i || '_' || LPAD((30-j)::text, 2, '0'),
          user_id,
          train_date,
          0, 0, 0, 0,
          '{}', '{}', false,
          CASE WHEN RANDOM() > 0.8 THEN ARRAY['rest_day_wisdom'] ELSE ARRAY[]::TEXT[] END,
          train_date,
          NOW()
        );
      END IF;
    END LOOP;
  END LOOP;
END $$;

-- ==========================================
-- 16. 深链系统数据 (Deeplink & DeeplinkClick)
-- ==========================================

DO $$
DECLARE
  session_ids   TEXT[] := ARRAY['cuid_session_001', 'cuid_session_002', 'cuid_session_003'];
  theme_week_ids TEXT[] := ARRAY['cuid_themeweek_chair', 'cuid_themeweek_bottle'];
  share_card_ids TEXT[] := ARRAY['cuid_sharecard_001', 'cuid_sharecard_002', 'cuid_sharecard_003'];
  exercise_ids   TEXT[] := ARRAY['cuid_exercise_wall_pushup', 'cuid_exercise_chair_squat'];
  deeplink_id    TEXT;
  i INTEGER;
  j INTEGER;
BEGIN
  FOR i IN 1..10 LOOP
    deeplink_id := 'cuid_deeplink_' || LPAD(i::text, 3, '0');

    INSERT INTO deeplinks (
      id, code, target_type, target_id, created_by, expires_at, created_at
    )
    VALUES (
      deeplink_id,
      'dl' || LPAD(i::text, 6, '0'),
      CASE WHEN i % 4 = 1 THEN 'WORKOUT_SESSION'
           WHEN i % 4 = 2 THEN 'THEME_WEEK'
           WHEN i % 4 = 3 THEN 'SHARE_CARD'
           ELSE 'EXERCISE' END::"DeeplinkTargetType",
      CASE WHEN i % 4 = 1 THEN session_ids[(i % 3) + 1]
           WHEN i % 4 = 2 THEN theme_week_ids[(i % 2) + 1]
           WHEN i % 4 = 3 THEN share_card_ids[(i % 3) + 1]
           ELSE exercise_ids[(i % 2) + 1] END,
      CASE WHEN i % 3 = 0
           THEN '550e8400-e29b-41d4-a716-446655440002'::UUID
           ELSE NULL::UUID END,
      CASE WHEN i % 5 = 0 THEN NOW() + INTERVAL '30 days' ELSE NULL END,
      NOW() - INTERVAL '1 day' * (i % 10)
    )
    ON CONFLICT (code) DO NOTHING; -- 可选：方便脚本可重复执行
  END LOOP;
END $$;


-- ==========================================
-- 17. 临时Post数据 (保持兼容性)
-- ==========================================

-- INSERT INTO posts (id, title, content, published, author_id, created_at, updated_at)
-- VALUES
--   ('cuid_post_001', '欢迎使用SnapRep', '这是一个测试文章，用于验证系统功能。', true, '550e8400-e29b-41d4-a716-446655440002', NOW(), NOW()),
--   ('cuid_post_002', 'API接口文档', 'GraphQL和REST接口的使用说明...', true, '550e8400-e29b-41d4-a716-446655440001', NOW(), NOW()),
--   ('cuid_post_003', '草稿文章', '这是一篇未发布的草稿。', false, '550e8400-e29b-41d4-a716-446655440003', NOW(), NOW())
-- ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 18. 挑战系统测试数据 (v3.1 简化设计)
-- ==========================================

-- 清理旧的挑战数据
DELETE FROM challenge_completions;
DELETE FROM challenge_items;

-- 18.1) 挑战数据 (12个挑战，使用3x4网格展示，英文界面，简化设计)
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

-- 18.2) 挑战完成记录测试数据 (简化设计)
INSERT INTO challenge_completions (
  id, user_id, challenge_item_id, workout_session_id,
  status, started_at, completed_at, abandoned_at,
  actual_duration, completed_count, progress_percent,
  difficulty_felt, enjoyment_rating, feedback,
  badge_earned, xp_earned, bonus_rewards,
  created_at, updated_at
)
VALUES
  -- Test user 完成记录
  ('cuid_completion_001', '550e8400-e29b-41d4-a716-446655440002', 'cuid_challenge_umbrella', 'cuid_session_001',
   'COMPLETED', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour 55 minutes', NULL,
   320, 3, 100.0, 3, 5, 'Great workout! Really enjoyed using the umbrella for resistance.',
   'COMMON', 150, '{"specialAchievement": "first_umbrella_challenge", "bonusXP": 50}',
   NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour 55 minutes'),

  ('cuid_completion_002', '550e8400-e29b-41d4-a716-446655440002', 'cuid_challenge_book', NULL,
   'COMPLETED', NOW() - INTERVAL '1 day', NOW() - INTERVAL '23 hours 56 minutes', NULL,
   240, 3, 100.0, 2, 4, 'Simple but effective. Good for beginners.',
   'COMMON', 120, NULL,
   NOW() - INTERVAL '1 day', NOW() - INTERVAL '23 hours 56 minutes'),

  ('cuid_completion_003', '550e8400-e29b-41d4-a716-446655440002', 'cuid_challenge_none', 'cuid_session_003',
   'IN_PROGRESS', NOW() - INTERVAL '30 minutes', NULL, NULL,
   NULL, 2, 40.0, NULL, NULL, NULL,
   NULL, 0, NULL,
   NOW() - INTERVAL '30 minutes', NOW()),

  -- Alice 完成记录
  ('cuid_completion_004', '550e8400-e29b-41d4-a716-446655440003', 'cuid_challenge_chair', 'cuid_session_002',
   'COMPLETED', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '2 hours 56 minutes', NULL,
   240, 3, 100.0, 1, 5, 'Perfect for office breaks! Highly recommend.',
   'COMMON', 140, '{"specialAchievement": "office_warrior"}',
   NOW() - INTERVAL '3 hours', NOW() - INTERVAL '2 hours 56 minutes'),

  ('cuid_completion_005', '550e8400-e29b-41d4-a716-446655440003', 'cuid_challenge_bottle', NULL,
   'COMPLETED', NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '15 minutes', NULL,
   900, 3, 100.0, 2, 4, 'Good hydration reminder too!',
   'COMMON', 130, NULL,
   NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days' + INTERVAL '15 minutes'),

  -- Bob 完成记录
  ('cuid_completion_006', '550e8400-e29b-41d4-a716-446655440004', 'cuid_challenge_backpack', NULL,
   'COMPLETED', NOW() - INTERVAL '5 hours', NOW() - INTERVAL '4 hours 55 minutes', NULL,
   1200, 4, 100.0, 4, 3, 'Challenging but rewarding. Good for travel.',
   'FINE', 200, '{"specialAchievement": "travel_fitness_expert", "bonusXP": 75}',
   NOW() - INTERVAL '5 hours', NOW() - INTERVAL '4 hours 55 minutes'),

  ('cuid_completion_007', '550e8400-e29b-41d4-a716-446655440004', 'cuid_challenge_wall', NULL,
   'COMPLETED', NOW() - INTERVAL '1 day 2 hours', NOW() - INTERVAL '1 day 1 hour 45 minutes', NULL,
   900, 4, 100.0, 3, 4, 'Wall exercises are underrated. Great workout!',
   'UNCOMMON', 180, NULL,
   NOW() - INTERVAL '1 day 2 hours', NOW() - INTERVAL '1 day 1 hour 45 minutes'),

  -- Premium user 高难度挑战
  ('cuid_completion_008', '550e8400-e29b-41d4-a716-446655440008', 'cuid_challenge_tree', NULL,
   'COMPLETED', NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '25 minutes', NULL,
   1500, 5, 100.0, 5, 5, 'Amazing outdoor experience! Nature workout is the best.',
   'RARE', 300, '{"specialAchievement": "nature_warrior", "bonusXP": 100}',
   NOW() - INTERVAL '3 days', NOW() - INTERVAL '3 days' + INTERVAL '25 minutes'),

  -- Abandoned challenge example
  ('cuid_completion_009', '550e8400-e29b-41d4-a716-446655440003', 'cuid_challenge_stairs', NULL,
   'ABANDONED', NOW() - INTERVAL '6 hours', NULL, NOW() - INTERVAL '5 hours 30 minutes',
   1800, 2, 50.0, 5, 2, 'Too intense for me right now. Will try again later.',
   NULL, 0, NULL,
   NOW() - INTERVAL '6 hours', NOW() - INTERVAL '5 hours 30 minutes'),

  -- Recent completion
  ('cuid_completion_010', '550e8400-e29b-41d4-a716-446655440002', 'cuid_challenge_towel', NULL,
   'COMPLETED', NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days' + INTERVAL '12 minutes', NULL,
   720, 3, 100.0, 2, 5, 'Great for flexibility. Feel much better!',
   'UNCOMMON', 160, '{"specialAchievement": "flexibility_master"}',
   NOW() - INTERVAL '4 days', NOW() - INTERVAL '4 days' + INTERVAL '12 minutes')
ON CONFLICT (user_id, challenge_item_id) DO NOTHING;

-- ==========================================
-- 数据插入完成 - 验证统计
-- ==========================================

-- 基础数据统计
SELECT
  'SnapRep v3.1 测试数据统计' as category,
  (SELECT COUNT(*) FROM scenarios) as scenarios_count,
  (SELECT COUNT(*) FROM equipment) as equipment_count,
  (SELECT COUNT(*) FROM exercises) as exercises_count,
  (SELECT COUNT(*) FROM scenario_equipment) as scenario_equipment_count

UNION ALL

-- 用户与训练数据
SELECT
  '用户与训练数据统计' as category,
  (SELECT COUNT(*) FROM users) as users_count,
  (SELECT COUNT(*) FROM workout_sessions) as sessions_count,
  (SELECT COUNT(*) FROM session_exercises) as session_exercises_count,
  (SELECT COUNT(*) FROM share_cards) as cards_count

UNION ALL

-- 活动与系统数据
SELECT
  '活动与系统数据统计' as category,
  (SELECT COUNT(*) FROM theme_weeks) as theme_weeks_count,
  (SELECT COUNT(*) FROM theme_week_participations) as participations_count,
  (SELECT COUNT(*) FROM rarity_table) as rarity_entries_count,
  (SELECT COUNT(*) FROM deeplinks) as deeplinks_count

UNION ALL

-- 挑战系统数据统计 (v3.1 新增)
SELECT
  '挑战系统数据统计' as category,
  (SELECT COUNT(*) FROM challenge_items) as challenge_items_count,
  (SELECT COUNT(*) FROM challenge_completions) as challenge_completions_count,
  (SELECT COUNT(*) FROM challenge_completions WHERE status = 'COMPLETED') as completed_challenges_count,
  (SELECT COUNT(*) FROM challenge_completions WHERE status IN ('STARTED', 'IN_PROGRESS')) as active_challenges_count;

-- 关键业务数据验证
SELECT
  '关键业务数据验证' as check_name,
  '成功' as status,
  '所有表数据已按schema.prisma格式正确插入（包含挑战系统）' as description
WHERE EXISTS (SELECT 1 FROM scenarios)
  AND EXISTS (SELECT 1 FROM equipment)
  AND EXISTS (SELECT 1 FROM scenario_equipment)
  AND EXISTS (SELECT 1 FROM exercises)
  AND EXISTS (SELECT 1 FROM users)
  AND EXISTS (SELECT 1 FROM workout_sessions)
  AND EXISTS (SELECT 1 FROM share_cards)
  AND EXISTS (SELECT 1 FROM challenge_items)
  AND EXISTS (SELECT 1 FROM challenge_completions);

-- 验证ScenarioEquipment关联数据
SELECT
  'ScenarioEquipment关联验证' as check_name,
  s.name as scenario_name,
  COUNT(se.equipment_id) as equipment_count,
  COUNT(CASE WHEN se.is_common THEN 1 END) as common_equipment_count
FROM scenarios s
LEFT JOIN scenario_equipment se ON s.id = se.scenario_id
GROUP BY s.id, s.name
ORDER BY equipment_count DESC;

-- 验证挑战系统关联数据 (v3.1 新增)
SELECT
  '挑战系统关联验证' as check_name,
  ci.title as challenge_title,
  e.name as equipment_name,
  e.category as equipment_category,
  ci.time_limit as time_limit_minutes,
  ci.target_count as target_exercises,
  COUNT(cc.id) as completion_count,
  COUNT(CASE WHEN cc.status = 'COMPLETED' THEN 1 END) as completed_count
FROM challenge_items ci
LEFT JOIN equipment e ON ci.equipment_id = e.id
LEFT JOIN challenge_completions cc ON ci.id = cc.challenge_item_id
GROUP BY ci.id, ci.title, e.name, e.category, ci.time_limit, ci.target_count
ORDER BY ci.display_order;

-- ==========================================
-- ==========================================
-- 补充数据区域 - scenario_equipment 和 theme_weeks
-- 这些表在之前的数据初始化中被跳过，现在补充
-- ==========================================
-- ==========================================

-- ==========================================
-- 补充 1: 场景-器材关联表 (ScenarioEquipment)
-- 这是核心关联数据，定义了每个场景中可用的器材
-- ==========================================

INSERT INTO scenario_equipment (scenario_id, equipment_id, is_common, created_at)
VALUES
  -- 办公室场景 (cuid_scenario_office) - 常用器材
  ('cuid_scenario_office', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_chair', true, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_desk', true, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_wall', true, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_water_bottle', true, NOW()),
  -- 办公室场景 - 不常见器材
  ('cuid_scenario_office', 'cuid_equipment_backpack', false, NOW()),
  ('cuid_scenario_office', 'cuid_equipment_book', false, NOW()),

  -- 居家客厅场景 (cuid_scenario_home) - 常用器材
  ('cuid_scenario_home', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_sofa', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_chair', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_wall', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_towel', true, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_stairs', true, NOW()),
  -- 居家客厅场景 - 不常见器材
  ('cuid_scenario_home', 'cuid_equipment_water_bottle', false, NOW()),
  ('cuid_scenario_home', 'cuid_equipment_book', false, NOW()),

  -- 公园户外场景 (cuid_scenario_park) - 常用器材
  ('cuid_scenario_park', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_bench', true, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_tree', true, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_rock', true, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_water_bottle', true, NOW()),
  -- 公园户外场景 - 不常见器材
  ('cuid_scenario_park', 'cuid_equipment_backpack', false, NOW()),
  ('cuid_scenario_park', 'cuid_equipment_towel', false, NOW()),

  -- 健身房场景 (cuid_scenario_gym) - 常用器材
  ('cuid_scenario_gym', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_gym', 'cuid_equipment_wall', true, NOW()),
  ('cuid_scenario_gym', 'cuid_equipment_bench', true, NOW()),
  ('cuid_scenario_gym', 'cuid_equipment_water_bottle', true, NOW()),
  ('cuid_scenario_gym', 'cuid_equipment_towel', true, NOW()),
  -- 健身房场景 - 不常见器材
  ('cuid_scenario_gym', 'cuid_equipment_backpack', false, NOW()),

  -- 酒店房间场景 (cuid_scenario_hotel) - 常用器材
  ('cuid_scenario_hotel', 'cuid_equipment_none', true, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_bed', true, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_chair', true, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_wall', true, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_towel', true, NOW()),
  -- 酒店房间场景 - 不常见器材
  ('cuid_scenario_hotel', 'cuid_equipment_suitcase', false, NOW()),
  ('cuid_scenario_hotel', 'cuid_equipment_water_bottle', false, NOW())
ON CONFLICT (scenario_id, equipment_id) DO NOTHING;

-- ==========================================
-- 补充 2: 主题周数据 (ThemeWeeks)
-- 包含5个主题周：1个进行中，2个即将开始，2个已完成
-- ==========================================

INSERT INTO theme_weeks (id, title, code, description, equipment_code, target_exercise_count, start_date, end_date, reward_type, reward_data, status, is_visible, display_order, total_participants, total_completions, completion_rate, created_at, updated_at)
VALUES
  -- Currently active theme week
  ('cuid_themeweek_chair', '#Chair Day', 'chair_week', 'Do 3 chair exercises to unlock a sticker skin', 'chair', 3,
   (NOW() - INTERVAL '2 days')::date, (NOW() + INTERVAL '5 days')::date, 'skin',
   '{"skin_name": "Chair Master", "skin_color": "#8B4513", "rarity": "RARE"}', 'ACTIVE', true, 1, 128, 67, 52.3, NOW(), NOW()),

  -- Upcoming theme week
  ('cuid_themeweek_bottle', '#Water Bottle Week', 'bottle_week', 'Turn your everyday bottle into workout gear', 'water_bottle', 3,
   (NOW() + INTERVAL '5 days')::date, (NOW() + INTERVAL '12 days')::date, 'badge',
   '{"badge_name": "Bottle Warrior", "badge_icon": "bottle-badge", "description": "Complete the water bottle workout series"}', 'UPCOMING', true, 2, 0, 0, 0.0, NOW(), NOW()),

  -- Future theme week
  ('cuid_themeweek_backpack', '#Backpack Week', 'backpack_week', 'Stay fit even while traveling', 'backpack', 5,
   (NOW() + INTERVAL '12 days')::date, (NOW() + INTERVAL '19 days')::date, 'rarity_boost',
   '{"boost_multiplier": 1.5, "duration_days": 7, "description": "Increase all card rarities by 50%"}', 'UPCOMING', true, 3, 0, 0, 0.0, NOW(), NOW()),

  -- Past theme weeks
  ('cuid_themeweek_wall', '#Wall Week', 'wall_week', 'Get a great workout using just a wall', 'wall', 3,
   (NOW() - INTERVAL '14 days')::date, (NOW() - INTERVAL '7 days')::date, 'skin',
   '{"skin_name": "Wall Master", "skin_color": "#C0C0C0", "rarity": "UNCOMMON"}', 'COMPLETED', false, 4, 89, 72, 80.9, NOW(), NOW()),

  ('cuid_themeweek_none', '#No-Equipment Week', 'none_week', 'Bodyweight training challenge', 'none', 7,
   (NOW() - INTERVAL '21 days')::date, (NOW() - INTERVAL '14 days')::date, 'badge',
   '{"badge_name": "Minimalist", "badge_icon": "minimalist-badge", "description": "Completed the no-equipment training week"}', 'COMPLETED', false, 5, 156, 134, 85.9, NOW(), NOW())
ON CONFLICT (code) DO NOTHING;

-- ==========================================
-- 补充数据验证查询
-- ==========================================

-- 验证scenario_equipment数据插入
SELECT
  '补充数据验证 - scenario_equipment' as check_name,
  COUNT(*) as total_records,
  COUNT(CASE WHEN is_common THEN 1 END) as common_equipment_count,
  COUNT(CASE WHEN NOT is_common THEN 1 END) as uncommon_equipment_count
FROM scenario_equipment;

-- 验证theme_weeks数据插入
SELECT
  '补充数据验证 - theme_weeks' as check_name,
  COUNT(*) as total_theme_weeks,
  COUNT(CASE WHEN status = 'ACTIVE' THEN 1 END) as active_weeks,
  COUNT(CASE WHEN status = 'UPCOMING' THEN 1 END) as upcoming_weeks,
  COUNT(CASE WHEN status = 'COMPLETED' THEN 1 END) as completed_weeks
FROM theme_weeks;

-- 验证scenario_equipment与scenarios的关联
SELECT
  'scenario_equipment关联统计' as check_name,
  s.name as scenario_name,
  s.code as scenario_code,
  COUNT(se.equipment_id) as equipment_count,
  COUNT(CASE WHEN se.is_common THEN 1 END) as common_count,
  COUNT(CASE WHEN NOT se.is_common THEN 1 END) as uncommon_count
FROM scenarios s
LEFT JOIN scenario_equipment se ON s.id = se.scenario_id
GROUP BY s.id, s.name, s.code
ORDER BY equipment_count DESC;

-- ==========================================
-- 数据补充完成提示
-- ==========================================

SELECT
  '✅ 数据补充完成' as status,
  'scenario_equipment 和 theme_weeks 表数据已成功追加到 complete-test-data.sql' as message,
  NOW() as completed_at;

COMMIT;