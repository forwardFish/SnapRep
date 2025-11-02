# SnapRep Database Schema Design (MVP v2.0)

> **Version**: v2.0 MVP-Optimized
> **Author**: Database Architecture Team
> **Date**: 2024-10-30
> **Stack**: NestJS 11 + Prisma + Supabase PostgreSQL
> **Focus**: MVP 核心表 + 规范化多对多关系 + 严格约束

---

## 📋 核心改进点 (vs v1.0)

### ✅ 必须修复 (MVP上线前)
1. **规范化场景/物品为独立表 + N-N关系** - 移除数组字段，使用显式连接表
2. **Supabase双连接串配置** - 区分pooler(6543)和直连(5432)
3. **统一时间类型为timestamptz** - 支持多时区
4. **RLS策略补齐** - 子表策略 + 共享卡片严格条件
5. **收敛到MVP范围** - 移除CardSeries/Analytics等P1功能

### ⚡ 尽快优化 (本迭代内)
6. **用code作为业务稳定键** - 所有核心表添加code字段
7. **约束与校验** - CHECK约束 + 字段长度限制
8. **i18n一致性** - 独立翻译表而非JSON字段
9. **索引策略微调** - 补充复合索引
10. **API与产品对齐** - 统一 POST /api/reco/generate

---

## 1. Prisma Schema 配置

### 1.1 数据源配置 (Supabase)

```prisma
// prisma/schema.prisma

generator client {
  provider = "prisma-client-js"
  previewFeatures = ["fullTextSearch", "fullTextIndex"]
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")   // Supabase Transaction Pooler (6543)
  directUrl = env("DIRECT_URL")     // Direct connection (5432) for migrations
}
```

**环境变量配置**:
```bash
# .env.local
DATABASE_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:6543/postgres?pgbouncer=true&connection_limit=1&sslmode=require"
DIRECT_URL="postgresql://postgres:[PASSWORD]@db.[PROJECT-REF].supabase.co:5432/postgres?sslmode=require"
```

---

## 2. MVP 核心表设计

### 2.1 内容库模块 (Content Library)

#### 2.1.1 Scenario 场景表 (规范化)

```prisma
model Scenario {
  id          String   @id @default(cuid())
  code        String   @unique  // 业务稳定键: "office", "home", "travel"

  // Basic Info (基本信息)
  nameEn      String   @unique @map("name_en")
  nameZh      String?  @map("name_zh")
  nameEs      String?  @map("name_es")

  // Properties (场景特性)
  noiseTolerance   NoiseLevel    @map("noise_tolerance")
  spaceRequirement SpaceSize     @map("space_requirement")

  // Media (媒体资源)
  iconUrl          String?       @map("icon_url")

  // Metadata (元数据)
  displayOrder     Int           @default(0) @map("display_order")
  isActive         Boolean       @default(true) @map("is_active")
  createdAt        DateTime      @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt        DateTime      @updatedAt @map("updated_at") @db.Timestamptz(6)

  // Relations (N-N关系)
  exerciseScenarios    ExerciseScenario[]
  sessionScenarios     WorkoutSessionScenario[]

  @@index([code])
  @@index([isActive])
  @@map("scenarios")
}

enum NoiseLevel {
  SILENT          // 必须静音 (办公室)
  QUIET           // 轻声 (酒店)
  NORMAL          // 正常 (家中)
}

enum SpaceSize {
  SMALL           // 小空间 (1-2m²)
  MEDIUM          // 中等空间 (2-4m²)
  LARGE           // 大空间 (>4m²)
}
```

---

#### 2.1.2 Equipment 器材表 (规范化)

