-- SnapRep Database Migration Script v3.0
-- Generated from: prisma/schema_v3.prisma
-- Date: 2024-10-30
-- Target: Supabase PostgreSQL
-- Author: Claude Code
--
-- 改进内容:
-- 1. 统一枚举命名（UPPER_SNAKE_CASE）
-- 2. 新增深链统计表（deeplinks, deeplink_clicks）
-- 3. 重命名 equipment_frequencies → rarity_table
-- 4. 新增数据来源枚举（DataSource）
-- 5. 新增稀有度枚举（RarityLevel）
-- 6. 难度改为颜色编码（GREEN, BLUE, RED）
-- 7. 完善 RLS 级联策略

-- ============================================================================
-- 1. CREATE ENUMS (枚举类型定义)
-- ============================================================================

-- 噪音等级枚举
CREATE TYPE "NoiseLevel" AS ENUM (
  'SILENT',   -- 必须静音 - 适合办公室、图书馆
  'QUIET',    -- 安静 - 适合酒店房间、宿舍
  'NORMAL'    -- 正常 - 适合家中、健身房
);

-- 空间大小枚举
CREATE TYPE "SpaceSize" AS ENUM (
  'SMALL',    -- 小空间 (1-2m²)
  'MEDIUM',   -- 中等 (2-4m²)
  'LARGE'     -- 大空间 (>4m²)
);

-- 器材分类枚举
CREATE TYPE "EquipmentCategory" AS ENUM (
  'NONE',       -- 徒手/无器材
  'FURNITURE',  -- 家具系
  'WALL',       -- 墙面系
  'BOTTLE',     -- 水瓶系
  'BAG',        -- 背包系
  'STAIRS',     -- 台阶系
  'FABRIC',     -- 布料系
  'STICK',      -- 棍棒系
  'OUTDOOR',    -- 户外系
  'CREATIVE'    -- 创意系
);

-- 主要肌群枚举
CREATE TYPE "PrimaryMuscle" AS ENUM (
  'CHEST',         -- 胸部肌群
  'BACK',          -- 背部肌群
  'LEGS',          -- 腿部肌群
  'GLUTES',        -- 臀部肌群
  'SHOULDERS',     -- 肩部肌群
  'ARMS',          -- 手臂肌群
  'CORE',          -- 核心肌群
  'FULL_BODY',     -- 全身综合
  'NECK_SHOULDER'  -- 颈肩部位
);

-- 运动意图枚举（v3.0 统一）
CREATE TYPE "IntentType" AS ENUM (
  'RELAX',    -- 放松模式
  'STRETCH',  -- 拉伸模式
  'MODERATE', -- 适度运动
  'STRENGTH'  -- 力量训练
);

-- 难度等级枚举（v3.0 改为颜色编码）
CREATE TYPE "Difficulty" AS ENUM (
  'GREEN',       -- 简单 - 适合健身新手
  'BLUE',        -- 中等 - 需要一定技巧
  'RED'          -- 困难 - 技术要求高
);

-- 时长计量方式枚举
CREATE TYPE "DurationType" AS ENUM (
  'TIME',  -- 按时间计量
  'REPS'   -- 按次数计量
);

-- 训练会话状态枚举
CREATE TYPE "SessionStatus" AS ENUM (
  'PENDING',      -- 待开始
  'IN_PROGRESS',  -- 进行中
  'COMPLETED',    -- 已完成
  'ABANDONED'     -- 已放弃
);

-- 稀有度等级枚举（v3.0 新增）
CREATE TYPE "RarityLevel" AS ENUM (
  'COMMON',      -- 常见 (>50%使用率)
  'UNCOMMON',    -- 不常见 (20-50%)
  'RARE',        -- 稀有 (5-20%)
  'EPIC',        -- 史诗 (1-5%)
  'LEGENDARY'    -- 传说 (<1%)
);

-- 数据来源枚举（v3.0 新增）
CREATE TYPE "DataSource" AS ENUM (
  'WEEKLY_TABLE',         -- 权威周表数据
  'ON_THE_FLY_ESTIMATE'   -- 即时估算
);

-- 深链目标类型枚举（v3.0 新增）
CREATE TYPE "DeeplinkTargetType" AS ENUM (
  'WORKOUT_SESSION',  -- 训练会话
  'THEME_WEEK',       -- 主题周
  'SHARE_CARD',       -- 分享卡片
  'EXERCISE'          -- 单个动作
);

-- ============================================================================
-- 2. CREATE TABLES (创建表)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 2.1 Scenarios Table (场景表)
-- ----------------------------------------------------------------------------
CREATE TABLE "scenarios" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "noise_tolerance" "NoiseLevel",
    "space_requirement" "SpaceSize",
    "icon_url" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "scenarios_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "scenarios" ADD CONSTRAINT "scenarios_code_key" UNIQUE ("code");

CREATE INDEX "scenarios_code_idx" ON "scenarios"("code");
CREATE INDEX "scenarios_is_active_idx" ON "scenarios"("is_active");

-- ----------------------------------------------------------------------------
-- 2.2 Equipment Table (器材表)
-- ----------------------------------------------------------------------------
CREATE TABLE "equipment" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" "EquipmentCategory" NOT NULL,
    "recognizable" BOOLEAN NOT NULL DEFAULT false,
    "recognition_labels" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "recognition_confidence" DOUBLE PRECISION NOT NULL DEFAULT 0.85,
    "icon_url" TEXT NOT NULL,
    "image_url" TEXT,
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "equipment_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "equipment" ADD CONSTRAINT "equipment_code_key" UNIQUE ("code");

CREATE INDEX "equipment_code_idx" ON "equipment"("code");
CREATE INDEX "equipment_category_idx" ON "equipment"("category");
CREATE INDEX "equipment_recognizable_idx" ON "equipment"("recognizable");

-- ----------------------------------------------------------------------------
-- 2.3 Exercises Table (动作表)
-- ----------------------------------------------------------------------------
CREATE TABLE "exercises" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "primary_muscle" "PrimaryMuscle" NOT NULL,
    "secondary_muscles" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "intent_type" "IntentType" NOT NULL,
    "difficulty" "Difficulty" NOT NULL,
    "description" JSONB NOT NULL,
    "default_duration" INTEGER NOT NULL,
    "default_sets" INTEGER NOT NULL DEFAULT 1,
    "duration_type" "DurationType" NOT NULL,
    "demo_image_url" TEXT,
    "demo_video_url" TEXT,
    "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "exercises_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "exercises" ADD CONSTRAINT "exercises_code_key" UNIQUE ("code");

CREATE INDEX "exercises_code_idx" ON "exercises"("code");
CREATE INDEX "exercises_primary_muscle_difficulty_intent_type_idx" ON "exercises"("primary_muscle", "difficulty", "intent_type");
CREATE INDEX "exercises_is_active_idx" ON "exercises"("is_active");

-- ----------------------------------------------------------------------------
-- 2.4 Exercise-Scenario Junction Table (动作-场景关联表)
-- ----------------------------------------------------------------------------
CREATE TABLE "exercise_scenarios" (
    "exercise_id" TEXT NOT NULL,
    "scenario_id" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "exercise_scenarios_pkey" PRIMARY KEY ("exercise_id", "scenario_id")
);

CREATE INDEX "exercise_scenarios_scenario_id_idx" ON "exercise_scenarios"("scenario_id");

-- ----------------------------------------------------------------------------
-- 2.5 Exercise-Equipment Junction Table (动作-器材关联表)
-- ----------------------------------------------------------------------------
CREATE TABLE "exercise_equipment" (
    "exercise_id" TEXT NOT NULL,
    "equipment_id" TEXT NOT NULL,
    "is_required" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "exercise_equipment_pkey" PRIMARY KEY ("exercise_id", "equipment_id")
);

CREATE INDEX "exercise_equipment_equipment_id_idx" ON "exercise_equipment"("equipment_id");

