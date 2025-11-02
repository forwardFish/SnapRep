# SnapRep 数据库表结构设计文档 (专业简化版)

> **版本**: v2.0 Simplified
> **日期**: 2024-10-30
> **技术栈**: NestJS 11 + Prisma + Supabase PostgreSQL
> **设计原则**: KISS (Keep It Simple, Stupid) - 从 MVP 出发，避免过度设计

---

## 📋 设计原则

### 核心原则
1. **英文优先** - 所有字段使用英文，前端通过 i18n 库处理多语言
2. **可选字段最小化** - 只在真正需要时使用可选字段
3. **避免过早优化** - 不添加暂时用不到的功能
4. **数据库职责清晰** - 只存储核心业务数据，不做展示逻辑

### 环境配置

```bash
# .env
DATABASE_URL="postgresql://postgres:Snaprep@123@db.tvjcmleckqovnieuexgu.supabase.co:6543/postgres?pgbouncer=true&connection_limit=1&sslmode=require"
DIRECT_URL="postgresql://postgres:Snaprep@123@db.tvjcmleckqovnieuexgu.supabase.co:5432/postgres?sslmode=require"
```

---

## 3. Prisma Schema 定义

### 3.1 配置

```prisma
generator client {
  provider = "prisma-client-js"
  previewFeatures = ["fullTextSearch"]
}

datasource db {
  provider  = "postgresql"
  url       = env("DATABASE_URL")
  directUrl = env("DIRECT_URL")
}
```

---

## 📚 核心表设计

### 1. Scenario 表 - 场景表 (简化版)

**设计说明**：
- 移除多语言字段，前端通过 i18n 文件处理翻译
- `noiseTolerance` 和 `spaceRequirement` 改为可选，因为不是所有场景都需要这些约束
- 使用 `code` 作为唯一业务键，方便前端引用

```prisma
model Scenario {
  id        String   @id @default(cuid())        // 主键ID (自动生成的唯一标识符)
  code      String   @unique                     // 业务标识符 (用于前端引用，如 "office", "home", "gym")
  name      String                               // 场景名称 (英文，如 "Office", "Home", "Gym")

  // 场景特性 (可选字段)
  noiseTolerance   NoiseLevel?  @map("noise_tolerance")    // 噪音容忍度 (可选，不是所有场景都需要)
  spaceRequirement SpaceSize?   @map("space_requirement")  // 空间需求 (可选，如办公室是小空间，公园是大空间)

  // 媒体资源
  iconUrl   String?  @map("icon_url")            // 图标URL地址 (可选，用于在选择器中显示)

  // 元数据字段
  isActive  Boolean  @default(true) @map("is_active")                  // 是否启用 (false时不会在前端显示)
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz(6)  // 创建时间 (自动记录)
  updatedAt DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)       // 最后更新时间 (自动更新)

  // 数据库关系
  exerciseScenarios  ExerciseScenario[]     // 关联的动作列表 (一个场景可以有多个动作)
  workoutSessions    WorkoutSession[]       // 在此场景进行的训练会话

  @@index([code])        // 索引：加速通过 code 查询
  @@index([isActive])    // 索引：快速筛选启用的场景
  @@map("scenarios")     // 数据库表名
}

// 噪音等级枚举 (描述场景对噪音的要求)
enum NoiseLevel {
  SILENT   // 必须静音 - 适合办公室、图书馆等需要绝对安静的场景
  QUIET    // 安静 - 适合酒店房间、宿舍等需要保持安静的场景
  NORMAL   // 正常 - 适合家中、健身房等可以发出正常声响的场景
}

// 空间大小枚举 (描述场景所需的活动空间)
enum SpaceSize {
  SMALL    // 小空间 (1-2平方米) - 如办公桌旁边、狭小房间
  MEDIUM   // 中等空间 (2-4平方米) - 如客厅一角、卧室
  LARGE    // 大空间 (>4平方米) - 如公园、健身房、大客厅
}
```

---

### 2. Equipment 表 - 器材表 (简化版)

**设计说明**：
- 移除多语言，只保留 `name`
- 移除 `CardSeries` 依赖，避免过度耦合
- AI 识别相关字段保留，因为是核心功能