```prisma
model Equipment {
  id          String   @id @default(cuid())
  code        String   @unique  // 业务稳定键: "chair", "wall", "bottle"

  // Basic Info (基本信息)
  nameEn      String   @unique @map("name_en")
  nameZh      String?  @map("name_zh")
  nameEs      String?  @map("name_es")

  // Classification (分类)
  category    EquipmentCategory

  // AI Recognition (AI识别配置)
  isRecognizable      Boolean  @default(false) @map("is_recognizable")
  recognitionLabels   String[] @default([]) @map("recognition_labels")  // TensorFlow Lite labels
  confidenceThreshold Float    @default(0.85) @map("confidence_threshold")

  // Physical Properties (物理属性 - JSON for flexibility)
  properties          Json?    @db.JsonB  // {"weightRange": "0-5kg", "sizeRequirement": "40-50cm"}

  // Safety (安全指导 - JSON for i18n)
  safetyGuidelines    Json     @map("safety_guidelines") @db.JsonB

  // Media Assets (媒体资源)
  iconUrl             String   @map("icon_url")

  // Metadata (元数据)
  displayOrder        Int      @default(0) @map("display_order")
  isActive            Boolean  @default(true) @map("is_active")
  createdAt           DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt           DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)

  // Relations (N-N关系)
  exerciseEquipment        ExerciseEquipment[]
  sessionEquipment         WorkoutSessionEquipment[]

  @@index([code])
  @@index([category])
  @@index([isRecognizable])
  @@index([isActive])
  @@map("equipment")
}

enum EquipmentCategory {
  NONE            // 空手/无器材
  FURNITURE       // 家具系
  WALL            // 墙面系
  BOTTLE          // 瓶罐系
  BAG             // 背包系
  STAIRS          // 台阶系
  FABRIC          // 布料系
  STICK           // 棍棒系
  LUGGAGE         // 行李系
  OUTDOOR         // 户外系
  CREATIVE        // 创意系
}
```

---

#### 2.1.3 Exercise 动作表 (规范化 + 翻译分离)

```prisma
model Exercise {
  id          String   @id @default(cuid())
  code        String   @unique  // 业务稳定键: "wall_chest_opener"

  // Basic Info (基本信息 - 仅英文主表)
  nameEn      String   @unique @map("name_en")

  // Classification (分类定位)
  primaryMuscle     PrimaryMuscle @map("primary_muscle")
  secondaryMuscles  String[]      @map("secondary_muscles")  // 临时保留数组
  intentType        IntentType    @map("intent_type")

  // Difficulty (难度)
  difficulty        Difficulty

  // Space & Noise (空间与噪音)
  spaceRequirement  SpaceSize     @map("space_requirement")
  isSilent          Boolean       @default(false) @map("is_silent")
  noiseLevel        NoiseLevel    @map("noise_level")

  // Dosage (剂量信息)
  defaultDuration   Int           @map("default_duration")    // seconds
  defaultSets       Int           @default(1) @map("default_sets")
  durationFormat    DurationFormat @map("duration_format")

  // Media Assets (媒体资源 - Supabase Storage URLs)
  demoImageUrl      String?       @map("demo_image_url")
  demoVideoUrl      String?       @map("demo_video_url")
  previewGifUrl     String?       @map("preview_gif_url")

  // Tags (标签)
  tags              String[]      @default([])

  // Recommendation Weights (推荐权重)
  popularityScore   Float         @default(0.5) @map("popularity_score")
  safetyScore       Float         @default(1.0) @map("safety_score")
  effectivenessScore Float        @default(0.7) @map("effectiveness_score")

  // Metadata (元数据)
  version           Int           @default(1)
  isActive          Boolean       @default(true) @map("is_active")
  createdAt         DateTime      @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt         DateTime      @updatedAt @map("updated_at") @db.Timestamptz(6)

  // Relations (关系)
  translations          ExerciseI18n[]
  exerciseScenarios     ExerciseScenario[]
  exerciseEquipment     ExerciseEquipment[]
  sessionExercises      SessionExercise[]

  @@index([code])
  @@index([primaryMuscle, difficulty, intentType])
  @@index([intentType, difficulty, isActive])
  @@index([isActive])
  @@index([tags], type: Gin)  // GIN index for array search
  @@map("exercises")
}

// Enums
enum PrimaryMuscle {
  CHEST           // 胸
  BACK            // 背
  LEGS            // 腿
  GLUTES          // 臀
  SHOULDERS       // 肩
  ARMS            // 臂
  CORE            // 核心
  FULL_BODY       // 全身
  NECK_SHOULDER   // 颈肩
}

enum IntentType {
  RELAX           // 放松
  STRETCH         // 舒展筋骨
  MODERATE        // 适当运动
  STRENGTH        // 主体锻炼
}

enum Difficulty {
  BEGINNER        // 初级
  INTERMEDIATE    // 中级
  ADVANCED        // 高级
}

enum DurationFormat {
  TIME            // 时间: 20s×1
  REPS            // 次数: 12reps×3
}
```

---

#### 2.1.4 ExerciseI18n 动作翻译表 (i18n分离)

