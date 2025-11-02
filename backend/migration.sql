-- CreateEnum
CREATE TYPE "NoiseLevel" AS ENUM ('SILENT', 'QUIET', 'NORMAL');

-- CreateEnum
CREATE TYPE "SpaceSize" AS ENUM ('SMALL', 'MEDIUM', 'LARGE');

-- CreateEnum
CREATE TYPE "EquipmentCategory" AS ENUM ('NONE', 'FURNITURE', 'WALL', 'BOTTLE', 'BAG', 'STAIRS', 'FABRIC', 'STICK', 'OUTDOOR', 'CREATIVE');

-- CreateEnum
CREATE TYPE "PrimaryMuscle" AS ENUM ('CHEST', 'BACK', 'LEGS', 'GLUTES', 'SHOULDERS', 'ARMS', 'CORE', 'FULL_BODY', 'NECK_SHOULDER');

-- CreateEnum
CREATE TYPE "IntentType" AS ENUM ('RELAX', 'STRETCH', 'MODERATE', 'STRENGTH');

-- CreateEnum
CREATE TYPE "Difficulty" AS ENUM ('BEGINNER', 'INTERMEDIATE', 'ADVANCED');

-- CreateEnum
CREATE TYPE "DurationType" AS ENUM ('TIME', 'REPS');

-- CreateEnum
CREATE TYPE "SessionStatus" AS ENUM ('PENDING', 'IN_PROGRESS', 'COMPLETED', 'ABANDONED');

-- CreateTable
CREATE TABLE "scenarios" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "noise_tolerance" "NoiseLevel",
    "space_requirement" "SpaceSize",
    "icon_url" TEXT,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "scenarios_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "equipment" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "category" "EquipmentCategory" NOT NULL,
    "recognizable" BOOLEAN NOT NULL DEFAULT false,
    "recognitionLabels" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "recognitionConfidence" DOUBLE PRECISION NOT NULL DEFAULT 0.85,
    "icon_url" TEXT NOT NULL,
    "image_url" TEXT,
    "display_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "equipment_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exercises" (
    "id" TEXT NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "primaryMuscle" "PrimaryMuscle" NOT NULL,
    "secondaryMuscles" TEXT[],
    "intentType" "IntentType" NOT NULL,
    "difficulty" "Difficulty" NOT NULL,
    "spaceRequirement" "SpaceSize" NOT NULL,
    "noiseLevel" "NoiseLevel" NOT NULL,
    "is_silent" BOOLEAN NOT NULL DEFAULT false,
    "description" JSONB NOT NULL,
    "default_duration" INTEGER NOT NULL,
    "default_sets" INTEGER NOT NULL DEFAULT 1,
    "duration_type" "DurationType" NOT NULL,
    "demo_image_url" TEXT,
    "demo_video_url" TEXT,
    "tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "exercises_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exercise_scenarios" (
    "exercise_id" TEXT NOT NULL,
    "scenario_id" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "exercise_scenarios_pkey" PRIMARY KEY ("exercise_id","scenario_id")
);