```prisma
model Equipment {
  id          String   @id @default(cuid())          // 主键ID (自动生成)
  code        String   @unique                       // 业务标识符 (如 "chair", "wall", "bottle")
  name        String                                 // 器材名称 (英文，如 "Chair", "Wall", "Water Bottle")
  category    EquipmentCategory                      // 器材分类 (家具、墙面、水瓶等)

  // AI 识别配置 (核心功能)
  recognizable          Boolean  @default(false)     // 是否可通过相机识别 (true表示可以用TensorFlow识别)
  recognitionLabels     String[] @default([])        // TensorFlow Lite 识别标签 (如 ["chair", "stool", "seat"])
  recognitionConfidence Float    @default(0.85)      // 识别置信度阈值 (0.85表示85%以上才认为识别成功)

  // 媒体资源
  iconUrl     String   @map("icon_url")              // 图标URL (必需，用于器材选择界面的9宫格显示)
  imageUrl    String?  @map("image_url")             // 大图URL (可选，用于详情页展示)

  // 元数据字段
  displayOrder Int     @default(0) @map("display_order")                   // 显示顺序 (数字越小越靠前)
  isActive    Boolean  @default(true) @map("is_active")                    // 是否启用
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(6)   // 创建时间
  updatedAt   DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)        // 最后更新时间

  // 数据库关系
  exerciseEquipment ExerciseEquipment[]    // 关联的动作列表 (一个器材可以用于多个动作)
  equipmentFrequencies EquipmentFrequency[] // 器材使用频次统计记录 (一对多关系)

  @@index([code])          // 索引：通过 code 快速查询
  @@index([category])      // 索引：按分类筛选
  @@index([recognizable])  // 索引：快速查找可识别的器材
  @@map("equipment")       // 数据库表名
}

// 器材分类枚举 (将器材按类型分组)
enum EquipmentCategory {
  NONE         // 徒手/无器材 - 不需要任何器材的训练
  FURNITURE    // 家具系 - 椅子、沙发、桌子等家具
  WALL         // 墙面系 - 墙壁、门框等固定结构
  BOTTLE       // 水瓶系 - 水瓶、饮料瓶等容器
  BAG          // 背包系 - 背包、手提包等便携物品
  STAIRS       // 台阶系 - 楼梯、台阶、凳子等有高度差的物品
  FABRIC       // 布料系 - 毛巾、床单、围巾等柔软织物
  STICK        // 棍棒系 - 扫把、拖把、雨伞等长杆状物品
  OUTDOOR      // 户外系 - 树木、长椅、石头等户外环境物品
  CREATIVE     // 创意系 - 其他创意性使用的物品
}
```

---

### 3. Exercise 表 - 动作表 (简化版)

**设计说明**：
- 只保留英文名称
- 详细描述 (keyPoints, targetEffect等) 使用 JSON 存储，支持前端 i18n
- 移除复杂的评分系统，只保留核心字段

```prisma
model Exercise {
  id        String   @id @default(cuid())          // 主键ID (自动生成的唯一标识符)
  code      String   @unique                       // 业务标识符 (如 "wall_chest_opener", "chair_squat")
  name      String                                 // 动作名称 (英文，如 "Wall Chest Opener", "Chair Squat")

  // 肌群分类
  primaryMuscle    PrimaryMuscle                   // 主要目标肌群 (如胸部、背部、腿部等)
  secondaryMuscles String[]                        // 次要肌群列表 (如 ["SHOULDERS", "CORE"])
  intentType       IntentType                      // 运动意图类型 (放松、拉伸、适度运动、力量训练)
  difficulty       Difficulty                      // 难度等级 (初级、中级、高级)

  // 动作详情 (JSON 格式，支持前端 i18n)
  description      Json                            // 详细描述 (包含动作要点、步骤、注意事项等，支持多语言)
                                                  // 格式: {"keyPoints": [...], "steps": [...], "warnings": [...]}

  // 时长配置
  defaultDuration  Int   @map("default_duration")  // 默认时长 (秒数，如20表示20秒)
  defaultSets      Int   @default(1) @map("default_sets")   // 默认组数 (通常为1-3组)
  durationType     DurationType @map("duration_type")       // 计量方式 (按时间或按次数)

  // 媒体资源
  demoImageUrl     String?  @map("demo_image_url") // 示范图片URL (可选，用于展示动作姿势)
  demoVideoUrl     String?  @map("demo_video_url") // 示范视频URL (可选，用于动态展示)

  // 标签系统
  tags             String[] @default([])           // 标签列表 (如 ["静音", "小空间", "办公室适用"])

  // 元数据字段
  isActive         Boolean  @default(true) @map("is_active")                    // 是否启用 (false时不会在推荐中出现)
  createdAt        DateTime @default(now()) @map("created_at") @db.Timestamptz(6)   // 创建时间 (自动记录)
  updatedAt        DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)        // 最后更新时间 (自动更新)

  // 数据库关系
  exerciseScenarios ExerciseScenario[]            // 关联的场景列表 (一个动作可以适用于多个场景)
  exerciseEquipment ExerciseEquipment[]           // 关联的器材列表 (一个动作可以使用多种器材)
  sessionExercises  SessionExercise[]             // 在训练会话中的使用记录

  @@index([code])                                 // 索引：通过 code 快速查询
  @@index([primaryMuscle, difficulty, intentType]) // 复合索引：按肌群、难度、意图查询
  @@index([isActive])                             // 索引：快速筛选启用的动作
  @@map("exercises")                              // 数据库表名
}

// 主要肌群枚举 (定义动作主要锻炼的身体部位)
enum PrimaryMuscle {
  CHEST         // 胸部肌群 - 胸大肌、胸小肌等，如俯卧撑、胸部拉伸动作
  BACK          // 背部肌群 - 背阔肌、斜方肌、菱形肌等，如拉背、背部拉伸动作
  LEGS          // 腿部肌群 - 股四头肌、股二头肌、小腿肌群等，如深蹲、腿部拉伸
  GLUTES        // 臀部肌群 - 臀大肌、臀中肌等，如臀桥、臀部激活动作
  SHOULDERS     // 肩部肌群 - 三角肌前中后束等，如肩部拉伸、肩关节活动
  ARMS          // 手臂肌群 - 肱二头肌、肱三头肌、前臂肌群等，如手臂拉伸
  CORE          // 核心肌群 - 腹肌、腰背肌、深层稳定肌等，如平板支撑、腹部拉伸
  FULL_BODY     // 全身综合 - 涉及多个肌群的复合动作，如全身拉伸、综合训练
  NECK_SHOULDER // 颈肩部位 - 颈部肌群和肩颈交界处，如颈部拉伸、肩颈放松
}

// 运动意图类型枚举 (定义用户想要达到的训练效果)
enum IntentType {
  RELAX      // 放松模式 - 缓解肌肉紧张，降低压力，适合疲劳时或睡前
  STRETCH    // 拉伸模式 - 增加柔韧性，改善关节活动度，适合久坐后或运动前后
  MODERATE   // 适度运动 - 轻微提升心率，增加血液循环，适合日常健身维持
  STRENGTH   // 力量训练 - 增强肌肉力量和耐力，提升身体素质，适合有一定基础者
}

// 难度等级枚举 (定义动作的技术要求和强度水平)
enum Difficulty {
  BEGINNER      // 初级难度 - 动作简单，技术要求低，适合健身新手或身体基础较弱者
  INTERMEDIATE  // 中级难度 - 需要一定技巧，强度适中，适合有一定健身基础者
  ADVANCED      // 高级难度 - 技术要求高，强度较大，适合有丰富健身经验者
}

// 时长计量方式枚举 (定义动作的计量标准)
enum DurationType {
  TIME       // 按时间计量 - 以秒为单位，如"保持20秒"，适合静态拉伸、等长收缩
  REPS       // 按次数计量 - 以重复次数为单位，如"重复15次"，适合动态动作
}
```