```prisma
model ExerciseI18n {
  exerciseId   String   @map("exercise_id")
  exercise     Exercise @relation(fields: [exerciseId], references: [id], onDelete: Cascade)

  lang         String   // "en" | "zh" | "es" | "fr"

  // Translatable Fields (可翻译字段)
  title        String?
  keyPoints    Json?    @db.JsonB  // ["要点1", "要点2", "要点3"]
  targetEffect String?  @map("target_effect")
  contraindications Json? @db.JsonB  // ["禁忌1", "禁忌2"]
  operationSteps    Json? @map("operation_steps") @db.JsonB
  commonMistakes    Json? @map("common_mistakes") @db.JsonB
  breathingGuide    String? @map("breathing_guide")

  createdAt    DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt    DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)

  @@id([exerciseId, lang])
  @@index([lang])
  @@map("exercise_i18n")
}
```

---

### 2.2 连接表 (Junction Tables for N-N Relations)

#### 2.2.1 ExerciseScenario 动作-场景关联表

```prisma
model ExerciseScenario {
  exerciseId  String   @map("exercise_id")
  exercise    Exercise @relation(fields: [exerciseId], references: [id], onDelete: Cascade)

  scenarioId  String   @map("scenario_id")
  scenario    Scenario @relation(fields: [scenarioId], references: [id], onDelete: Cascade)

  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

  @@id([exerciseId, scenarioId])
  @@index([scenarioId])  // 反向查询优化
  @@map("exercise_scenarios")
}
```

---

#### 2.2.2 ExerciseEquipment 动作-器材关联表 (支持必需/可选)

```prisma
model ExerciseEquipment {
  exerciseId  String    @map("exercise_id")
  exercise    Exercise  @relation(fields: [exerciseId], references: [id], onDelete: Cascade)

  equipmentId String    @map("equipment_id")
  equipment   Equipment @relation(fields: [equipmentId], references: [id], onDelete: Cascade)

  isOptional  Boolean   @default(true) @map("is_optional")  // false=必需, true=可选

  createdAt   DateTime  @default(now()) @map("created_at") @db.Timestamptz(6)

  @@id([exerciseId, equipmentId])
  @@index([equipmentId])  // 反向查询优化
  @@index([equipmentId, isOptional])  // 按必需/可选筛选
  @@map("exercise_equipment")
}
```

---

### 2.3 用户模块 (User Module)

#### 2.3.1 User 用户表 (扩展Supabase Auth)

```prisma
model User {
  id          String   @id  // Supabase Auth UUID (不使用cuid)

  // Profile (用户资料)
  email       String?  @unique
  nickname    String?
  avatarUrl   String?  @map("avatar_url")

  // Locale Preference (语言偏好)
  language    Language @default(EN)

  // Stats Summary (统计摘要 - 冗余字段)
  totalWorkouts       Int      @default(0) @map("total_workouts")
  totalDurationSec    Int      @default(0) @map("total_duration_sec")
  currentStreak       Int      @default(0) @map("current_streak")
  maxStreak           Int      @default(0) @map("max_streak")

  // Metadata (元数据)
  lastActiveAt        DateTime @default(now()) @map("last_active_at") @db.Timestamptz(6)
  createdAt           DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt           DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)

  // Relations (关系)
  preferences         UserPreference?
  workoutSessions     WorkoutSession[]
  resultCards         ResultCard[]

  @@index([email])
  @@index([lastActiveAt])
  @@map("users")
}

enum Language {
  EN              // English
  ZH              // Chinese (Simplified)
  ES              // Spanish
  FR              // French
  DE              // German
  JA              // Japanese
  KO              // Korean
}
```

---

#### 2.3.2 UserPreference 用户偏好表 (MVP精简版)

```prisma
model UserPreference {
  id                  String   @id @default(cuid())
  userId              String   @unique @map("user_id")
  user                User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  // Workout Preferences (训练偏好 - 使用code数组)
  favoriteIntentTypes IntentType[]  @default([]) @map("favorite_intent_types")
  favoriteEquipmentCodes String[]   @default([]) @map("favorite_equipment_codes")  // Equipment codes
  favoriteScenarioCodes  String[]   @default([]) @map("favorite_scenario_codes")   // Scenario codes
  favoriteMuscleParts PrimaryMuscle[] @default([]) @map("favorite_muscle_parts")
  preferredDifficulty Difficulty?    @map("preferred_difficulty")

  // Mode Preferences (模式偏好)
  silentModeDefault   Boolean  @default(false) @map("silent_mode_default")

  // Exercise History (动作历史频次 - 简化JSON)
  exerciseHistoryJson Json     @default("{}") @map("exercise_history_json") @db.JsonB

  // Notification Settings (通知设置)
  notificationEnabled Boolean  @default(true) @map("notification_enabled")
  streakReminder      Boolean  @default(true) @map("streak_reminder")

  // Metadata (元数据)
  createdAt           DateTime @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt           DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)

  @@map("user_preferences")
}
```