-- ----------------------------------------------------------------------------
-- 2.6 Users Table (用户表)
-- ----------------------------------------------------------------------------
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "email" TEXT,
    "name" TEXT,
    "avatar_url" TEXT,
    "total_workouts" INTEGER NOT NULL DEFAULT 0,
    "total_duration_sec" INTEGER NOT NULL DEFAULT 0,
    "current_streak" INTEGER NOT NULL DEFAULT 0,
    "longest_streak" INTEGER NOT NULL DEFAULT 0,
    "preferred_intents" "IntentType"[] DEFAULT ARRAY[]::"IntentType"[],
    "preferred_difficulty" "Difficulty",
    "preferred_duration" INTEGER,
    "avoid_equipment" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "streak_reminder" BOOLEAN NOT NULL DEFAULT true,
    "theme_week_reminder" BOOLEAN NOT NULL DEFAULT true,
    "quiet_hours_start" TEXT,
    "quiet_hours_end" TEXT,
    "hide_real_photos" BOOLEAN NOT NULL DEFAULT true,
    "auto_blur_faces" BOOLEAN NOT NULL DEFAULT true,
    "allow_data_sync" BOOLEAN NOT NULL DEFAULT false,
    "language" TEXT NOT NULL DEFAULT 'zh',
    "theme" TEXT NOT NULL DEFAULT 'auto',
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "users" ADD CONSTRAINT "users_email_key" UNIQUE ("email");

CREATE INDEX "users_email_idx" ON "users"("email");