---

### 4. 连接表 (Junction Tables) - 多对多关系表

```prisma
// 动作-场景关联表 (多对多关系)
model ExerciseScenario {
  exerciseId String   @map("exercise_id")          // 动作ID (外键，关联到Exercise表)
  exercise   Exercise @relation(fields: [exerciseId], references: [id], onDelete: Cascade)

  scenarioId String   @map("scenario_id")          // 场景ID (外键，关联到Scenario表)
  scenario   Scenario @relation(fields: [scenarioId], references: [id], onDelete: Cascade)

  createdAt  DateTime @default(now()) @map("created_at") @db.Timestamptz(6)  // 关联创建时间

  @@id([exerciseId, scenarioId])                   // 复合主键 (防止重复关联)
  @@index([scenarioId])                            // 索引：从场景查找动作时优化性能
  @@map("exercise_scenarios")                      // 数据库表名
}

// 动作-器材关联表 (多对多关系，支持必需/可选标记)
model ExerciseEquipment {
  exerciseId  String    @map("exercise_id")        // 动作ID (外键，关联到Exercise表)
  exercise    Exercise  @relation(fields: [exerciseId], references: [id], onDelete: Cascade)

  equipmentId String    @map("equipment_id")       // 器材ID (外键，关联到Equipment表)
  equipment   Equipment @relation(fields: [equipmentId], references: [id], onDelete: Cascade)

  isRequired  Boolean   @default(false) @map("is_required")  // 是否必需 (true=必需器材, false=可选器材)

  createdAt   DateTime  @default(now()) @map("created_at") @db.Timestamptz(6)  // 关联创建时间

  @@id([exerciseId, equipmentId])                  // 复合主键 (防止重复关联)
  @@index([equipmentId])                           // 索引：从器材查找动作时优化性能
  @@map("exercise_equipment")                      // 数据库表名
}
```

---

### 5. User 表 - 用户表 (简化版)

**设计说明**：
- 移除多语言偏好，前端根据系统语言自动设置
- 只保留核心统计字段