---

### 2.4 训练模块 (Workout Module)

#### 2.4.1 WorkoutSession 训练会话表 (规范化)

```prisma
model WorkoutSession {
  id                  String   @id @default(cuid())

  // User Association (用户关联)
  userId              String   @map("user_id")
  user                User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  // User Input Parameters (用户选择参数 - 使用code)
  intentType          IntentType @map("intent_type")
  targetMuscles       PrimaryMuscle[] @map("target_muscles")

  // Session Configuration (会话配置)
  totalDuration       Int        @map("total_duration")      // seconds
  difficulty          Difficulty
  isSilentMode        Boolean    @default(false) @map("is_silent_mode")

  // Completion Status (完成状态)
  status              SessionStatus @default(PENDING)
  startedAt           DateTime?  @map("started_at") @db.Timestamptz(6)
  completedAt         DateTime?  @map("completed_at") @db.Timestamptz(6)
  actualDuration      Int?       @map("actual_duration")     // seconds
  completionRate      Float?     @map("completion_rate")     // 0.0 - 1.0

  // User Feedback (用户反馈)
  userRating          Int?       @map("user_rating")         // 1-5
  userFeedback        String?    @map("user_feedback") @db.VarChar(500)

  // Metadata (元数据)
  deviceInfo          Json?      @map("device_info") @db.JsonB
  appVersion          String?    @map("app_version") @db.VarChar(20)
  createdAt           DateTime   @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt           DateTime   @updatedAt @map("updated_at") @db.Timestamptz(6)

  // Relations (关系)
  sessionScenarios    WorkoutSessionScenario[]
  sessionEquipment    WorkoutSessionEquipment[]
  sessionExercises    SessionExercise[]
  resultCard          ResultCard?

  @@index([userId, createdAt(sort: Desc)])
  @@index([userId, completedAt(sort: Desc)])
  @@index([userId, status])
  @@index([status])
  @@index([intentType])
  @@map("workout_sessions")
}

enum SessionStatus {
  PENDING           // 待开始
  IN_PROGRESS       // 进行中
  COMPLETED         // 已完成
  ABANDONED         // 已放弃
}
```

**CHECK 约束** (使用 Prisma migrate 后手动添加):
```sql
ALTER TABLE workout_sessions
  ADD CONSTRAINT chk_completion_rate CHECK (completion_rate >= 0 AND completion_rate <= 1),
  ADD CONSTRAINT chk_user_rating CHECK (user_rating >= 1 AND user_rating <= 5);
```

---

#### 2.4.2 WorkoutSessionScenario 会话-场景关联表

```prisma
model WorkoutSessionScenario {
  sessionId   String   @map("session_id")
  session     WorkoutSession @relation(fields: [sessionId], references: [id], onDelete: Cascade)

  scenarioId  String   @map("scenario_id")
  scenario    Scenario @relation(fields: [scenarioId], references: [id], onDelete: Cascade)

  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

  @@id([sessionId, scenarioId])
  @@index([scenarioId])
  @@map("workout_session_scenarios")
}
```

---

#### 2.4.3 WorkoutSessionEquipment 会话-器材关联表

```prisma
model WorkoutSessionEquipment {
  sessionId   String   @map("session_id")
  session     WorkoutSession @relation(fields: [sessionId], references: [id], onDelete: Cascade)

  equipmentId String   @map("equipment_id")
  equipment   Equipment @relation(fields: [equipmentId], references: [id], onDelete: Cascade)

  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

  @@id([sessionId, equipmentId])
  @@index([equipmentId])
  @@map("workout_session_equipment")
}
```

---

#### 2.4.4 SessionExercise 会话动作关联表

```prisma
model SessionExercise {
  id                  String   @id @default(cuid())

  // Relations (关联)
  sessionId           String   @map("session_id")
  session             WorkoutSession @relation(fields: [sessionId], references: [id], onDelete: Cascade)

  exerciseId          String   @map("exercise_id")
  exercise            Exercise @relation(fields: [exerciseId], references: [id])

  // Order & Configuration (顺序配置)
  sequenceOrder       Int      @map("sequence_order")  // 1, 2, 3
  duration            Int      // seconds
  sets                Int      @default(1)

  // Completion (完成状态)
  isCompleted         Boolean  @default(false) @map("is_completed")
  actualDuration      Int?     @map("actual_duration")

  // Replacement Tracking (替换记录)
  wasReplaced         Boolean  @default(false) @map("was_replaced")
  originalExerciseId  String?  @map("original_exercise_id")
  replacementReason   String?  @map("replacement_reason") @db.VarChar(50)

  // Metadata (元数据)
  createdAt           DateTime @default(now()) @map("created_at") @db.Timestamptz(6)

  @@unique([sessionId, sequenceOrder])
  @@index([sessionId])
  @@index([exerciseId])
  @@map("session_exercises")
}
```