-- ----------------------------------------------------------------------------
-- 2.7 Workout Sessions Table (训练会话表)
-- ----------------------------------------------------------------------------
CREATE TABLE "workout_sessions" (
    "id" TEXT NOT NULL,
    "user_id" UUID NOT NULL,
    "intent_type" "IntentType" NOT NULL,
    "scenario_id" TEXT,
    "target_muscles" "PrimaryMuscle"[] DEFAULT ARRAY[]::"PrimaryMuscle"[],
    "total_duration" INTEGER NOT NULL,
    "difficulty" "Difficulty" NOT NULL,
    "is_silent" BOOLEAN NOT NULL DEFAULT false,
    "status" "SessionStatus" NOT NULL DEFAULT 'PENDING',
    "started_at" TIMESTAMPTZ(6),
    "completed_at" TIMESTAMPTZ(6),
    "actual_duration" INTEGER,
    "follow_mode" BOOLEAN NOT NULL DEFAULT false,
    "current_step" INTEGER NOT NULL DEFAULT 0,
    "pause_count" INTEGER NOT NULL DEFAULT 0,
    "skip_count" INTEGER NOT NULL DEFAULT 0,
    "is_offline" BOOLEAN NOT NULL DEFAULT false,
    "ambient_noise" "NoiseLevel",
    "used_space" "SpaceSize",
    "rating" INTEGER,
    "feedback" VARCHAR(500),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "workout_sessions_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "workout_sessions_user_id_completed_at_idx" ON "workout_sessions"("user_id", "completed_at" DESC);
CREATE INDEX "workout_sessions_status_idx" ON "workout_sessions"("status");

-- ----------------------------------------------------------------------------
-- 2.8 Session Exercises Table (会话动作关联表)
-- ----------------------------------------------------------------------------
CREATE TABLE "session_exercises" (
    "id" TEXT NOT NULL,
    "session_id" TEXT NOT NULL,
    "exercise_id" TEXT NOT NULL,
    "sequence_order" INTEGER NOT NULL,
    "duration" INTEGER NOT NULL,
    "sets" INTEGER NOT NULL DEFAULT 1,
    "is_completed" BOOLEAN NOT NULL DEFAULT false,
    "actual_duration" INTEGER,
    "started_at" TIMESTAMPTZ(6),
    "ended_at" TIMESTAMPTZ(6),
    "paused_times" INTEGER NOT NULL DEFAULT 0,
    "skip_reason" TEXT,
    "difficulty_felt" "Difficulty",
    "comfort_level" INTEGER,
    "effectiveness_rating" INTEGER,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "session_exercises_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "session_exercises" ADD CONSTRAINT "session_exercises_session_id_sequence_order_key" UNIQUE ("session_id", "sequence_order");

CREATE INDEX "session_exercises_session_id_idx" ON "session_exercises"("session_id");

-- ----------------------------------------------------------------------------
-- 2.9 Share Cards Table (分享成果卡表)
-- ----------------------------------------------------------------------------
CREATE TABLE "share_cards" (
    "id" TEXT NOT NULL,
    "user_id" UUID NOT NULL,
    "session_id" TEXT NOT NULL,
    "card_image_url" TEXT NOT NULL,
    "card_template" TEXT NOT NULL,
    "card_data" JSONB NOT NULL,
    "rarity" "RarityLevel" NOT NULL,
    "equipment_series" TEXT NOT NULL,
    "rarity_score" DOUBLE PRECISION NOT NULL,
    "data_source" "DataSource" NOT NULL DEFAULT 'WEEKLY_TABLE',
    "special_tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "city_edition" TEXT,
    "theme_week" TEXT,
    "share_text" VARCHAR(500),
    "is_public" BOOLEAN NOT NULL DEFAULT true,
    "share_count" INTEGER NOT NULL DEFAULT 0,
    "view_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "share_cards_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "share_cards" ADD CONSTRAINT "share_cards_session_id_key" UNIQUE ("session_id");

CREATE INDEX "share_cards_user_id_created_at_idx" ON "share_cards"("user_id", "created_at" DESC);
CREATE INDEX "share_cards_is_public_idx" ON "share_cards"("is_public");
CREATE INDEX "share_cards_rarity_idx" ON "share_cards"("rarity");

-- ----------------------------------------------------------------------------
-- 2.10 Daily Trainings Table (每日训练记录表)
-- ----------------------------------------------------------------------------
CREATE TABLE "daily_trainings" (
    "id" TEXT NOT NULL,
    "user_id" UUID NOT NULL,
    "training_date" DATE NOT NULL,
    "total_sessions" INTEGER NOT NULL DEFAULT 0,
    "total_duration" INTEGER NOT NULL DEFAULT 0,
    "total_exercises" INTEGER NOT NULL DEFAULT 0,
    "completed_sessions" INTEGER NOT NULL DEFAULT 0,
    "intent_breakdown" JSONB,
    "muscle_breakdown" JSONB,
    "is_streak_day" BOOLEAN NOT NULL DEFAULT false,
    "achievements" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "daily_trainings_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "daily_trainings" ADD CONSTRAINT "daily_trainings_user_id_training_date_key" UNIQUE ("user_id", "training_date");

CREATE INDEX "daily_trainings_user_id_training_date_idx" ON "daily_trainings"("user_id", "training_date" DESC);
CREATE INDEX "daily_trainings_training_date_idx" ON "daily_trainings"("training_date");

-- ----------------------------------------------------------------------------
-- 2.11 Rarity Table (稀有度周表 - v3.0重命名优化)
-- ----------------------------------------------------------------------------
CREATE TABLE "rarity_table" (
    "id" TEXT NOT NULL,
    "equipment_id" TEXT NOT NULL,
    "equipment_code" TEXT NOT NULL,
    "week_start" DATE NOT NULL,
    "rarity_score" DOUBLE PRECISION NOT NULL,
    "rarity_level" "RarityLevel" NOT NULL,
    "data_source" "DataSource" NOT NULL DEFAULT 'WEEKLY_TABLE',
    "region" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "rarity_table_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "rarity_table" ADD CONSTRAINT "rarity_table_equipment_id_week_start_key" UNIQUE ("equipment_id", "week_start");
ALTER TABLE "rarity_table" ADD CONSTRAINT "rarity_table_equipment_code_week_start_key" UNIQUE ("equipment_code", "week_start");

CREATE INDEX "rarity_table_week_start_idx" ON "rarity_table"("week_start");
CREATE INDEX "rarity_table_rarity_level_week_start_idx" ON "rarity_table"("rarity_level", "week_start");

-- ----------------------------------------------------------------------------
-- 2.12 User Preferences Table (用户偏好学习记录表)
-- ----------------------------------------------------------------------------
CREATE TABLE "user_preferences" (
    "id" TEXT NOT NULL,
    "user_id" UUID NOT NULL,
    "preference_type" TEXT NOT NULL,
    "preference_key" TEXT NOT NULL,
    "preference_value" DOUBLE PRECISION NOT NULL,
    "usage_count" INTEGER NOT NULL DEFAULT 0,
    "success_rate" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "average_rating" DOUBLE PRECISION,
    "last_used_at" TIMESTAMPTZ(6),
    "first_used_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_preferences_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "user_preferences" ADD CONSTRAINT "user_preferences_user_id_preference_type_preference_key_key" UNIQUE ("user_id", "preference_type", "preference_key");

CREATE INDEX "user_preferences_user_id_preference_type_idx" ON "user_preferences"("user_id", "preference_type");
CREATE INDEX "user_preferences_preference_value_idx" ON "user_preferences"("preference_value" DESC);

-- ----------------------------------------------------------------------------
-- 2.13 Theme Weeks Table (主题周活动表)
-- ----------------------------------------------------------------------------
CREATE TABLE "theme_weeks" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "description" VARCHAR(500),
    "equipment_code" TEXT NOT NULL,
    "target_exercise_count" INTEGER NOT NULL DEFAULT 3,
    "start_date" DATE NOT NULL,
    "end_date" DATE NOT NULL,
    "reward_type" TEXT NOT NULL,
    "reward_data" JSONB,
    "status" TEXT NOT NULL DEFAULT 'UPCOMING',
    "is_visible" BOOLEAN NOT NULL DEFAULT true,
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "total_participants" INTEGER NOT NULL DEFAULT 0,
    "total_completions" INTEGER NOT NULL DEFAULT 0,
    "completion_rate" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "theme_weeks_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "theme_weeks" ADD CONSTRAINT "theme_weeks_code_key" UNIQUE ("code");

CREATE INDEX "theme_weeks_status_start_date_idx" ON "theme_weeks"("status", "start_date");
CREATE INDEX "theme_weeks_equipment_code_idx" ON "theme_weeks"("equipment_code");
CREATE INDEX "theme_weeks_display_order_idx" ON "theme_weeks"("display_order");

-- ----------------------------------------------------------------------------
-- 2.14 Theme Week Participations Table (主题周参与记录表)
-- ----------------------------------------------------------------------------
CREATE TABLE "theme_week_participations" (
    "id" TEXT NOT NULL,
    "user_id" UUID NOT NULL,
    "theme_week_id" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'JOINED',
    "joined_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "completed_at" TIMESTAMPTZ(6),
    "exercises_completed" INTEGER NOT NULL DEFAULT 0,
    "target_exercises" INTEGER NOT NULL,
    "progress_percent" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "reward_earned" BOOLEAN NOT NULL DEFAULT false,
    "reward_claimed_at" TIMESTAMPTZ(6),
    "related_sessions" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "theme_week_participations_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "theme_week_participations" ADD CONSTRAINT "theme_week_participations_user_id_theme_week_id_key" UNIQUE ("user_id", "theme_week_id");

CREATE INDEX "theme_week_participations_theme_week_id_status_idx" ON "theme_week_participations"("theme_week_id", "status");
CREATE INDEX "theme_week_participations_user_id_status_idx" ON "theme_week_participations"("user_id", "status");

-- ----------------------------------------------------------------------------
-- 2.15 Deeplinks Table (深链表 - v3.0新增)
-- ----------------------------------------------------------------------------
CREATE TABLE "deeplinks" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "target_type" "DeeplinkTargetType" NOT NULL,
    "target_id" TEXT NOT NULL,
    "created_by" UUID,
    "expires_at" TIMESTAMPTZ(6),
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "deeplinks_pkey" PRIMARY KEY ("id")
);

ALTER TABLE "deeplinks" ADD CONSTRAINT "deeplinks_code_key" UNIQUE ("code");

CREATE INDEX "deeplinks_code_idx" ON "deeplinks"("code");
CREATE INDEX "deeplinks_target_type_target_id_idx" ON "deeplinks"("target_type", "target_id");
CREATE INDEX "deeplinks_expires_at_idx" ON "deeplinks"("expires_at");

-- ----------------------------------------------------------------------------
-- 2.16 Deeplink Clicks Table (深链点击统计表 - v3.0新增)
-- ----------------------------------------------------------------------------
CREATE TABLE "deeplink_clicks" (
    "id" TEXT NOT NULL,
    "deeplink_id" TEXT NOT NULL,
    "clicked_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "ip_address" TEXT,
    "user_agent" TEXT,
    "referer" TEXT,

    CONSTRAINT "deeplink_clicks_pkey" PRIMARY KEY ("id")
);

CREATE INDEX "deeplink_clicks_deeplink_id_clicked_at_idx" ON "deeplink_clicks"("deeplink_id", "clicked_at" DESC);

-- ============================================================================
-- 3. ADD FOREIGN KEY CONSTRAINTS (添加外键约束)
-- ============================================================================

-- Exercise-Scenario relationships
ALTER TABLE "exercise_scenarios" ADD CONSTRAINT "exercise_scenarios_exercise_id_fkey" FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "exercise_scenarios" ADD CONSTRAINT "exercise_scenarios_scenario_id_fkey" FOREIGN KEY ("scenario_id") REFERENCES "scenarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Exercise-Equipment relationships
ALTER TABLE "exercise_equipment" ADD CONSTRAINT "exercise_equipment_exercise_id_fkey" FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "exercise_equipment" ADD CONSTRAINT "exercise_equipment_equipment_id_fkey" FOREIGN KEY ("equipment_id") REFERENCES "equipment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Workout Sessions relationships
ALTER TABLE "workout_sessions" ADD CONSTRAINT "workout_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "workout_sessions" ADD CONSTRAINT "workout_sessions_scenario_id_fkey" FOREIGN KEY ("scenario_id") REFERENCES "scenarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Session Exercises relationships
ALTER TABLE "session_exercises" ADD CONSTRAINT "session_exercises_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "workout_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "session_exercises" ADD CONSTRAINT "session_exercises_exercise_id_fkey" FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- Share Cards relationships
ALTER TABLE "share_cards" ADD CONSTRAINT "share_cards_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "share_cards" ADD CONSTRAINT "share_cards_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "workout_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Daily Trainings relationships
ALTER TABLE "daily_trainings" ADD CONSTRAINT "daily_trainings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Rarity Table relationships
ALTER TABLE "rarity_table" ADD CONSTRAINT "rarity_table_equipment_id_fkey" FOREIGN KEY ("equipment_id") REFERENCES "equipment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- User Preferences relationships
ALTER TABLE "user_preferences" ADD CONSTRAINT "user_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Theme Week Participations relationships
ALTER TABLE "theme_week_participations" ADD CONSTRAINT "theme_week_participations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "theme_week_participations" ADD CONSTRAINT "theme_week_participations_theme_week_id_fkey" FOREIGN KEY ("theme_week_id") REFERENCES "theme_weeks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Deeplink Clicks relationships (v3.0新增)
ALTER TABLE "deeplink_clicks" ADD CONSTRAINT "deeplink_clicks_deeplink_id_fkey" FOREIGN KEY ("deeplink_id") REFERENCES "deeplinks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- ============================================================================
-- 4. CREATE UPDATED_AT TRIGGER FUNCTION (创建自动更新时间戳触发器)
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================================================
-- 5. APPLY UPDATED_AT TRIGGERS TO ALL TABLES (为所有表添加触发器)
-- ============================================================================

CREATE TRIGGER update_scenarios_updated_at BEFORE UPDATE ON "scenarios" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_equipment_updated_at BEFORE UPDATE ON "equipment" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_exercises_updated_at BEFORE UPDATE ON "exercises" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON "users" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_workout_sessions_updated_at BEFORE UPDATE ON "workout_sessions" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_share_cards_updated_at BEFORE UPDATE ON "share_cards" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_daily_trainings_updated_at BEFORE UPDATE ON "daily_trainings" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_rarity_table_updated_at BEFORE UPDATE ON "rarity_table" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_user_preferences_updated_at BEFORE UPDATE ON "user_preferences" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_theme_weeks_updated_at BEFORE UPDATE ON "theme_weeks" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_theme_week_participations_updated_at BEFORE UPDATE ON "theme_week_participations" FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6. ENABLE ROW LEVEL SECURITY (RLS) (启用行级安全策略)
-- ============================================================================

ALTER TABLE "scenarios" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "equipment" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "exercises" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "exercise_scenarios" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "exercise_equipment" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "users" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "workout_sessions" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "session_exercises" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "share_cards" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "daily_trainings" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "rarity_table" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "user_preferences" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "theme_weeks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "theme_week_participations" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "deeplinks" ENABLE ROW LEVEL SECURITY;
ALTER TABLE "deeplink_clicks" ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 7. CREATE RLS POLICIES (创建行级安全策略)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 7.1 Public Read Access (公开数据可被所有人访问)
-- ----------------------------------------------------------------------------

CREATE POLICY "Public scenarios readable"
ON "scenarios" FOR SELECT TO anon, authenticated
USING (is_active = true);

CREATE POLICY "Public equipment readable"
ON "equipment" FOR SELECT TO anon, authenticated
USING (is_active = true);

CREATE POLICY "Public exercises readable"
ON "exercises" FOR SELECT TO anon, authenticated
USING (is_active = true);

CREATE POLICY "Public exercise_scenarios readable"
ON "exercise_scenarios" FOR SELECT TO anon, authenticated
USING (true);

CREATE POLICY "Public exercise_equipment readable"
ON "exercise_equipment" FOR SELECT TO anon, authenticated
USING (true);

CREATE POLICY "Public theme_weeks readable"
ON "theme_weeks" FOR SELECT TO anon, authenticated
USING (is_visible = true);

-- Rarity Table: 稀有度数据公开可读
CREATE POLICY "Public rarity_table readable"
ON "rarity_table" FOR SELECT TO anon, authenticated
USING (true);

-- ----------------------------------------------------------------------------
-- 7.2 Users Own Data Access (用户只能访问自己的数据)
-- ----------------------------------------------------------------------------

CREATE POLICY "Users can view own profile"
ON "users" FOR SELECT TO authenticated
USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
ON "users" FOR UPDATE TO authenticated
USING (auth.uid() = id);

-- ----------------------------------------------------------------------------
-- 7.3 Workout Sessions Access (训练会话权限)
-- ----------------------------------------------------------------------------

CREATE POLICY "Users can view own sessions"
ON "workout_sessions" FOR SELECT TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions"
ON "workout_sessions" FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions"
ON "workout_sessions" FOR UPDATE TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own sessions"
ON "workout_sessions" FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 7.4 Session Exercises Access (会话动作权限 - v3.0增强级联策略)
-- ----------------------------------------------------------------------------

-- 查询权限：通过 EXISTS 关联 workout_sessions.user_id
CREATE POLICY "Users can view own session_exercises"
ON "session_exercises" FOR SELECT TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM workout_sessions
        WHERE workout_sessions.id = session_exercises.session_id
          AND workout_sessions.user_id = auth.uid()
    )
);

-- 插入权限：只能为自己的会话插入动作
CREATE POLICY "Users can insert own session_exercises"
ON "session_exercises" FOR INSERT TO authenticated
WITH CHECK (
    EXISTS (
        SELECT 1 FROM workout_sessions
        WHERE workout_sessions.id = session_exercises.session_id
          AND workout_sessions.user_id = auth.uid()
    )
);

-- 更新权限：只能更新自己会话的动作
CREATE POLICY "Users can update own session_exercises"
ON "session_exercises" FOR UPDATE TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM workout_sessions
        WHERE workout_sessions.id = session_exercises.session_id
          AND workout_sessions.user_id = auth.uid()
    )
);

-- ----------------------------------------------------------------------------
-- 7.5 Share Cards Access (分享卡片权限 - v3.0完善可见性控制)
-- ----------------------------------------------------------------------------

-- 查询权限：公开卡片或自己的卡片
CREATE POLICY "Users can view own or public cards"
ON "share_cards" FOR SELECT TO authenticated
USING (auth.uid() = user_id OR is_public = true);

CREATE POLICY "Users can insert own cards"
ON "share_cards" FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own cards"
ON "share_cards" FOR UPDATE TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own cards"
ON "share_cards" FOR DELETE TO authenticated
USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 7.6 Daily Trainings Access (每日训练记录权限)
-- ----------------------------------------------------------------------------

CREATE POLICY "Users can view own daily_trainings"
ON "daily_trainings" FOR SELECT TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own daily_trainings"
ON "daily_trainings" FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own daily_trainings"
ON "daily_trainings" FOR UPDATE TO authenticated
USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 7.7 User Preferences Access (用户偏好权限)
-- ----------------------------------------------------------------------------

CREATE POLICY "Users can view own preferences"
ON "user_preferences" FOR SELECT TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own preferences"
ON "user_preferences" FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own preferences"
ON "user_preferences" FOR UPDATE TO authenticated
USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 7.8 Theme Week Participations Access (主题周参与权限)
-- ----------------------------------------------------------------------------

CREATE POLICY "Users can view own participations"
ON "theme_week_participations" FOR SELECT TO authenticated
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own participations"
ON "theme_week_participations" FOR INSERT TO authenticated
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own participations"
ON "theme_week_participations" FOR UPDATE TO authenticated
USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 7.9 Deeplinks Access (深链权限 - v3.0新增)
-- ----------------------------------------------------------------------------

-- 查询权限：公开读取有效的深链
CREATE POLICY "Public can read active deeplinks"
ON "deeplinks" FOR SELECT TO anon, authenticated
USING (expires_at IS NULL OR expires_at > NOW());

-- 插入权限：仅 service_role 可创建（Edge Function 使用）
-- 注意：此策略由应用层控制，通常使用 Service Key

-- ----------------------------------------------------------------------------
-- 7.10 Deeplink Clicks Access (深链点击统计权限 - v3.0新增)
-- ----------------------------------------------------------------------------

-- 插入权限：service_role 可写入（无需用户认证）
CREATE POLICY "Service can insert clicks"
ON "deeplink_clicks" FOR INSERT TO service_role
WITH CHECK (true);

-- 查询权限：仅管理员或数据分析角色可读（可选实现）
-- CREATE POLICY "Admin can read clicks"
-- ON "deeplink_clicks" FOR SELECT TO authenticated
-- USING (auth.jwt()->>'role' = 'admin');

-- ============================================================================
-- 8. ADD TABLE COMMENTS (添加表和列的注释)
-- ============================================================================

COMMENT ON TABLE "scenarios" IS '场景表 - 存储训练场景信息（如办公室、家、健身房等）';
COMMENT ON TABLE "equipment" IS '器材表 - 存储训练器材信息（如椅子、墙面、水瓶等）';
COMMENT ON TABLE "exercises" IS '动作表 - 存储所有训练动作的详细信息';
COMMENT ON TABLE "exercise_scenarios" IS '动作-场景关联表 - 多对多关系';
COMMENT ON TABLE "exercise_equipment" IS '动作-器材关联表 - 多对多关系';
COMMENT ON TABLE "users" IS '用户表 - 存储用户基本信息、统计数据和偏好设置';
COMMENT ON TABLE "workout_sessions" IS '训练会话表 - 记录每次训练的完整信息';
COMMENT ON TABLE "session_exercises" IS '会话动作关联表 - 记录训练会话中的具体动作（v3.0增强RLS级联策略）';
COMMENT ON TABLE "share_cards" IS '分享成果卡表 - 用户完成训练后生成的分享卡片（v3.0改用枚举类型）';
COMMENT ON TABLE "daily_trainings" IS '每日训练记录表 - 按日期聚合的训练数据，用于日历视图';
COMMENT ON TABLE "rarity_table" IS '稀有度周表 - 用于动态计算稀有度（v3.0重命名自equipment_frequencies）';
COMMENT ON TABLE "user_preferences" IS '用户偏好学习记录表 - 用于个性化推荐和智能学习';
COMMENT ON TABLE "theme_weeks" IS '主题周活动表 - 管理主题周活动（如椅子周、水瓶周）';
COMMENT ON TABLE "theme_week_participations" IS '主题周参与记录表 - 记录用户参与主题周的详细数据';
COMMENT ON TABLE "deeplinks" IS '深链表 - 用于分享和跳转链接（v3.0新增）';
COMMENT ON TABLE "deeplink_clicks" IS '深链点击统计表 - 无需用户认证的统计数据（v3.0新增）';

-- ============================================================================
-- MIGRATION COMPLETED - 迁移完成
-- ============================================================================
--
-- ✅ 数据库架构版本: v3.0 Production Ready
-- ✅ 基于改进建议全面重构
--
-- 统计数据:
-- - Total Tables Created: 16 (新增2个：deeplinks, deeplink_clicks)
-- - Total Enums Created: 11 (新增3个：RarityLevel, DataSource, DeeplinkTargetType)
-- - Total Indexes Created: 40+
-- - Total Foreign Keys: 14
-- - Total Triggers: 11
-- - RLS Policies: Enabled for all tables with ~30 policies
--
-- v3.0 主要改进:
-- 1. ✅ 统一命名规范（资源型 vs 计算型接口）
-- 2. ✅ 新增深链统计表（deeplinks, deeplink_clicks）
-- 3. ✅ 重命名 equipment_frequencies → rarity_table
-- 4. ✅ 新增数据来源枚举（DataSource）
-- 5. ✅ 新增稀有度枚举（RarityLevel）
-- 6. ✅ 难度改为颜色编码（GREEN, BLUE, RED）
-- 7. ✅ 完善 RLS 级联策略（session_exercises 通过 EXISTS 关联）
-- 8. ✅ 所有枚举统一为 UPPER_SNAKE_CASE
--
-- 下一步操作:
-- 1. 在 Supabase SQL Editor 中运行此脚本
--    URL: https://app.supabase.com/project/tvjcmleckqovnieuexgu/sql
-- 2. 验证所有 16 张表创建成功
-- 3. 更新 Prisma 配置：将 schema.prisma 替换为 schema_v3.prisma
-- 4. 运行 npx prisma generate 生成 Prisma Client
-- 5. 创建种子数据 (scenarios, equipment, exercises)
-- 6. 测试 Supabase Auth 集成和 RLS 策略
-- 7. 配置 Supabase Storage bucket (share-cards)
-- 8. 部署 Edge Functions（深链创建和点击统计）
--
-- ============================================================================


-- 1) share_cards 增加 personal_stars（修复当前报错）
ALTER TABLE public.share_cards
  ADD COLUMN IF NOT EXISTS personal_stars smallint NOT NULL DEFAULT 1;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conname = 'share_cards_personal_stars_chk'
  ) THEN
    ALTER TABLE public.share_cards
      ADD CONSTRAINT share_cards_personal_stars_chk
      CHECK (personal_stars BETWEEN 1 AND 5);
  END IF;