```prisma
model User {
  id        String   @id                           // 主键ID (使用Supabase Auth的UUID，不使用cuid)

  // 基本用户信息
  email     String?  @unique                       // 邮箱地址 (可选，支持匿名用户)
  name      String?                                // 用户昵称 (可选，用于个性化显示)
  avatarUrl String?  @map("avatar_url")            // 头像URL (可选，存储在Supabase Storage)

  // 统计数据 (冗余字段，提升查询性能)
  totalWorkouts    Int @default(0) @map("total_workouts")      // 总训练次数 (累计完成的训练会话数)
  totalDurationSec Int @default(0) @map("total_duration_sec")  // 总训练时长 (秒数，所有训练的累计时间)
  currentStreak    Int @default(0) @map("current_streak")      // 当前连续天数 (连续训练的天数，用于激励)
  longestStreak    Int @default(0) @map("longest_streak")      // 最长连续天数 (历史最高连续训练天数)

  // 用户偏好设置 (机器学习和个性化推荐)
  preferredIntents      IntentType[] @default([])             // 偏好的运动意图 (如 ["STRETCH", "RELAX"])
  preferredDifficulty   Difficulty?                           // 偏好难度 (可选，null表示自适应)
  preferredDuration     Int?         @map("preferred_duration") // 偏好训练时长 (秒数，null表示随意)
  avoidEquipment        String[]     @default([]) @map("avoid_equipment") // 避免的器材 (如用户不喜欢某些物件)

  // 通知设置
  streakReminder        Boolean  @default(true) @map("streak_reminder")      // 连击提醒开关
  themeWeekReminder     Boolean  @default(true) @map("theme_week_reminder")  // 主题周提醒开关
  quietHoursStart       String?  @map("quiet_hours_start")                  // 安静时段开始 (如 "22:00")
  quietHoursEnd         String?  @map("quiet_hours_end")                    // 安静时段结束 (如 "08:00")

  // 隐私设置
  hideRealPhotos        Boolean  @default(true) @map("hide_real_photos")     // 隐藏实拍背景 (默认开启)
  autoBlurFaces         Boolean  @default(true) @map("auto_blur_faces")      // 自动人脸模糊 (默认开启)
  allowDataSync         Boolean  @default(false) @map("allow_data_sync")     // 允许数据同步 (默认关闭)

  // 应用设置
  language              String   @default("zh") @map("language")             // 界面语言 (zh/en)
  theme                 String   @default("auto") @map("theme")              // 主题模式 (auto/light/dark)

  // 元数据字段
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz(6)  // 账户创建时间
  updatedAt DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)       // 最后更新时间

  // 数据库关系
  workoutSessions WorkoutSession[]                 // 用户的训练会话记录 (一对多关系)
  shareCards      ShareCard[]                      // 用户的分享卡片记录 (一对多关系)
  dailyTrainings  DailyTraining[]                  // 用户的每日训练记录 (一对多关系)
  userPreferences UserPreference[]                 // 用户的偏好学习记录 (一对多关系)
  themeWeekParticipations ThemeWeekParticipation[] // 用户的主题周参与记录 (一对多关系)

  @@index([email])                                 // 索引：邮箱查询优化
  @@map("users")                                   // 数据库表名
}
```

---

### 6. WorkoutSession 表 - 训练会话表 (简化版)

**设计说明**：
- 记录用户每次训练的完整信息
- 支持训练状态跟踪和用户反馈

```prisma
model WorkoutSession {
  id          String   @id @default(cuid())        // 主键ID (会话唯一标识符)
  userId      String   @map("user_id")             // 用户ID (外键，关联到User表)
  user        User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  // 用户选择的训练参数
  intentType    IntentType                         // 运动意图 (放松、拉伸、适度运动、力量训练)
  scenarioId    String?   @map("scenario_id")      // 场景ID (可选，外键关联到Scenario表)
  scenario      Scenario? @relation(fields: [scenarioId], references: [id])
  targetMuscles PrimaryMuscle[]                    // 目标肌群列表 (用户选择要锻炼的部位)

  // 训练配置参数
  totalDuration Int       @map("total_duration")   // 总时长设置 (秒数，用户设定的训练时间)
  difficulty    Difficulty                         // 难度等级 (初级、中级、高级)
  isSilent      Boolean   @default(false) @map("is_silent")  // 静音模式 (是否需要静音训练)

  // 训练状态跟踪
  status         SessionStatus @default(PENDING)   // 会话状态 (待开始、进行中、已完成、已放弃)
  startedAt      DateTime?     @map("started_at") @db.Timestamptz(6)   // 开始时间 (实际开始训练的时间)
  completedAt    DateTime?     @map("completed_at") @db.Timestamptz(6) // 完成时间 (训练结束的时间)
  actualDuration Int?          @map("actual_duration")       // 实际时长 (秒数，实际训练花费的时间)

  // 跟练模式和进度
  followMode     Boolean       @default(false) @map("follow_mode")     // 是否使用跟练模式 (true=引导跟练，false=自由练习)
  currentStep    Int           @default(0) @map("current_step")        // 当前跟练步骤 (0=未开始，1-3=动作序号)
  pauseCount     Int           @default(0) @map("pause_count")         // 暂停次数 (跟练过程中的暂停统计)
  skipCount      Int           @default(0) @map("skip_count")          // 跳过次数 (跳过动作的统计)

  // 训练环境和条件
  isOffline      Boolean       @default(false) @map("is_offline")      // 是否离线完成 (网络状态记录)
  ambientNoise   NoiseLevel?   @map("ambient_noise")                   // 环境噪音等级 (实际训练环境)
  usedSpace      SpaceSize?    @map("used_space")                      // 实际使用空间 (可能与计划不同)

  // 用户反馈
  rating   Int?                                    // 用户评分 (1-5星，训练后的满意度评价)
  feedback String? @db.VarChar(500)               // 用户反馈 (文字评价，最多500字符)

  // 元数据字段
  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz(6)  // 会话创建时间
  updatedAt DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)       // 最后更新时间

  // 数据库关系
  sessionExercises SessionExercise[]              // 本次会话包含的动作列表 (一对多关系)
  shareCard        ShareCard?                     // 本次会话生成的分享卡 (一对一关系，可选)

  @@index([userId, completedAt(sort: Desc)])      // 复合索引：用户训练历史查询优化
  @@index([status])                               // 索引：按状态筛选会话
  @@map("workout_sessions")                       // 数据库表名
}

// 训练会话状态枚举 (定义训练的进行状态)
enum SessionStatus {
  PENDING       // 待开始 - 已创建但尚未开始训练
  IN_PROGRESS   // 进行中 - 正在进行训练
  COMPLETED     // 已完成 - 训练成功完成
  ABANDONED     // 已放弃 - 中途退出或取消训练
}
```