**CHECK 约束**:
```sql
ALTER TABLE session_exercises
  ADD CONSTRAINT chk_sequence_order CHECK (sequence_order >= 1 AND sequence_order <= 10),
  ADD CONSTRAINT chk_duration CHECK (duration > 0),
  ADD CONSTRAINT chk_sets CHECK (sets >= 1);
```

---

### 2.5 成果卡模块 (Result Card Module - MVP精简版)

#### 2.5.1 ResultCard 成果卡表 (去除CardSeries依赖)

```prisma
model ResultCard {
  id                  String   @id @default(cuid())

  // User & Session Association (用户和会话关联)
  userId              String   @map("user_id")
  user                User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  sessionId           String   @unique @map("session_id")
  session             WorkoutSession @relation(fields: [sessionId], references: [id], onDelete: Cascade)

  // Card Content (卡片内容 - JSON for i18n)
  cardTitle           Json     @map("card_title") @db.JsonB  // {"en": "Chair Day", "zh": "椅子日"}
  effects             Json     @map("effects") @db.JsonB     // ["Relieve neck...", "Improve..."]

  // Card Style (卡片样式)
  cardStyle           CardStyle  @default(CLASSIC) @map("card_style")
  backgroundType      BackgroundType @default(ILLUSTRATION) @map("background_type")

  // Export Information (导出信息)
  exportedAt          DateTime?  @map("exported_at") @db.Timestamptz(6)
  exportFormat        String?    @map("export_format") @db.VarChar(10)  // "png", "jpeg"
  storageUrl          String?    @map("storage_url")  // Supabase Storage URL

  // Sharing Information (分享信息)
  isShared            Boolean    @default(false) @map("is_shared")  // 严格控制公开访问
  sharedAt            DateTime?  @map("shared_at") @db.Timestamptz(6)
  sharePlatform       String?    @map("share_platform") @db.VarChar(50)
  shareCount          Int        @default(0) @map("share_count")
  deeplinkCode        String     @unique @map("deeplink_code") @db.VarChar(12)  // 6-12字符

  // Metadata (元数据)
  createdAt           DateTime   @default(now()) @map("created_at") @db.Timestamptz(6)
  updatedAt           DateTime   @updatedAt @map("updated_at") @db.Timestamptz(6)

  @@index([userId, createdAt(sort: Desc)])
  @@index([deeplinkCode])
  @@index([isShared])
  @@map("result_cards")
}

enum CardStyle {
  CLASSIC         // 经典
  VIBRANT         // 鲜艳
  MINIMAL         // 极简
}

enum BackgroundType {
  ILLUSTRATION    // 插画
  PHOTO           // 实拍
  GRADIENT        // 渐变
}
```

**CHECK 约束**:
```sql
ALTER TABLE result_cards
  ADD CONSTRAINT chk_deeplink_code CHECK (deeplink_code ~ '^[A-Za-z0-9_-]{6,12}$'),
  ADD CONSTRAINT chk_share_count CHECK (share_count >= 0);
```

---

## 3. Supabase RLS 策略 (严格版)

### 3.1 启用RLS

```sql
-- 用户表
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- 训练表
ALTER TABLE workout_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_session_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE workout_session_equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE session_exercises ENABLE ROW LEVEL SECURITY;

-- 成果卡表
ALTER TABLE result_cards ENABLE ROW LEVEL SECURITY;

-- 内容表 (公开只读)
ALTER TABLE scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercises ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_i18n ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE exercise_equipment ENABLE ROW LEVEL SECURITY;
```

---

### 3.2 核心RLS策略

#### 3.2.1 用户表策略

```sql
-- Users: 只能查看/更新自己的资料
CREATE POLICY "users_select_own" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_update_own" ON users
  FOR UPDATE USING (auth.uid() = id);

-- User Preferences: 完全控制自己的偏好
CREATE POLICY "user_preferences_all_own" ON user_preferences
  FOR ALL USING (auth.uid() = user_id);
```