END$$;

-- 索引（与 Prisma 模型里的 @@index 对齐，建议）
CREATE INDEX IF NOT EXISTS share_cards_personal_stars_idx ON public.share_cards (personal_stars);
CREATE INDEX IF NOT EXISTS share_cards_rarity_personal_stars_idx ON public.share_cards (rarity, personal_stars);

-- 2) 扩展 RarityLevel 到 9 档（若当前只有 5 档，以下将顺序插入缺失值）
-- Postgres 12+ 支持 IF NOT EXISTS；若已存在会跳过
DO $$
BEGIN
  -- 在 UNCOMMON 之后加入 FINE
  BEGIN
    ALTER TYPE "RarityLevel" ADD VALUE IF NOT EXISTS 'FINE' AFTER 'UNCOMMON';
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- 在 RARE 之后加入 ELITE
  BEGIN
    ALTER TYPE "RarityLevel" ADD VALUE IF NOT EXISTS 'ELITE' AFTER 'RARE';
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- 在 EPIC 之后加入 MYTHIC
  BEGIN
    ALTER TYPE "RarityLevel" ADD VALUE IF NOT EXISTS 'MYTHIC' AFTER 'EPIC';
  EXCEPTION WHEN duplicate_object THEN NULL; END;

  -- 在 LEGENDARY 之后加入 APEX
  BEGIN
    ALTER TYPE "RarityLevel" ADD VALUE IF NOT EXISTS 'APEX' AFTER 'LEGENDARY';
  EXCEPTION WHEN duplicate_object THEN NULL; END;