---

### 7. SessionExercise 表 - 会话动作关联表

**设计说明**：
- 记录每次训练会话中包含的具体动作
- 支持动作完成状态跟踪

```prisma
model SessionExercise {
  id         String   @id @default(cuid())         // 主键ID (记录唯一标识符)

  sessionId  String   @map("session_id")           // 会话ID (外键，关联到WorkoutSession表)
  session    WorkoutSession @relation(fields: [sessionId], references: [id], onDelete: Cascade)

  exerciseId String   @map("exercise_id")          // 动作ID (外键，关联到Exercise表)
  exercise   Exercise @relation(fields: [exerciseId], references: [id])

  // 动作配置
  sequenceOrder Int      @map("sequence_order")    // 动作顺序 (在本次训练中的执行顺序，如1、2、3)
  duration      Int                                // 时长设置 (秒数或次数，根据durationType决定)
  sets          Int      @default(1)               // 组数 (动作重复的组数，通常1-3组)

  // 完成状态跟踪
  isCompleted    Boolean  @default(false) @map("is_completed")     // 是否完成 (标记该动作是否已完成)
  actualDuration Int?     @map("actual_duration")                 // 实际时长 (秒数，实际花费的时间)

  // 详细跟练数据
  startedAt      DateTime? @map("started_at") @db.Timestamptz(6)  // 动作开始时间 (具体到每个动作的开始)
  endedAt        DateTime? @map("ended_at") @db.Timestamptz(6)    // 动作结束时间 (具体到每个动作的结束)
  pausedTimes    Int       @default(0) @map("paused_times")       // 暂停次数 (该动作暂停的次数)
  skipReason     String?   @map("skip_reason")                    // 跳过原因 (如 "too_difficult", "no_space", "no_equipment")

  // 用户体验反馈
  difficultyFelt Difficulty? @map("difficulty_felt")             // 实际感受难度 (用户主观感受)
  comfortLevel   Int?        @map("comfort_level")               // 舒适度评分 (1-5分，动作舒适度)
  effectivenessRating Int?   @map("effectiveness_rating")        // 效果评分 (1-5分，动作有效性)

  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz(6)  // 记录创建时间

  @@unique([sessionId, sequenceOrder])            // 唯一约束：同一会话中动作顺序不能重复
  @@index([sessionId])                            // 索引：快速查询会话中的所有动作
  @@map("session_exercises")                      // 数据库表名
}
```

---

### 8. ShareCard 表 - 分享成果卡

**设计说明**：
- 用户完成训练后生成分享卡片
- 支持社交媒体分享（图片 + 文案）
- 记录分享数据用于统计

```prisma
model ShareCard {
  id          String   @id @default(cuid())         // 主键ID (分享卡唯一标识符)

  // 关联信息
  userId      String   @map("user_id")              // 用户ID (外键，关联到User表)
  user        User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  sessionId   String   @unique @map("session_id")   // 会话ID (外键，关联到WorkoutSession表，一个会话只能生成一张卡片)
  session     WorkoutSession @relation(fields: [sessionId], references: [id], onDelete: Cascade)

  // 卡片内容
  cardImageUrl    String   @map("card_image_url")   // 生成的卡片图片URL (存储在Supabase Storage)
  cardTemplate    String   @map("card_template")    // 使用的卡片模板 (如 "classic", "minimal", "vibrant")
  cardData        Json     @map("card_data")        // 卡片数据 (JSON格式，包含训练摘要、统计数据等)
                                                    // 格式: {"duration": 300, "exercises": 5, "calories": 120, "streak": 7}

  // 稀有度系统 (卡片收集核心功能)
  rarity          String   @map("rarity")           // 稀有度等级 ("COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY")
  equipmentSeries String   @map("equipment_series") // 器材系列 (如 "家具系", "墙面系", "瓶罐系"等)
  rarityScore     Float    @map("rarity_score")     // 稀有度分数 (0.0-1.0，基于全局使用频次计算)

  // 特殊标记和成就
  specialTags     String[] @default([]) @map("special_tags")     // 特殊标签 (如 ["静音完成", "连击Day7", "夜间模式"])
  cityEdition     String?  @map("city_edition")                  // 城市限定版本 (如 "Beijing", "Shanghai", 地理位置彩蛋)
  themeWeek       String?  @map("theme_week")                    // 主题周标记 (如 "椅子周", "水瓶周")

  // 分享配置
  shareText       String?  @map("share_text") @db.VarChar(500)  // 分享文案 (可自定义，可选)
  isPublic        Boolean  @default(true) @map("is_public")     // 是否公开 (true=允许他人查看，false=仅自己可见)

  // 分享统计
  shareCount      Int      @default(0) @map("share_count")      // 分享次数 (记录用户分享到社交平台的次数)
  viewCount       Int      @default(0) @map("view_count")       // 浏览次数 (他人查看该卡片的次数)

  // 元数据字段
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(6)  // 创建时间
  updatedAt   DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)       // 最后更新时间

  @@index([userId, createdAt(sort: Desc)])        // 复合索引：查询用户的分享历史
  @@index([isPublic])                             // 索引：筛选公开的分享卡
  @@map("share_cards")                            // 数据库表名
}
```