---

#### 3.2.2 训练会话策略 (含子表回溯)

```sql
-- Workout Sessions: 完全控制自己的会话
CREATE POLICY "workout_sessions_all_own" ON workout_sessions
  FOR ALL USING (auth.uid() = user_id);

-- Session Scenarios: 通过会话回溯所有权
CREATE POLICY "session_scenarios_all_own" ON workout_session_scenarios
  FOR ALL USING (
    auth.uid() = (SELECT user_id FROM workout_sessions WHERE id = session_id)
  );

-- Session Equipment: 通过会话回溯所有权
CREATE POLICY "session_equipment_all_own" ON workout_session_equipment
  FOR ALL USING (
    auth.uid() = (SELECT user_id FROM workout_sessions WHERE id = session_id)
  );

-- Session Exercises: 通过会话回溯所有权
CREATE POLICY "session_exercises_all_own" ON session_exercises
  FOR ALL USING (
    auth.uid() = (SELECT user_id FROM workout_sessions WHERE id = session_id)
  );
```

---

#### 3.2.3 成果卡策略 (严格共享控制)

```sql
-- Result Cards: 完全控制自己的卡片
CREATE POLICY "result_cards_all_own" ON result_cards
  FOR ALL USING (auth.uid() = user_id);

-- Result Cards: 公开查看已分享的卡片 (严格条件)
CREATE POLICY "result_cards_select_shared" ON result_cards
  FOR SELECT USING (is_shared = true AND deeplink_code IS NOT NULL);
```

---

#### 3.2.4 内容表策略 (公开只读)

```sql
-- Scenarios: 所有人可查看启用的场景
CREATE POLICY "scenarios_select_public" ON scenarios
  FOR SELECT USING (is_active = true);

-- Equipment: 所有人可查看启用的器材
CREATE POLICY "equipment_select_public" ON equipment
  FOR SELECT USING (is_active = true);

-- Exercises: 所有人可查看启用的动作
CREATE POLICY "exercises_select_public" ON exercises
  FOR SELECT USING (is_active = true);

-- Exercise I18n: 所有人可查看翻译
CREATE POLICY "exercise_i18n_select_public" ON exercise_i18n
  FOR SELECT USING (true);

-- Exercise Scenarios: 所有人可查看关联
CREATE POLICY "exercise_scenarios_select_public" ON exercise_scenarios
  FOR SELECT USING (true);

-- Exercise Equipment: 所有人可查看关联
CREATE POLICY "exercise_equipment_select_public" ON exercise_equipment
  FOR SELECT USING (true);
```

**注意**: Service role 自动绕过RLS，无需额外策略。

---

## 4. 索引策略优化

### 4.1 核心查询索引

```sql
-- Exercise 推荐查询复合索引
CREATE INDEX idx_exercises_recommend
  ON exercises(intent_type, difficulty, is_active, popularity_score DESC)
  WHERE is_active = true;

-- Exercise 按场景查询
CREATE INDEX idx_exercise_scenarios_composite
  ON exercise_scenarios(scenario_id, exercise_id);

-- Exercise 按器材查询 (区分必需/可选)
CREATE INDEX idx_exercise_equipment_composite
  ON exercise_equipment(equipment_id, is_optional, exercise_id);

-- Workout Session 用户历史查询
CREATE INDEX idx_sessions_user_created
  ON workout_sessions(user_id, created_at DESC)
  WHERE status = 'COMPLETED';

-- Workout Session 用户完成记录
CREATE INDEX idx_sessions_user_completed
  ON workout_sessions(user_id, completed_at DESC)
  WHERE status = 'COMPLETED';

-- Result Card 用户卡片查询
CREATE INDEX idx_cards_user_created
  ON result_cards(user_id, created_at DESC);

-- 全文搜索索引 (支持中英文)
CREATE INDEX idx_exercises_fulltext_en
  ON exercises USING GIN(to_tsvector('english', name_en));

CREATE INDEX idx_exercises_fulltext_multi
  ON exercises USING GIN(to_tsvector('simple',
    COALESCE(name_en, '') || ' ' ||
    (SELECT STRING_AGG(title, ' ') FROM exercise_i18n WHERE exercise_id = exercises.id)
  ));
```

---

## 5. API 端点设计 (统一规范)

### 5.1 核心端点