END$$;

-- 3) 若缺少 scenario_equipment 则创建（与你的种子保持一致）
CREATE TABLE IF NOT EXISTS public.scenario_equipment (
  scenario_id text NOT NULL,
  equipment_id text NOT NULL,
  is_common boolean NOT NULL DEFAULT true,
  created_at timestamptz(6) NOT NULL DEFAULT now(),
  CONSTRAINT scenario_equipment_pkey PRIMARY KEY (scenario_id, equipment_id),
  CONSTRAINT scenario_equipment_scenario_id_fkey
    FOREIGN KEY (scenario_id) REFERENCES public.scenarios(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT scenario_equipment_equipment_id_fkey
    FOREIGN KEY (equipment_id) REFERENCES public.equipment(id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- 可选：RLS 与只读策略（与 v3.0 其他公共表风格一致）
ALTER TABLE public.scenario_equipment ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'scenario_equipment'
      AND policyname = 'Public scenario_equipment readable'
  ) THEN
    CREATE POLICY "Public scenario_equipment readable"
    ON public.scenario_equipment FOR SELECT
    TO anon, authenticated
    USING (true);
  END IF;
END$$;

-- 4) （可选）把 share_text/description 严格收敛到 500 长度，和 v3.0 保持一致
-- 若你的系统不会存特别长的文本，建议做；否则可跳过
ALTER TABLE public.share_cards ALTER COLUMN share_text TYPE varchar(500);
ALTER TABLE public.theme_weeks ALTER COLUMN description TYPE varchar(500);

-- ============================================================================
-- 5. CHALLENGE SYSTEM - 挑战系统表 (v3.1 - Simplified Design)
-- ============================================================================

-- 挑战状态枚举（兼容写法）
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'ChallengeStatus') THEN
    CREATE TYPE "ChallengeStatus" AS ENUM (
      'STARTED',     -- 已开始 - 用户已接受挑战但尚未完成
      'IN_PROGRESS', -- 进行中 - 正在进行挑战
      'COMPLETED',   -- 已完成 - 成功完成挑战
      'ABANDONED'    -- 已放弃 - 中途退出或取消挑战
    );
  END IF;
END$$;

-- 5.1) 创建挑战表（简化设计）
CREATE TABLE IF NOT EXISTS public.challenge_items (
  id text NOT NULL DEFAULT gen_random_uuid()::text,
  code text NOT NULL,
  title text NOT NULL,

  -- 关联器材信息
  equipment_id text NOT NULL,

  -- 挑战配置
  time_limit integer,  -- 时间限制（分钟数，null表示无限制）
  target_count integer NOT NULL DEFAULT 3,  -- 目标完成次数

  -- 描述和说明
  description varchar(500) NOT NULL,
  instructions varchar(1000),

  -- 热度和推荐
  is_popular boolean DEFAULT false,
  trending_score double precision DEFAULT 0.0,

  -- 状态管理
  is_active boolean NOT NULL DEFAULT true,
  display_order integer NOT NULL DEFAULT 0,

  -- 元数据
  created_at timestamptz(6) NOT NULL DEFAULT now(),
  updated_at timestamptz(6) NOT NULL DEFAULT now(),

  CONSTRAINT challenge_items_pkey PRIMARY KEY (id),
  CONSTRAINT challenge_items_code_key UNIQUE (code),
  CONSTRAINT challenge_items_equipment_id_fkey
    FOREIGN KEY (equipment_id) REFERENCES public.equipment(id)
    ON DELETE RESTRICT ON UPDATE CASCADE
);