---

### 9. DailyTraining 表 - 每日训练记录

**设计说明**：
- 按日期聚合用户的训练数据
- 用于日历视图展示
- 支持连续打卡统计

```prisma
model DailyTraining {
  id          String   @id @default(cuid())         // 主键ID (每日记录唯一标识符)

  // 关联信息
  userId      String   @map("user_id")              // 用户ID (外键，关联到User表)
  user        User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  // 日期标识
  trainingDate  DateTime  @map("training_date") @db.Date  // 训练日期 (不含时间，用于日历展示，如 2024-10-30)

  // 当日统计数据
  totalSessions    Int   @default(0) @map("total_sessions")      // 当日完成的训练会话数
  totalDuration    Int   @default(0) @map("total_duration")      // 当日总训练时长 (秒数)
  totalExercises   Int   @default(0) @map("total_exercises")     // 当日完成的动作总数
  completedSessions Int  @default(0) @map("completed_sessions")  // 当日成功完成的会话数

  // 训练类型分布 (JSON格式，记录不同意图类型的时长)
  intentBreakdown  Json?  @map("intent_breakdown")   // 意图类型分布 (可选)
                                                     // 格式: {"RELAX": 300, "STRETCH": 600, "STRENGTH": 900}

  // 肌群训练分布 (JSON格式，记录不同肌群的训练次数)
  muscleBreakdown  Json?  @map("muscle_breakdown")   // 肌群分布 (可选)
                                                     // 格式: {"CHEST": 5, "BACK": 3, "LEGS": 7}

  // 成就标记
  isStreakDay      Boolean  @default(false) @map("is_streak_day")  // 是否为连续打卡日 (用于计算连续天数)
  achievements     String[] @default([])                            // 当日获得的成就标签 (如 ["first_workout", "5_day_streak"])

  // 元数据字段
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(6)  // 记录创建时间
  updatedAt   DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)       // 最后更新时间

  @@unique([userId, trainingDate])                    // 唯一约束：每个用户每天只有一条记录
  @@index([userId, trainingDate(sort: Desc)])         // 复合索引：查询用户的训练历史
  @@index([trainingDate])                             // 索引：按日期查询
  @@map("daily_trainings")                            // 数据库表名
}
```

---

### 10. EquipmentFrequency 表 - 器材使用频次统计 (稀有度计算)

**设计说明**：
- 统计全局器材使用频次，用于动态计算稀有度
- 按日期聚合，支持7日、30日频次查询
- 支持稀有度等级的动态调整

```prisma
model EquipmentFrequency {
  id          String   @id @default(cuid())         // 主键ID (统计记录唯一标识符)

  // 器材信息
  equipmentId String   @map("equipment_id")         // 器材ID (外键，关联到Equipment表)
  equipment   Equipment @relation(fields: [equipmentId], references: [id], onDelete: Cascade)

  equipmentCode String @map("equipment_code")       // 器材代码冗余 (便于快速查询，如 "chair", "wall")

  // 统计时间范围
  statisticsDate DateTime @map("statistics_date") @db.Date // 统计日期 (不含时间，如 2024-10-30)

  // 使用频次数据
  // dailyUsageCount    Int @default(0) @map("daily_usage_count")    // 当日使用次数
  // weeklyUsageCount   Int @default(0) @map("weekly_usage_count")   // 近7日累计使用次数
  // monthlyUsageCount  Int @default(0) @map("monthly_usage_count")  // 近30日累计使用次数

  // 全局统计
  // globalDailyRank    Int? @map("global_daily_rank")     // 当日全局排名 (1=最热门)
  // globalWeeklyRank   Int? @map("global_weekly_rank")    // 近7日全球排名

  // 稀有度计算结果
  rarityScore        Float @map("rarity_score")         // 稀有度分数 (0.0-1.0，1.0最稀有)
  rarityLevel        String @map("rarity_level")        // 稀有度等级 ("COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY")

  // 地区数据 (可选，用于城市限定版本)
  region             String? @map("region")              // 地区代码 (如 "Beijing", "Shanghai", 可选)

  // 元数据字段
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(6)  // 记录创建时间
  updatedAt   DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)       // 最后更新时间

  @@unique([equipmentId, statisticsDate])              // 唯一约束：每个器材每天只有一条统计记录
  @@unique([equipmentCode, statisticsDate])            // 唯一约束：按代码和日期
  @@index([statisticsDate])                            // 索引：按日期查询
  @@index([rarityLevel, statisticsDate])               // 索引：按稀有度等级查询
  @@index([globalWeeklyRank])                          // 索引：全球排名查询
  @@map("equipment_frequencies")                       // 数据库表名
}
```

---

### 11. UserPreference 表 - 用户偏好学习记录

**设计说明**：
- 记录用户的训练偏好和行为模式
- 用于个性化推荐和智能学习
- 支持机器学习算法优化