```typescript
// 推荐引擎 (统一为 POST)
POST   /api/reco/generate
  Body: {
    intentType: "STRETCH",
    scenarioCodes: ["office"],
    equipmentCodes: ["chair", "wall"],
    targetMuscles: ["NECK_SHOULDER"],
    difficulty: "BEGINNER",
    isSilentMode: true
  }
  Response: {
    candidates: Exercise[],  // 10个候选动作
    recommendations: Exercise[]  // 算法推荐的3个动作
  }

// 创建训练会话
POST   /api/workout/sessions
  Body: {
    intentType: "STRETCH",
    scenarioCodes: ["office"],
    equipmentCodes: ["chair"],
    targetMuscles: ["NECK_SHOULDER"],
    exerciseIds: ["ex_001", "ex_002", "ex_003"],
    totalDuration: 60
  }
  Response: WorkoutSession

// 完成训练
PATCH  /api/workout/sessions/:id/complete
  Body: {
    actualDuration: 65,
    completionRate: 1.0,
    exerciseCompletions: [
      { exerciseId: "ex_001", isCompleted: true, actualDuration: 22 },
      { exerciseId: "ex_002", isCompleted: true, actualDuration: 20 },
      { exerciseId: "ex_003", isCompleted: true, actualDuration: 23 }
    ]
  }
  Response: WorkoutSession

// 生成成果卡
POST   /api/cards/generate
  Body: { sessionId: "ws_xxx", cardStyle: "CLASSIC" }
  Response: ResultCard (with storageUrl)

// 分享成果卡
POST   /api/cards/:id/share
  Body: { platform: "instagram" }
  Response: { deeplinkUrl: "https://app.snaprep.io/c/ABC123", shareCount: 1 }

// 深链处理 (一键同款)
GET    /api/cards/deeplink/:code
  Response: {
    sessionParams: { intentType, scenarioCodes, equipmentCodes, targetMuscles },
    exercises: Exercise[]
  }
```

---

## 6. 数据迁移 & 种子数据

### 6.1 迁移脚本

```bash
# 生成Prisma Client
npx prisma generate

# 创建初始迁移
npx prisma migrate dev --name init_mvp_v2

# 部署到生产环境 (Supabase)
npx prisma migrate deploy
```

---

### 6.2 种子数据示例

```typescript
// prisma/seed.ts
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // 1. Seed Scenarios
  await prisma.scenario.createMany({
    data: [
      {
        code: 'office',
        nameEn: 'Office',
        nameZh: '办公室',
        noiseTolerance: 'SILENT',
        spaceRequirement: 'SMALL',
        iconUrl: '/assets/scenarios/office.svg',
      },
      {
        code: 'home',
        nameEn: 'Living Room',
        nameZh: '客厅',
        noiseTolerance: 'NORMAL',
        spaceRequirement: 'MEDIUM',
        iconUrl: '/assets/scenarios/home.svg',
      },
      {
        code: 'travel',
        nameEn: 'Travel / Hotel',
        nameZh: '旅途/酒店',
        noiseTolerance: 'QUIET',
        spaceRequirement: 'SMALL',
        iconUrl: '/assets/scenarios/travel.svg',
      },
    ],
  });

  // 2. Seed Equipment
  await prisma.equipment.createMany({
    data: [
      {
        code: 'none',
        nameEn: 'No Equipment',
        nameZh: '空手',
        category: 'NONE',
        iconUrl: '/assets/equipment/none.svg',
        safetyGuidelines: { en: 'Use your body weight only', zh: '仅使用自身体重' },
      },
      {
        code: 'chair',
        nameEn: 'Chair',
        nameZh: '椅子',
        category: 'FURNITURE',
        isRecognizable: true,
        recognitionLabels: ['chair', 'stool', 'seat'],
        iconUrl: '/assets/equipment/chair.svg',
        safetyGuidelines: {
          en: 'Use a stable chair that can support your body weight',
          zh: '使用稳固椅子，能承受体重',
        },
      },
      {
        code: 'wall',
        nameEn: 'Wall',
        nameZh: '墙面',
        category: 'WALL',
        isRecognizable: true,
        recognitionLabels: ['wall'],
        iconUrl: '/assets/equipment/wall.svg',
        safetyGuidelines: {
          en: 'Use a flat, sturdy wall',
          zh: '使用平整、坚固的墙面',
        },
      },
    ],
  });

  // 3. Seed Exercise
  const exercise = await prisma.exercise.create({
    data: {
      code: 'wall_chest_opener',
      nameEn: 'Wall Chest Opener',
      primaryMuscle: 'NECK_SHOULDER',
      secondaryMuscles: ['CHEST', 'SHOULDERS'],
      intentType: 'STRETCH',
      difficulty: 'BEGINNER',
      spaceRequirement: 'SMALL',
      isSilent: true,
      noiseLevel: 'SILENT',
      defaultDuration: 20,
      defaultSets: 1,
      durationFormat: 'TIME',
      tags: ['standing', 'wall', 'stretch', 'silent', 'small_space'],
      popularityScore: 0.85,
      safetyScore: 0.95,
      demoImageUrl: 'https://[supabase]/storage/v1/object/public/exercise-media/wall_chest_opener.jpg',
    },
  });

  // 4. Seed Exercise I18n
  await prisma.exerciseI18n.createMany({
    data: [
      {
        exerciseId: exercise.id,
        lang: 'en',
        title: 'Wall Chest Opener',
        keyPoints: ['Keep spine neutral', 'Arms extended upward', 'Breathe naturally'],
        targetEffect: 'Relieve neck stiffness, relax shoulders',
        contraindications: ['Keep neck neutral, no hyperextension', 'Lower shoulders, no shrugging'],
        operationSteps: ['Stand against wall', 'Raise arms overhead', 'Hold for 20 seconds'],
      },
      {
        exerciseId: exercise.id,
        lang: 'zh',
        title: '靠墙胸椎打开',
        keyPoints: ['脊柱保持中立', '双臂向上延展', '保持自然呼吸'],
        targetEffect: '缓解颈部僵硬,放松肩颈',
        contraindications: ['颈保持中立,不后仰', '肩下沉不耸肩'],
        operationSteps: ['背部贴墙站立', '双臂向上举', '保持20秒'],
      },
    ],
  });

  // 5. Link Exercise to Scenarios
  await prisma.exerciseScenario.createMany({
    data: [
      { exerciseId: exercise.id, scenarioId: (await prisma.scenario.findUnique({ where: { code: 'office' } }))!.id },
      { exerciseId: exercise.id, scenarioId: (await prisma.scenario.findUnique({ where: { code: 'home' } }))!.id },
    ],
  });

  // 6. Link Exercise to Equipment (必需器材)
  await prisma.exerciseEquipment.create({
    data: {
      exerciseId: exercise.id,
      equipmentId: (await prisma.equipment.findUnique({ where: { code: 'wall' } }))!.id,
      isOptional: false,  // 必需
    },
  });

  console.log('✅ Seed data created successfully!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
```