-- 5.2) 创建挑战完成记录表（简化设计）
CREATE TABLE IF NOT EXISTS public.challenge_completions (
  id text NOT NULL DEFAULT gen_random_uuid()::text,

  -- 关联信息
  user_id uuid NOT NULL,  -- 修改为 uuid 类型以匹配 users 表
  challenge_item_id text NOT NULL,
  workout_session_id text,  -- 关联训练会话（可选）

  -- 挑战状态
  status "ChallengeStatus" NOT NULL DEFAULT 'STARTED',
  started_at timestamptz(6) NOT NULL DEFAULT now(),
  completed_at timestamptz(6),
  abandoned_at timestamptz(6),

  -- 完成详情
  actual_duration integer,  -- 实际完成时长（秒数）
  completed_count integer NOT NULL DEFAULT 0,  -- 完成次数
  progress_percent double precision NOT NULL DEFAULT 0.0,  -- 完成百分比

  -- 用户反馈和评价
  difficulty_felt integer,  -- 实际感受难度（1-5分）
  enjoyment_rating integer,  -- 享受度评分（1-5分）
  feedback varchar(500),  -- 用户反馈

  -- 奖励系统
  badge_earned "RarityLevel",  -- 获得徽章稀有度
  xp_earned integer NOT NULL DEFAULT 0,  -- 获得经验值
  bonus_rewards jsonb,  -- 额外奖励

  -- 元数据
  created_at timestamptz(6) NOT NULL DEFAULT now(),
  updated_at timestamptz(6) NOT NULL DEFAULT now(),

  CONSTRAINT challenge_completions_pkey PRIMARY KEY (id),
  CONSTRAINT challenge_completions_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT challenge_completions_challenge_item_id_fkey
    FOREIGN KEY (challenge_item_id) REFERENCES public.challenge_items(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT challenge_completions_workout_session_id_fkey
    FOREIGN KEY (workout_session_id) REFERENCES public.workout_sessions(id)
    ON DELETE SET NULL ON UPDATE CASCADE
);

-- 5.3) 创建索引优化查询性能
CREATE INDEX IF NOT EXISTS idx_challenge_items_code ON public.challenge_items(code);
CREATE INDEX IF NOT EXISTS idx_challenge_items_equipment_id ON public.challenge_items(equipment_id);
CREATE INDEX IF NOT EXISTS idx_challenge_items_is_active_display_order ON public.challenge_items(is_active, display_order);
CREATE INDEX IF NOT EXISTS idx_challenge_items_trending_score_desc ON public.challenge_items(trending_score DESC);

CREATE INDEX IF NOT EXISTS idx_challenge_completions_user_id_status ON public.challenge_completions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_challenge_completions_challenge_item_id_status ON public.challenge_completions(challenge_item_id, status);
CREATE INDEX IF NOT EXISTS idx_challenge_completions_user_id_completed_at_desc ON public.challenge_completions(user_id, completed_at DESC);
CREATE INDEX IF NOT EXISTS idx_challenge_completions_status_started_at ON public.challenge_completions(status, started_at);

-- 5.4) 添加自动更新时间戳触发器
CREATE TRIGGER update_challenge_items_updated_at BEFORE UPDATE ON public.challenge_items FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_challenge_completions_updated_at BEFORE UPDATE ON public.challenge_completions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 5.5) 启用 RLS 安全策略
ALTER TABLE public.challenge_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.challenge_completions ENABLE ROW LEVEL SECURITY;

-- 5.6) 创建 RLS 策略
DO $$
BEGIN
  -- 挑战表 - 公共只读（仅启用的挑战）
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'challenge_items'
      AND policyname = 'Public challenge_items readable'
  ) THEN
    CREATE POLICY "Public challenge_items readable"
    ON public.challenge_items FOR SELECT
    TO anon, authenticated
    USING (is_active = true);
  END IF;

  -- 挑战完成记录表 - 用户只能查看自己的记录
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'challenge_completions'
      AND policyname = 'Users can view own challenge completions'
  ) THEN
    CREATE POLICY "Users can view own challenge completions"
    ON public.challenge_completions FOR SELECT
    TO authenticated
    USING (auth.uid() = user_id);
  END IF;

  -- 用户可以插入自己的挑战完成记录
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'challenge_completions'
      AND policyname = 'Users can insert own challenge completions'
  ) THEN
    CREATE POLICY "Users can insert own challenge completions"
    ON public.challenge_completions FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);
  END IF;

  -- 用户可以更新自己的挑战完成记录
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename = 'challenge_completions'
      AND policyname = 'Users can update own challenge completions'
  ) THEN
    CREATE POLICY "Users can update own challenge completions"
    ON public.challenge_completions FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id);
  END IF;
END$$;

-- 5.7) 添加表注释
COMMENT ON TABLE public.challenge_items IS '挑战表 - 存储挑战信息，专注于挑战本身而非统计数据（简化设计）';
COMMENT ON TABLE public.challenge_completions IS '挑战完成记录表 - 记录用户挑战的参与、进度和完成状态';

COMMENT ON COLUMN public.challenge_items.code IS '业务标识符，如：umbrella_challenge, book_challenge';
COMMENT ON COLUMN public.challenge_items.title IS '挑战标题，如：Umbrella Fitness Challenge, Book Balance Challenge';
COMMENT ON COLUMN public.challenge_items.equipment_id IS '关联器材ID，从equipment表获取物品属性';
COMMENT ON COLUMN public.challenge_items.time_limit IS '时间限制（分钟数，null表示无限制）';
COMMENT ON COLUMN public.challenge_items.target_count IS '目标完成次数（需要完成的练习动作数量）';
COMMENT ON COLUMN public.challenge_items.description IS '挑战描述';
COMMENT ON COLUMN public.challenge_items.instructions IS '详细说明（可选，挑战的具体要求）';
COMMENT ON COLUMN public.challenge_items.trending_score IS '趋势分数（用于排序推荐）';

COMMENT ON COLUMN public.challenge_completions.user_id IS '用户ID';
COMMENT ON COLUMN public.challenge_completions.challenge_item_id IS '挑战ID';
COMMENT ON COLUMN public.challenge_completions.workout_session_id IS '关联训练会话ID（可选）';
COMMENT ON COLUMN public.challenge_completions.status IS '挑战状态：STARTED, IN_PROGRESS, COMPLETED, ABANDONED';
COMMENT ON COLUMN public.challenge_completions.actual_duration IS '实际完成时长（秒数）';
COMMENT ON COLUMN public.challenge_completions.completed_count IS '完成次数（完成的练习动作数量）';
COMMENT ON COLUMN public.challenge_completions.progress_percent IS '完成百分比（0.0-1.0）';
COMMENT ON COLUMN public.challenge_completions.difficulty_felt IS '实际感受难度（1-5分，用户主观感受）';
COMMENT ON COLUMN public.challenge_completions.enjoyment_rating IS '享受度评分（1-5分，挑战趣味性）';
COMMENT ON COLUMN public.challenge_completions.badge_earned IS '获得徽章稀有度（使用现有枚举）';
COMMENT ON COLUMN public.challenge_completions.xp_earned IS '获得经验值（基于难度和完成质量）';
COMMENT ON COLUMN public.challenge_completions.bonus_rewards IS '额外奖励（JSON格式，特殊成就等）';

-- ============================================================================
-- SUBSCRIPTION SYSTEM IMPLEMENTATION - v3.2 (2024-11-20)
-- ============================================================================
--
-- Implementation for SnapRep Premium Subscription System
-- Features:
-- - Google Play Billing integration
-- - Free trial management (7 days)
-- - Daily exercise limits (3 per day for free users)
-- - Subscription status tracking
-- - Payment transaction history
--
-- Pricing Strategy:
-- - Monthly: $4.99 USD
-- - Yearly: $29.99 USD (50% savings)
-- - Free tier: 3 exercises per day + 7-day trial
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. ADD SUBSCRIPTION ENUMS
-- ----------------------------------------------------------------------------

-- Subscription tier levels
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'SubscriptionTier') THEN
    CREATE TYPE "SubscriptionTier" AS ENUM (
      'FREE',            -- Free version (default)
      'PREMIUM',         -- Premium monthly subscription
      'PREMIUM_YEARLY'   -- Premium yearly subscription (discounted)
    );
  END IF;
END$$;

-- Subscription status states
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'SubscriptionStatus') THEN
    CREATE TYPE "SubscriptionStatus" AS ENUM (
      'ACTIVE',      -- Active subscription
      'PAST_DUE',    -- Payment failed, grace period
      'CANCELED',    -- Canceled but active until end date
      'UNPAID',      -- Payment failed, subscription suspended
      'EXPIRED'      -- Subscription has expired
    );
  END IF;
END$$;