```prisma
model UserPreference {
  id          String   @id @default(cuid())         // 主键ID (偏好记录唯一标识符)

  // 关联信息
  userId      String   @map("user_id")              // 用户ID (外键，关联到User表)
  user        User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  // 偏好类型和数据
  preferenceType    String   @map("preference_type")     // 偏好类型 ("equipment", "intent", "difficulty", "duration", "scenario")
  preferenceKey     String   @map("preference_key")      // 偏好键 (如 "chair", "STRETCH", "BEGINNER")
  preferenceValue   Float    @map("preference_value")    // 偏好值 (0.0-1.0，值越大越偏好)

  // 统计数据
  usageCount        Int      @default(0) @map("usage_count")        // 使用次数
  successRate       Float    @default(0.0) @map("success_rate")     // 成功率 (完成训练的比例)
  averageRating     Float?   @map("average_rating")                 // 平均评分 (用户对该偏好的平均评分)

  // 时间窗口
  lastUsedAt        DateTime? @map("last_used_at") @db.Timestamptz(6)  // 最后使用时间
  firstUsedAt       DateTime  @map("first_used_at") @db.Timestamptz(6) // 首次使用时间

  // 元数据字段
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(6)  // 记录创建时间
  updatedAt   DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)       // 最后更新时间

  @@unique([userId, preferenceType, preferenceKey])    // 唯一约束：每个用户每种偏好类型的每个键只有一条记录
  @@index([userId, preferenceType])                    // 索引：查询用户特定类型的偏好
  @@index([preferenceValue(sort: Desc)])               // 索引：按偏好值排序
  @@map("user_preferences")                            // 数据库表名
}
```

---

### 12. ThemeWeek 表 - 主题周活动

**设计说明**：
- 管理主题周活动，如"椅子周"、"水瓶周"等
- 支持活动状态管理和进度追踪
- 用于首页主题周展示和用户激励

```prisma
model ThemeWeek {
  id          String   @id @default(cuid())         // 主键ID (主题周唯一标识符)

  // 主题周基本信息
  title       String                                // 主题周标题 (如 "椅子周", "水瓶周")
  code        String   @unique                      // 主题周代码 (如 "chair_week", "bottle_week")
  description String?  @db.VarChar(500)             // 主题周描述 (如 "用椅子动三下·完成掉贴纸皮肤")

  // 关联器材和动作
  equipmentCode String @map("equipment_code")       // 主题器材代码 (如 "chair", "bottle")
  targetExerciseCount Int @default(3) @map("target_exercise_count") // 目标动作数量 (默认3个)

  // 时间范围
  startDate   DateTime @map("start_date") @db.Date  // 开始日期 (如 2024-10-28)
  endDate     DateTime @map("end_date") @db.Date    // 结束日期 (如 2024-11-03)

  // 奖励设置
  rewardType  String   @map("reward_type")          // 奖励类型 ("skin", "badge", "rarity_boost")
  rewardData  Json?    @map("reward_data")          // 奖励数据 (JSON格式，包含具体奖励信息)
                                                    // 格式: {"skinName": "贴纸皮肤", "rarityBoost": 0.2}

  // 状态管理
  status      String   @default("UPCOMING")         // 状态 ("UPCOMING", "ACTIVE", "COMPLETED", "CANCELLED")
  isVisible   Boolean  @default(true) @map("is_visible")  // 是否在首页显示
  displayOrder Int     @default(0) @map("display_order")  // 显示顺序 (数字越小越靠前)

  // 参与统计 (冗余字段，提升查询性能)
  totalParticipants Int @default(0) @map("total_participants")     // 总参与人数
  totalCompletions  Int @default(0) @map("total_completions")      // 总完成人数
  completionRate    Float @default(0.0) @map("completion_rate")    // 完成率 (0.0-1.0)

  // 元数据字段
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(6)  // 创建时间
  updatedAt   DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)       // 最后更新时间

  // 数据库关系
  participations ThemeWeekParticipation[]   // 用户参与记录 (一对多关系)

  @@index([status, startDate])               // 索引：按状态和开始日期查询
  @@index([equipmentCode])                   // 索引：按器材代码查询
  @@index([displayOrder])                    // 索引：显示顺序查询
  @@map("theme_weeks")                       // 数据库表名
}
```

---

### 13. ThemeWeekParticipation 表 - 主题周参与记录

**设计说明**：
- 记录用户参与主题周的详细数据
- 跟踪完成进度和获得奖励
- 支持成就系统和用户激励