-- CreateTable
CREATE TABLE "exercise_equipment" (
    "exercise_id" TEXT NOT NULL,
    "equipment_id" TEXT NOT NULL,
    "is_required" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "exercise_equipment_pkey" PRIMARY KEY ("exercise_id","equipment_id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "email" TEXT,
    "name" TEXT,
    "avatar_url" TEXT,
    "total_workouts" INTEGER NOT NULL DEFAULT 0,
    "total_duration_sec" INTEGER NOT NULL DEFAULT 0,
    "current_streak" INTEGER NOT NULL DEFAULT 0,
    "longest_streak" INTEGER NOT NULL DEFAULT 0,
    "preferredIntents" "IntentType"[] DEFAULT ARRAY[]::"IntentType"[],
    "preferredDifficulty" "Difficulty",
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
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "workout_sessions" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "intentType" "IntentType" NOT NULL,
    "scenario_id" TEXT,
    "targetMuscles" "PrimaryMuscle"[],
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
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "workout_sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
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

-- CreateTable
CREATE TABLE "share_cards" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "session_id" TEXT NOT NULL,
    "card_image_url" TEXT NOT NULL,
    "card_template" TEXT NOT NULL,
    "card_data" JSONB NOT NULL,
    "rarity" TEXT NOT NULL,
    "equipment_series" TEXT NOT NULL,
    "rarity_score" DOUBLE PRECISION NOT NULL,
    "special_tags" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "city_edition" TEXT,
    "theme_week" TEXT,
    "share_text" VARCHAR(500),
    "is_public" BOOLEAN NOT NULL DEFAULT true,
    "share_count" INTEGER NOT NULL DEFAULT 0,
    "view_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "share_cards_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "daily_trainings" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
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
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "daily_trainings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "equipment_frequencies" (
    "id" TEXT NOT NULL,
    "equipment_id" TEXT NOT NULL,
    "equipment_code" TEXT NOT NULL,
    "statistics_date" DATE NOT NULL,
    "daily_usage_count" INTEGER NOT NULL DEFAULT 0,
    "weekly_usage_count" INTEGER NOT NULL DEFAULT 0,
    "monthly_usage_count" INTEGER NOT NULL DEFAULT 0,
    "global_daily_rank" INTEGER,
    "global_weekly_rank" INTEGER,
    "rarity_score" DOUBLE PRECISION NOT NULL,
    "rarity_level" TEXT NOT NULL,
    "region" TEXT,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "equipment_frequencies_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_preferences" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
    "preference_type" TEXT NOT NULL,
    "preference_key" TEXT NOT NULL,
    "preference_value" DOUBLE PRECISION NOT NULL,
    "usage_count" INTEGER NOT NULL DEFAULT 0,
    "success_rate" DOUBLE PRECISION NOT NULL DEFAULT 0.0,
    "average_rating" DOUBLE PRECISION,
    "last_used_at" TIMESTAMPTZ(6),
    "first_used_at" TIMESTAMPTZ(6) NOT NULL,
    "created_at" TIMESTAMPTZ(6) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "user_preferences_pkey" PRIMARY KEY ("id")
);

-- CreateTable
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
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "theme_weeks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "theme_week_participations" (
    "id" TEXT NOT NULL,
    "user_id" TEXT NOT NULL,
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
    "updated_at" TIMESTAMPTZ(6) NOT NULL,

    CONSTRAINT "theme_week_participations_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "scenarios_code_key" ON "scenarios"("code");

-- CreateIndex
CREATE INDEX "scenarios_code_idx" ON "scenarios"("code");

-- CreateIndex
CREATE INDEX "scenarios_is_active_idx" ON "scenarios"("is_active");

-- CreateIndex
CREATE UNIQUE INDEX "equipment_code_key" ON "equipment"("code");

-- CreateIndex
CREATE INDEX "equipment_code_idx" ON "equipment"("code");

-- CreateIndex
CREATE INDEX "equipment_category_idx" ON "equipment"("category");

-- CreateIndex
CREATE INDEX "equipment_recognizable_idx" ON "equipment"("recognizable");

-- CreateIndex
CREATE UNIQUE INDEX "exercises_code_key" ON "exercises"("code");

-- CreateIndex
CREATE INDEX "exercises_code_idx" ON "exercises"("code");

-- CreateIndex
CREATE INDEX "exercises_primaryMuscle_difficulty_intentType_idx" ON "exercises"("primaryMuscle", "difficulty", "intentType");

-- CreateIndex
CREATE INDEX "exercises_is_active_idx" ON "exercises"("is_active");

-- CreateIndex
CREATE INDEX "exercise_scenarios_scenario_id_idx" ON "exercise_scenarios"("scenario_id");

-- CreateIndex
CREATE INDEX "exercise_equipment_equipment_id_idx" ON "exercise_equipment"("equipment_id");

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_email_idx" ON "users"("email");

-- CreateIndex
CREATE INDEX "workout_sessions_user_id_completed_at_idx" ON "workout_sessions"("user_id", "completed_at" DESC);

-- CreateIndex
CREATE INDEX "workout_sessions_status_idx" ON "workout_sessions"("status");

-- CreateIndex
CREATE INDEX "session_exercises_session_id_idx" ON "session_exercises"("session_id");

-- CreateIndex
CREATE UNIQUE INDEX "session_exercises_session_id_sequence_order_key" ON "session_exercises"("session_id", "sequence_order");

-- CreateIndex
CREATE UNIQUE INDEX "share_cards_session_id_key" ON "share_cards"("session_id");

-- CreateIndex
CREATE INDEX "share_cards_user_id_created_at_idx" ON "share_cards"("user_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "share_cards_is_public_idx" ON "share_cards"("is_public");

-- CreateIndex
CREATE INDEX "daily_trainings_user_id_training_date_idx" ON "daily_trainings"("user_id", "training_date" DESC);

-- CreateIndex
CREATE INDEX "daily_trainings_training_date_idx" ON "daily_trainings"("training_date");

-- CreateIndex
CREATE UNIQUE INDEX "daily_trainings_user_id_training_date_key" ON "daily_trainings"("user_id", "training_date");

-- CreateIndex
CREATE INDEX "equipment_frequencies_statistics_date_idx" ON "equipment_frequencies"("statistics_date");

-- CreateIndex
CREATE INDEX "equipment_frequencies_rarity_level_statistics_date_idx" ON "equipment_frequencies"("rarity_level", "statistics_date");

-- CreateIndex
CREATE INDEX "equipment_frequencies_global_weekly_rank_idx" ON "equipment_frequencies"("global_weekly_rank");

-- CreateIndex
CREATE UNIQUE INDEX "equipment_frequencies_equipment_id_statistics_date_key" ON "equipment_frequencies"("equipment_id", "statistics_date");

-- CreateIndex
CREATE UNIQUE INDEX "equipment_frequencies_equipment_code_statistics_date_key" ON "equipment_frequencies"("equipment_code", "statistics_date");

-- CreateIndex
CREATE INDEX "user_preferences_user_id_preference_type_idx" ON "user_preferences"("user_id", "preference_type");

-- CreateIndex
CREATE INDEX "user_preferences_preference_value_idx" ON "user_preferences"("preference_value" DESC);

-- CreateIndex
CREATE UNIQUE INDEX "user_preferences_user_id_preference_type_preference_key_key" ON "user_preferences"("user_id", "preference_type", "preference_key");

-- CreateIndex
CREATE UNIQUE INDEX "theme_weeks_code_key" ON "theme_weeks"("code");

-- CreateIndex
CREATE INDEX "theme_weeks_status_start_date_idx" ON "theme_weeks"("status", "start_date");

-- CreateIndex
CREATE INDEX "theme_weeks_equipment_code_idx" ON "theme_weeks"("equipment_code");

-- CreateIndex
CREATE INDEX "theme_weeks_display_order_idx" ON "theme_weeks"("display_order");

-- CreateIndex
CREATE INDEX "theme_week_participations_theme_week_id_status_idx" ON "theme_week_participations"("theme_week_id", "status");

-- CreateIndex
CREATE INDEX "theme_week_participations_user_id_status_idx" ON "theme_week_participations"("user_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "theme_week_participations_user_id_theme_week_id_key" ON "theme_week_participations"("user_id", "theme_week_id");

-- AddForeignKey
ALTER TABLE "exercise_scenarios" ADD CONSTRAINT "exercise_scenarios_exercise_id_fkey" FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exercise_scenarios" ADD CONSTRAINT "exercise_scenarios_scenario_id_fkey" FOREIGN KEY ("scenario_id") REFERENCES "scenarios"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exercise_equipment" ADD CONSTRAINT "exercise_equipment_exercise_id_fkey" FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exercise_equipment" ADD CONSTRAINT "exercise_equipment_equipment_id_fkey" FOREIGN KEY ("equipment_id") REFERENCES "equipment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_sessions" ADD CONSTRAINT "workout_sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "workout_sessions" ADD CONSTRAINT "workout_sessions_scenario_id_fkey" FOREIGN KEY ("scenario_id") REFERENCES "scenarios"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "session_exercises" ADD CONSTRAINT "session_exercises_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "workout_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "session_exercises" ADD CONSTRAINT "session_exercises_exercise_id_fkey" FOREIGN KEY ("exercise_id") REFERENCES "exercises"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "share_cards" ADD CONSTRAINT "share_cards_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "share_cards" ADD CONSTRAINT "share_cards_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "workout_sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "daily_trainings" ADD CONSTRAINT "daily_trainings_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "equipment_frequencies" ADD CONSTRAINT "equipment_frequencies_equipment_id_fkey" FOREIGN KEY ("equipment_id") REFERENCES "equipment"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_preferences" ADD CONSTRAINT "user_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "theme_week_participations" ADD CONSTRAINT "theme_week_participations_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "theme_week_participations" ADD CONSTRAINT "theme_week_participations_theme_week_id_fkey" FOREIGN KEY ("theme_week_id") REFERENCES "theme_weeks"("id") ON DELETE CASCADE ON UPDATE CASCADE;