-- Payment platform types
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'PaymentPlatform') THEN
    CREATE TYPE "PaymentPlatform" AS ENUM (
      'GOOGLE_PLAY',   -- Google Play Store
      'APPLE_STORE',   -- Apple App Store (future)
      'STRIPE'         -- Stripe (future)
    );
  END IF;
END$$;

-- ----------------------------------------------------------------------------
-- 2. MODIFY EXISTING USERS TABLE
-- ----------------------------------------------------------------------------

-- Add subscription-related fields to users table for quick queries
ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS subscription_tier "SubscriptionTier" NOT NULL DEFAULT 'FREE',
  ADD COLUMN IF NOT EXISTS subscription_status "SubscriptionStatus" NOT NULL DEFAULT 'ACTIVE',
  ADD COLUMN IF NOT EXISTS premium_expires_at timestamptz(6),
  ADD COLUMN IF NOT EXISTS free_trial_used boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS trial_started_at timestamptz(6);

-- Add indexes for subscription queries
CREATE INDEX IF NOT EXISTS idx_users_subscription_tier ON public.users(subscription_tier);
CREATE INDEX IF NOT EXISTS idx_users_subscription_status ON public.users(subscription_status);
CREATE INDEX IF NOT EXISTS idx_users_premium_expires_at ON public.users(premium_expires_at);
CREATE INDEX IF NOT EXISTS idx_users_trial_started_at ON public.users(trial_started_at);

-- Add comments for new fields
COMMENT ON COLUMN public.users.subscription_tier IS 'Current subscription tier (cached from subscriptions table)';
COMMENT ON COLUMN public.users.subscription_status IS 'Current subscription status (cached from subscriptions table)';
COMMENT ON COLUMN public.users.premium_expires_at IS 'When premium subscription expires (null for lifetime)';
COMMENT ON COLUMN public.users.free_trial_used IS 'Whether user has used their free trial';
COMMENT ON COLUMN public.users.trial_started_at IS 'When user started their free trial';

-- ----------------------------------------------------------------------------
-- 3. CREATE SUBSCRIPTIONS TABLE
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.subscriptions (
  id text NOT NULL DEFAULT gen_random_uuid()::text,
  user_id uuid NOT NULL,

  -- Subscription configuration
  tier "SubscriptionTier" NOT NULL DEFAULT 'FREE',
  status "SubscriptionStatus" NOT NULL DEFAULT 'ACTIVE',
  payment_platform "PaymentPlatform",

  -- Google Play related fields
  product_id text,           -- Google Play product ID (snaprep_premium)
  purchase_token text,       -- Google Play purchase token (for verification)
  order_id text,            -- Google Play order ID

  -- Subscription cycle
  start_date timestamptz(6) NOT NULL,
  end_date timestamptz(6),   -- null means unlimited/lifetime
  renews_at timestamptz(6),  -- Next renewal time

  -- Trial configuration
  trial_start_date timestamptz(6),
  trial_end_date timestamptz(6),
  is_trial_used boolean NOT NULL DEFAULT false,

  -- Price information (record actual payment for price lock support)
  currency text NOT NULL DEFAULT 'USD',
  original_price decimal(10,2) NOT NULL,  -- Original price
  actual_price decimal(10,2) NOT NULL,    -- Actual payment (with discounts)

  -- Cancellation related
  canceled_at timestamptz(6),
  cancel_reason text,
  will_renew boolean NOT NULL DEFAULT true,

  -- Verification and security
  last_verified_at timestamptz(6),
  verification_data jsonb,  -- Store Google Play receipt data

  -- Metadata
  created_at timestamptz(6) NOT NULL DEFAULT now(),
  updated_at timestamptz(6) NOT NULL DEFAULT now(),

  CONSTRAINT subscriptions_pkey PRIMARY KEY (id),
  CONSTRAINT subscriptions_user_id_key UNIQUE (user_id),  -- One subscription per user
  CONSTRAINT subscriptions_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- Indexes for subscription queries
CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id_status ON public.subscriptions(user_id, status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status_end_date ON public.subscriptions(status, end_date);
CREATE INDEX IF NOT EXISTS idx_subscriptions_payment_platform_status ON public.subscriptions(payment_platform, status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_purchase_token ON public.subscriptions(purchase_token);
CREATE INDEX IF NOT EXISTS idx_subscriptions_renews_at ON public.subscriptions(renews_at);

-- Add trigger for updated_at
CREATE TRIGGER update_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS policies for subscriptions
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'subscriptions'
    AND policyname = 'Users can view own subscription'
  ) THEN
    CREATE POLICY "Users can view own subscription"
    ON public.subscriptions FOR SELECT TO authenticated
    USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'subscriptions'
    AND policyname = 'Users can update own subscription'
  ) THEN
    CREATE POLICY "Users can update own subscription"
    ON public.subscriptions FOR UPDATE TO authenticated
    USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'subscriptions'
    AND policyname = 'Users can insert own subscription'
  ) THEN
    CREATE POLICY "Users can insert own subscription"
    ON public.subscriptions FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);
  END IF;
END$$;

-- ----------------------------------------------------------------------------
-- 4. CREATE PAYMENT TRANSACTIONS TABLE
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.payment_transactions (
  id text NOT NULL DEFAULT gen_random_uuid()::text,
  subscription_id text NOT NULL,
  user_id uuid NOT NULL,

  -- Transaction details
  platform "PaymentPlatform" NOT NULL,
  transaction_id text NOT NULL,        -- Platform's transaction ID
  purchase_token text,                 -- Google Play purchase token
  receipt_data jsonb,                  -- Full receipt/verification data

  -- Payment information
  amount decimal(10,2) NOT NULL,
  currency text NOT NULL DEFAULT 'USD',
  product_id text NOT NULL,            -- snaprep_premium

  -- Transaction status
  status text NOT NULL DEFAULT 'PENDING',  -- PENDING, SUCCESS, FAILED, REFUNDED
  processed_at timestamptz(6),

  -- Verification
  verified_at timestamptz(6),
  verification_attempts integer NOT NULL DEFAULT 0,
  last_error text,

  -- Metadata
  created_at timestamptz(6) NOT NULL DEFAULT now(),
  updated_at timestamptz(6) NOT NULL DEFAULT now(),

  CONSTRAINT payment_transactions_pkey PRIMARY KEY (id),
  CONSTRAINT payment_transactions_subscription_id_fkey
    FOREIGN KEY (subscription_id) REFERENCES public.subscriptions(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT payment_transactions_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id)
    ON DELETE CASCADE ON UPDATE CASCADE
);

-- Indexes for payment transaction queries
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_id ON public.payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_subscription_id ON public.payment_transactions(subscription_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_transaction_id ON public.payment_transactions(transaction_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status_created_at ON public.payment_transactions(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_platform_status ON public.payment_transactions(platform, status);

-- Add trigger for updated_at
CREATE TRIGGER update_payment_transactions_updated_at
  BEFORE UPDATE ON public.payment_transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS policies for payment transactions
ALTER TABLE public.payment_transactions ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'payment_transactions'
    AND policyname = 'Users can view own transactions'
  ) THEN
    CREATE POLICY "Users can view own transactions"
    ON public.payment_transactions FOR SELECT TO authenticated
    USING (auth.uid() = user_id);
  END IF;
END$$;

-- ----------------------------------------------------------------------------
-- 5. CREATE DAILY USAGE TABLE (Exercise Limits)
-- ----------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.daily_usage (
  id text NOT NULL DEFAULT gen_random_uuid()::text,
  user_id uuid NOT NULL,

  -- Usage tracking
  usage_date date NOT NULL,             -- Local date (YYYY-MM-DD)
  exercise_count integer NOT NULL DEFAULT 0,  -- Daily exercise count
  reset_at timestamptz(6) NOT NULL,     -- When counter resets (midnight local time)

  -- Metadata
  created_at timestamptz(6) NOT NULL DEFAULT now(),
  updated_at timestamptz(6) NOT NULL DEFAULT now(),

  CONSTRAINT daily_usage_pkey PRIMARY KEY (id),
  CONSTRAINT daily_usage_user_id_date_key UNIQUE (user_id, usage_date),
  CONSTRAINT daily_usage_user_id_fkey
    FOREIGN KEY (user_id) REFERENCES public.users(id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT daily_usage_exercise_count_check CHECK (exercise_count >= 0)
);

-- Indexes for daily usage queries
CREATE INDEX IF NOT EXISTS idx_daily_usage_user_id_date ON public.daily_usage(user_id, usage_date DESC);
CREATE INDEX IF NOT EXISTS idx_daily_usage_usage_date ON public.daily_usage(usage_date);
CREATE INDEX IF NOT EXISTS idx_daily_usage_reset_at ON public.daily_usage(reset_at);

-- Add trigger for updated_at
CREATE TRIGGER update_daily_usage_updated_at
  BEFORE UPDATE ON public.daily_usage
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS policies for daily usage
ALTER TABLE public.daily_usage ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'daily_usage'
    AND policyname = 'Users can view own daily usage'
  ) THEN
    CREATE POLICY "Users can view own daily usage"
    ON public.daily_usage FOR SELECT TO authenticated
    USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'daily_usage'
    AND policyname = 'Users can update own daily usage'
  ) THEN
    CREATE POLICY "Users can update own daily usage"
    ON public.daily_usage FOR UPDATE TO authenticated
    USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'public' AND tablename = 'daily_usage'
    AND policyname = 'Users can insert own daily usage'
  ) THEN
    CREATE POLICY "Users can insert own daily usage"
    ON public.daily_usage FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);
  END IF;