---

## 7. 性能基准测试

| 操作 | 目标时间 | 测试结果 | 状态 |
|------|---------|---------|------|
| 动作推荐查询 (JOIN场景+器材) | ≤50ms | TBD | 🔄 |
| 创建训练会话 (4张表INSERT) | ≤100ms | TBD | 🔄 |
| 生成成果卡 | ≤800ms | TBD | 🔄 |
| 用户历史查询 (30天) | ≤100ms | TBD | 🔄 |

---

## 8. 数据库备份策略

```bash
# Supabase自动备份 (每日)
# 手动备份
supabase db dump -f backup_$(date +%Y%m%d).sql

# 恢复
psql $DIRECT_URL < backup_20241030.sql
```

---

## Appendix: 与v1.0的关键差异

| 特性 | v1.0 | v2.0 MVP |
|------|------|----------|
| 场景/器材关系 | String[] 数组 | N-N连接表 (ExerciseScenario/ExerciseEquipment) |
| 业务主键 | 仅 id | 添加 code 字段 |
| 时间类型 | DateTime | @db.Timestamptz(6) |
| i18n方案 | JSON字段 | 独立 exercise_i18n 表 |
| Supabase连接 | 单URL | 双URL (pooler + direct) |
| RLS策略 | 基础策略 | 子表回溯 + 严格共享控制 |
| 成果卡依赖 | CardSeries外键 | 解耦,去除系列依赖 |
| CHECK约束 | 无 | completionRate/userRating等 |
| MVP范围 | 11张表 | 14张表 (去除CardSeries/UserStats/EquipmentFrequency) |

---

**文档维护**:
- 本schema为MVP上线版本
- P1功能 (CardSeries/Analytics/UserStats) 待后续迭代添加
- 所有breaking changes需migration脚本

**审核状态**:
- ✅ 规范化多对多关系
- ✅ Supabase双连接串配置
- ✅ RLS策略严格化
- ✅ 添加CHECK约束
- 🔄 性能测试待完成

---

*SnapRep Database Design v2.0 MVP - 2024.10.30*
*NestJS 11 + Prisma 5 + Supabase PostgreSQL*