```prisma
model ThemeWeekParticipation {
  id          String   @id @default(cuid())         // 主键ID (参与记录唯一标识符)

  // 关联信息
  userId      String   @map("user_id")              // 用户ID (外键，关联到User表)
  user        User     @relation(fields: [userId], references: [id], onDelete: Cascade)

  themeWeekId String   @map("theme_week_id")        // 主题周ID (外键，关联到ThemeWeek表)
  themeWeek   ThemeWeek @relation(fields: [themeWeekId], references: [id], onDelete: Cascade)

  // 参与状态
  status      String   @default("JOINED")           // 参与状态 ("JOINED", "IN_PROGRESS", "COMPLETED", "FAILED")
  joinedAt    DateTime @default(now()) @map("joined_at") @db.Timestamptz(6)  // 加入时间
  completedAt DateTime? @map("completed_at") @db.Timestamptz(6)               // 完成时间 (可选)

  // 进度追踪
  exercisesCompleted Int @default(0) @map("exercises_completed")   // 已完成动作数量
  targetExercises    Int @map("target_exercises")                  // 目标动作数量 (冗余，便于查询)
  progressPercent    Float @default(0.0) @map("progress_percent")  // 完成百分比 (0.0-1.0)

  // 奖励记录
  rewardEarned       Boolean @default(false) @map("reward_earned")     // 是否获得奖励
  rewardClaimedAt    DateTime? @map("reward_claimed_at") @db.Timestamptz(6) // 奖励领取时间

  // 相关训练会话记录
  relatedSessions    String[] @default([]) @map("related_sessions")    // 相关训练会话ID列表

  // 元数据字段
  createdAt   DateTime @default(now()) @map("created_at") @db.Timestamptz(6)  // 记录创建时间
  updatedAt   DateTime @updatedAt @map("updated_at") @db.Timestamptz(6)       // 最后更新时间

  @@unique([userId, themeWeekId])                    // 唯一约束：每个用户每个主题周只能有一条参与记录
  @@index([themeWeekId, status])                     // 索引：按主题周和状态查询
  @@index([userId, status])                          // 索引：用户参与状态查询
  @@map("theme_week_participations")                 // 数据库表名
}
```

---

## 🎯 核心改进点

### ✅ 简化的地方

1. **移除多语言字段**
   - ❌ 之前: `nameEn`, `nameZh`, `nameEs`
   - ✅ 现在: `name`
   - 理由: 前端使用 i18n 库处理翻译更灵活

2. **可选字段更合理**
   - ❌ 之前: `noiseTolerance` 必填
   - ✅ 现在: `noiseTolerance?` 可选
   - 理由: 不是所有场景都需要噪音约束

3. **移除过度设计**
   - 移除 `CardSeries` 表 (MVP 不需要)
   - 移除 `UserStats` 表 (冗余数据存 User 表即可)
   - 移除 `EquipmentFrequency` 表 (可后期添加)
   - 移除复杂的评分系统

4. **JSON 字段合理化**
   - `description` 存储动作详情 (支持前端自定义格式)
   - 前端可以根据需要展示不同部分

### ✅ 保留的核心功能

- AI 识别配置 (核心功能)
- 多对多关系 (数据规范化)
- 时间戳使用 `Timestamptz(6)`
- RLS 策略支持
- 索引优化

---

## 📝 迁移命令

```bash
# 1. 生成 Prisma 客户端
npx prisma generate

# 2. 创建迁移
npx prisma migrate dev --name simplified_schema

# 3. 查看数据库
npx prisma studio
```

---

## 🔍 前端 i18n 示例

前端通过配置文件处理多语言：

```typescript
// locales/zh.json
{
  "scenarios": {
    "office": "办公室",
    "home": "家",
    "gym": "健身房"
  },
  "equipment": {
    "chair": "椅子",
    "wall": "墙",
    "bottle": "水瓶"
  }
}

// locales/en.json
{
  "scenarios": {
    "office": "Office",
    "home": "Home",
    "gym": "Gym"
  }
}
```

**使用方式**:
```typescript
// 前端代码
const scenarioName = t(`scenarios.${scenario.code}`)
// scenario.code = "office"
// zh: "办公室"
// en: "Office"
```

---

## 📊 表数量对比

| 版本 | 表数量 | 说明 |
|------|--------|------|
| v1.0 | 14张表 | 包含 CardSeries, UserStats, EquipmentFrequency 等 |
| **v2.0** | **14张表** | 移除非 MVP 必需表，简化设计，增加预留功能表 |

**MVP + 预留功能的 14 张表**:
1. `scenarios` - 场景表
2. `equipment` - 器材表
3. `exercises` - 动作表
4. `exercise_scenarios` - 动作-场景关联表
5. `exercise_equipment` - 动作-器材关联表
6. `users` - 用户表 (增加偏好设置、通知设置、隐私设置)
7. `workout_sessions` - 训练会话表 (增加跟练模式、环境数据)
8. `session_exercises` - 会话动作关联表 (增加详细跟练数据)
9. `share_cards` - 分享成果卡表 (增加稀有度系统) ⭐ 新增
10. `daily_trainings` - 每日训练记录表 ⭐ 新增
11. `equipment_frequencies` - 器材使用频次统计表 ⭐ 新增 (稀有度计算)
12. `user_preferences` - 用户偏好学习记录表 ⭐ 新增 (个性化推荐)
13. `theme_weeks` - 主题周活动表 ⭐ 新增 (主题周管理)
14. `theme_week_participations` - 主题周参与记录表 ⭐ 新增 (用户参与追踪)

---

## 🚀 下一步

1. ✅ 更新 `backend/prisma/schema.prisma`
2. ✅ 运行迁移创建表
3. ✅ 创建种子数据
4. 🔄 实现 API 端点
5. 🔄 前端接入

---

*SnapRep 数据库设计 v2.0 - 专业简化版*
*设计原则: 从 MVP 出发，避免过度设计*