END$$;

-- ----------------------------------------------------------------------------
-- 6. ADD TABLE COMMENTS
-- ----------------------------------------------------------------------------

COMMENT ON TABLE public.subscriptions IS 'Subscription management table - tracks user subscription status, billing, and trial periods';
COMMENT ON TABLE public.payment_transactions IS 'Payment transaction history - records all subscription purchases and verification data';
COMMENT ON TABLE public.daily_usage IS 'Daily exercise usage tracking - enforces 3 exercise/day limit for free users';

-- Column comments for subscriptions table
COMMENT ON COLUMN public.subscriptions.tier IS 'Subscription tier level';
COMMENT ON COLUMN public.subscriptions.status IS 'Current subscription status';
COMMENT ON COLUMN public.subscriptions.payment_platform IS 'Payment platform used (Google Play, Apple Store, etc.)';
COMMENT ON COLUMN public.subscriptions.product_id IS 'Platform product identifier (snaprep_premium)';
COMMENT ON COLUMN public.subscriptions.purchase_token IS 'Platform purchase token for verification';
COMMENT ON COLUMN public.subscriptions.order_id IS 'Platform order identifier';
COMMENT ON COLUMN public.subscriptions.trial_start_date IS 'When free trial started';
COMMENT ON COLUMN public.subscriptions.trial_end_date IS 'When free trial ends';
COMMENT ON COLUMN public.subscriptions.verification_data IS 'Platform receipt/verification data (encrypted)';

-- Column comments for payment transactions table
COMMENT ON COLUMN public.payment_transactions.transaction_id IS 'Platform transaction identifier';
COMMENT ON COLUMN public.payment_transactions.receipt_data IS 'Full platform receipt data for verification';
COMMENT ON COLUMN public.payment_transactions.status IS 'Transaction status: PENDING, SUCCESS, FAILED, REFUNDED';
COMMENT ON COLUMN public.payment_transactions.verification_attempts IS 'Number of verification attempts';

-- Column comments for daily usage table
COMMENT ON COLUMN public.daily_usage.usage_date IS 'Local date for usage tracking (timezone-aware)';
COMMENT ON COLUMN public.daily_usage.exercise_count IS 'Number of exercises completed today';
COMMENT ON COLUMN public.daily_usage.reset_at IS 'When daily counter resets (midnight user local time)';

-- ----------------------------------------------------------------------------
-- 7. CREATE HELPER FUNCTIONS
-- ----------------------------------------------------------------------------

-- Function to check if user has premium access
CREATE OR REPLACE FUNCTION public.has_premium_access(user_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  user_tier "SubscriptionTier";
  user_status "SubscriptionStatus";
  expires_at timestamptz;
  trial_end timestamptz;
  trial_used boolean;
BEGIN
  -- Get user subscription info
  SELECT
    subscription_tier,
    subscription_status,
    premium_expires_at,
    trial_started_at + INTERVAL '7 days' as trial_end_calculated,
    free_trial_used
  INTO
    user_tier,
    user_status,
    expires_at,
    trial_end,
    trial_used
  FROM public.users
  WHERE id = user_uuid;

  -- If no user found, no access
  IF NOT FOUND THEN
    RETURN false;
  END IF;

  -- Premium subscribers have access
  IF user_tier IN ('PREMIUM', 'PREMIUM_YEARLY') AND user_status = 'ACTIVE' THEN
    -- Check if not expired
    IF expires_at IS NULL OR expires_at > NOW() THEN
      RETURN true;
    END IF;
  END IF;

  -- Check trial access
  IF NOT trial_used AND trial_end IS NOT NULL AND NOW() <= trial_end THEN
    RETURN true;
  END IF;

  RETURN false;
END;
$$;

-- Function to check daily exercise limit
CREATE OR REPLACE FUNCTION public.can_start_exercise(user_uuid uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  has_premium boolean;
  today_count integer;
  today_date date;
BEGIN
  -- Premium users have unlimited access
  SELECT public.has_premium_access(user_uuid) INTO has_premium;
  IF has_premium THEN
    RETURN true;
  END IF;

  -- Check daily limit for free users
  today_date := CURRENT_DATE;

  SELECT COALESCE(exercise_count, 0)
  INTO today_count
  FROM public.daily_usage
  WHERE user_id = user_uuid AND usage_date = today_date;

  -- Free users limited to 3 exercises per day
  RETURN COALESCE(today_count, 0) < 3;
END;
$$;

-- Function to increment daily exercise count
CREATE OR REPLACE FUNCTION public.increment_daily_usage(user_uuid uuid, user_timezone text DEFAULT 'UTC')
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  today_date date;
  reset_time timestamptz;
BEGIN
  -- Calculate today's date in user's timezone
  today_date := (NOW() AT TIME ZONE user_timezone)::date;

  -- Calculate next reset time (midnight in user timezone)
  reset_time := (today_date + 1) AT TIME ZONE user_timezone AT TIME ZONE 'UTC';

  -- Insert or update daily usage
  INSERT INTO public.daily_usage (user_id, usage_date, exercise_count, reset_at)
  VALUES (user_uuid, today_date, 1, reset_time)
  ON CONFLICT (user_id, usage_date)
  DO UPDATE SET
    exercise_count = daily_usage.exercise_count + 1,
    updated_at = NOW();

  RETURN true;
END;
$$;

-- ----------------------------------------------------------------------------
-- 8. INITIAL DATA SETUP
-- ----------------------------------------------------------------------------

-- Update existing users to have proper subscription defaults
UPDATE public.users
SET
  subscription_tier = 'FREE',
  subscription_status = 'ACTIVE'
WHERE
  subscription_tier IS NULL
  OR subscription_status IS NULL;

-- ============================================================================
-- SUBSCRIPTION SYSTEM MIGRATION COMPLETED - v3.2
-- ============================================================================
--
-- ✅ Added 3 new enums: SubscriptionTier, SubscriptionStatus, PaymentPlatform
-- ✅ Modified users table with subscription fields and indexes
-- ✅ Created subscriptions table with Google Play integration
-- ✅ Created payment_transactions table for billing history
-- ✅ Created daily_usage table for exercise limit tracking
-- ✅ Added RLS policies for all new tables
-- ✅ Created helper functions for subscription and usage checks
-- ✅ Added comprehensive indexing for performance
--
-- Features Implemented:
-- - Google Play Billing integration
-- - 7-day free trial management
-- - 3 exercises/day limit for free users
-- - Subscription verification and security
-- - Payment transaction history
-- - Timezone-aware daily usage tracking
--
-- Next Steps:
-- 1. Run this migration in Supabase SQL Editor
-- 2. Update Prisma schema with new tables
-- 3. Implement backend subscription service
-- 4. Create frontend subscription UI components
-- 5. Integrate Google Play Billing API
--
-- ============================================================================
