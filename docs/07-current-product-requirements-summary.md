# SnapRep 当前项目需求总结（基于代码与最新 UI）

Date: 2026-05-06  
Status: Stage 1 takeover audit support document  
Scope: 基于当前仓库代码、已有文档、最新 UI 图片与已提交/未提交文件状态整理 SnapRep 的当前需求真相。  
Constraint: 本文档只总结 SnapRep 本项目，不代表迁移、改名、模板抽取、重写或新产品方向。

> 结论先行：`docs/architecture/业务流程.md` 不是当前最新需求文档。当前仓库没有一份同时覆盖“代码现状 + 最新 UI 更新 + 前后端闭环 + 待确认项”的完整 PRD。本文档作为当前阶段最贴近项目事实的需求总结与后续 PRD 基线。

---

## 1. 文档来源优先级

| Priority | Source | Usage |
|---:|---|---|
| 1 | `frontend/lib/main.dart` | 当前最新运行入口与最新 UI 闭环的强证据。 |
| 2 | `frontend/lib/features/profile/screens/cosmic_profile_pages.dart` | 最新“我的/卡片图鉴/卡片详情/分享”宇宙风 UI 的强证据。 |
| 3 | `docs/design/UI/2/*.png` | 2026-05-05 最新视觉稿证据，尤其是“训练动作”“卡片系统”“我的”系列。 |
| 4 | `docs/01-product-requirements-from-code.md` | 2026-05-03 代码反推需求基线，但未完全吸收 2026-05-05 UI 更新。 |
| 5 | `backend/prisma/schema.prisma`、`backend/src/**` | 后端领域模型、API、推荐、会话、卡片、挑战、订阅能力证据。 |
| 6 | `docs/architecture/业务流程.md`、`docs/frontend/前端流程设计.md`、`docs/design/claude页面设计.md` | 历史流程/设计参考；部分内容已过期或与当前实现不一致。 |

---

## 2. 当前项目总判断

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| `docs/architecture/业务流程.md` 是旧业务流程文档，不是最新需求文档。 | `docs/architecture/业务流程.md`; `frontend/lib/main.dart`; `frontend/lib/features/profile/screens/cosmic_profile_pages.dart`; `docs/design/UI/2/` | 如果继续把旧文档当唯一 PRD，会把已变化的 UI、入口、相机状态、卡片系统状态判断错。 | High | 将 `业务流程.md` 降级为历史参考；以后以本文档 + `docs/01-product-requirements-from-code.md` + 最新 UI 文件作为 Stage 1 基线。 |
| 当前最新 UI 很大程度集中在 `frontend/lib/main.dart` 的单文件闭环中。 | `frontend/lib/main.dart` | 最新 UI 和历史模块化 Flutter 页面并存，容易出现“看代码以为 A，运行却是 B”的认知偏差。 | High | Stage 2 前必须确认保留单文件 UI、回归模块化页面，还是做最小整合。待确认。 |
| “我的/卡片图鉴/详情/分享”最新版本在新增的 cosmic profile 页面中。 | `frontend/lib/features/profile/screens/cosmic_profile_pages.dart`; `docs/design/UI/2/我的-1.png`; `docs/design/UI/2/我的-2.png`; `docs/design/UI/2/我的-3.png`; `docs/design/UI/2/我的-4.png` | 个人中心从普通 profile 变成偏“卡片宇宙/收藏成长”的核心留存模块。 | Medium | 将 MyPage 需求升级为“卡片图鉴 + 成就 + 历史 + 分享/复刻入口”的核心模块。 |
| 当前依赖中没有 Riverpod，实际状态管理主要是 Provider/局部 StatefulWidget。 | `frontend/pubspec.yaml`; `frontend/lib/core/providers/*.dart`; `frontend/lib/main.dart` | 若需求文档继续写 Riverpod，会误导技术方案和验收。 | Medium | 现状文档写 Provider；Riverpod 只作为未来可选重构，非当前事实。 |
| 当前依赖中没有 Hive、Isar、SQLite 一线本地数据库依赖。 | `frontend/pubspec.yaml`; `backend/package.json` | “本地数据库闭环”目前不能写成已实现。 | High | 本地持久化现状写 shared_preferences/token/fallback；Hive/Isar/SQLite 标为待确认。 |
| 当前未发现 TensorFlow Lite 依赖或 `.tflite` 模型资产；旧文档称 TFLite 识别。 | `docs/architecture/业务流程.md`; `frontend/pubspec.yaml`; `backend/src/**` | AI 识别如果被当成已完成，会影响验收和发布承诺。 | High | 将 AI/TFLite 识别标为目标能力/待确认；当前实现按“相机视觉模拟 + 手选兜底 + API 预留”描述。 |
| `camera` 依赖被注释，当前相机体验更接近静态视觉模拟/拍照识别占位。 | `frontend/pubspec.yaml`; `frontend/lib/main.dart` | 真机相机权限、摄像头切换、TFLite 推理不能直接作为已实现验收项。 | High | Stage 1 验收只验证相机 fallback/模拟交互；Stage 2 再决定是否恢复真相机。 |
| 后端领域模型仍然是 SnapRep 产品闭环的重要依据。 | `backend/prisma/schema.prisma`; `backend/src/app.module.ts`; `backend/src/exercises/**`; `backend/src/workout-sessions/**`; `backend/src/cards/**` | 不能把当前前端静态闭环误判为产品全部；后端仍承载推荐、会话、卡片、挑战、订阅等业务。 | Medium | 后续整合时以 Prisma schema + API controllers 作为业务域地图。 |

---

## 3. 当前产品定位

SnapRep 是一个移动端随地健身应用。

**核心价值：**

> 用户可以在任何地点，用身边物品或无器械，快速生成并完成一组短训练，并获得可分享、可收藏、可复刻的成果卡片。

**产品关键词：**

- 60 秒快速开始
- 场景感知：家、办公室、旅途、户外等
- 物品感知：椅子、水瓶、背包、墙等
- 动作推荐：根据场景、物品、意图、目标部位生成训练
- 跟练闭环：推荐动作 → 开始训练 → 完成反馈
- 结果卡片：生成成果卡、稀有度、分享、收藏
- 我的页面：卡片图鉴、训练历史、成就、复刻
- 弱网/离线兜底：现有 fallback 能力存在，但完整 offline-first 待确认

---

## 4. 当前主用户闭环

### 4.1 当前最贴近代码与最新 UI 的闭环

```text
打开 SnapRep
→ Home / 首页
→ 选择 60 秒快速开始、场景、物品或相机入口
→ Guide Step 1：选择训练意图/训练模式
→ Guide Step 2：选择场景与可用物品，可跳转相机
→ Guide Step 3：选择目标身体部位
→ Workout Result：展示 3 个主动作与候选替换动作
→ Training Practice：进入跟练页，支持暂停、上一步、下一步
→ Result Card：展示成果卡与训练统计
→ My / Collection：查看收藏卡片、训练历史、卡片详情、分享页
```

### 4.2 历史文档中的扩展路径

以下路径在旧文档中存在，但当前是否完整接入最新 UI，需要进一步确认：

- 首页 → 物品挑战 → 挑战列表 → 动作结果 → 跟练 → 卡片
- 首页 → 拍照 AI 识别 → 识别结果确认 → 引导页
- 我的页面 → 历史训练/卡片详情 → 一键同款 → 动作结果
- 主题周 → 参与挑战 → 完成训练 → 卡片稀有度/主题加成
- 订阅/付费 → 解锁使用次数或高级能力

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| “首页 → Guide → Result → Practice → Card → My” 是当前最可信闭环。 | `frontend/lib/main.dart` | 可作为 Stage 1 核心验收路径。 | Low | 优先验证该闭环是否能稳定打开与操作。 |
| 物品挑战、主题周、订阅等路径在后端和历史模块中存在，但和最新 UI 的关系待确认。 | `backend/src/challenges/**`; `backend/src/theme-weeks/**`; `backend/src/subscription/**`; `frontend/lib/features/challenges/**`; `frontend/lib/main.dart` | 容易把未整合能力当作已完成主流程。 | Medium | 标为扩展能力；Stage 2 再决定是否纳入当前版本。 |

---

## 5. 页面级需求

### 5.1 Home / 首页

**目标：** 让用户最快进入训练，理解 SnapRep 的“随地、身边物品、60 秒”价值。

**当前需求：**

- 展示 SnapRep 品牌与 60 秒训练主 CTA。
- 提供训练意图/推荐入口。
- 展示场景卡片与物品卡片。
- 提供相机识别入口。
- 提供底部导航进入相机和我的页面。

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| 最新首页在 `frontend/lib/main.dart` 中以 `HomeScreen`/`HomeHero` 实现。 | `frontend/lib/main.dart` | 当前运行入口可能不再使用旧 `features/home/screens/home_page.dart`。 | Medium | 后续以当前运行入口为准核对 UI。 |
| 旧模块化首页仍存在，且使用 Provider/API 数据。 | `frontend/lib/features/home/screens/home_page.dart`; `frontend/lib/core/providers/home_provider.dart` | 存在双首页实现，容易产生维护分叉。 | High | Stage 2 前明确保留哪套首页，另一套归档或整合。待确认。 |

### 5.2 Camera / 相机识别

**目标：** 让用户通过“拍一下身边物品”快速进入物品训练，但手选仍是一等公民。

**当前需求：**

- 当前 UI 应支持相机页视觉、扫描框、识别态切换、识别结果 sheet。
- 当前验收应以“相机 fallback/模拟交互可用”为主。
- 真机拍照、权限、摄像头切换、TFLite 推理为待确认能力。

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| 当前相机页由静态图片与 UI 状态模拟识别。 | `frontend/lib/main.dart`; `frontend/assets/backup/old/camera_room_chair.png` | 能展示交互，但不能证明真实识别。 | High | 文档中不要写成“已完成 AI 识别”；写为“视觉/交互占位 + 待接真实识别”。 |
| `camera` 依赖被禁用，`image_picker` 仍存在。 | `frontend/pubspec.yaml` | 真实相机能力不可直接按旧文档验收。 | High | Stage 2 决定：恢复 camera、用 image_picker、还是保留手选优先。 |

### 5.3 Workout Guide / 训练引导

**目标：** 通过少量选择捕捉用户训练上下文，生成合适动作。

**当前需求：**

- Step 1：训练意图/训练模式，例如放松、拉伸、轻运动、力量等。
- Step 2：场景 + 物品选择，并允许稍后/相机辅助。
- Step 3：目标部位选择，例如全身、上肢、核心、下肢等。
- 选择完成后进入动作结果页。

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| 最新引导页在 `frontend/lib/main.dart` 中有 Step1/Step2/Step3。 | `frontend/lib/main.dart` | 当前闭环可不依赖旧路由体系完成。 | Medium | 用当前 Step 页面作为最新 UI 需求基线。 |
| 模块化路由中也存在 scenario/equipment/intent/body step 页面。 | `frontend/lib/routes/app_routes.dart`; `frontend/lib/features/workout_guide/screens/**` | 双实现会造成状态和接口分叉。 | High | Stage 2 做一次路由与页面归一化。待确认。 |

### 5.4 Workout Result / 动作推荐结果

**目标：** 展示本次训练动作组合，并允许用户开始跟练或生成成果卡。

**当前需求：**

- 展示 3 个主动作卡。
- 展示候选替换动作。
- 提供开始跟练入口。
- 提供直接生成/查看成果卡入口。
- 每个动作应包含动作名、目标、时长、强度、图片/视频预览。

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| 当前最新结果页在单文件 UI 中实现为 `WorkoutResultScreen`。 | `frontend/lib/main.dart` | 可作为最新视觉稿验收对象。 | Low | 核对 `docs/design/UI/2/训练动作-*.png` 与该页面差异。 |
| 后端也有推荐 API 与动作匹配服务。 | `backend/src/exercises/exercises.controller.ts`; `backend/src/exercises/services/workout-recommendation.service.ts`; `frontend/lib/core/services/api_service.dart` | 最新 UI 若只使用静态数据，会和后端闭环脱节。 | High | Stage 2 决定静态 UI 如何接回推荐 API。 |

### 5.5 Training Practice / 跟练页

**目标：** 用户能跟随动作完成训练。

**当前需求：**

- 展示当前动作图/视频视觉。
- 展示动作步骤、倒计时、进度。
- 支持暂停、上一个、下一个。
- 完成后应能进入成果卡。

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| 当前单文件 UI 中存在 `TrainingPracticeScreen`，支持 page、paused、previous/next 状态。 | `frontend/lib/main.dart` | 基础跟练交互可作为 Stage 1 前端闭环。 | Medium | 补齐“完成后自动到成果卡”的明确路径，待确认。 |
| 历史模块中存在专业视频跟练页。 | `frontend/lib/features/workout_execution/screens/professional_workout_video_page.dart`; `frontend/lib/features/workout_execution/screens/professional_workout_video_page_v2.dart` | 当前最新 UI 与旧视频页关系不明。 | Medium | Stage 2 选择复用视频页还是延续最新 UI。 |

### 5.6 Result Card / 成果卡

**目标：** 将训练结果转化为可分享、可收藏的视觉成果。

**当前需求：**

- 展示 9:16 或移动端友好的成果卡。
- 包含动作/物品/训练时长/消耗/稀有度/成就感元素。
- 支持分享。
- 支持收藏进入我的页面。

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| 当前单文件 UI 有 `ResultCardScreen`。 | `frontend/lib/main.dart` | 可作为最新成果卡视觉入口。 | Low | 和 `docs/design/UI/2/卡片系统.png` 对齐差异。 |
| 后端有 cards 模块、卡片生成、稀有度、分享统计等能力。 | `backend/src/cards/**`; `backend/prisma/schema.prisma` | 前端卡片若只静态显示，会缺失真实收藏/分享统计闭环。 | Medium | Stage 2 把成果卡生成与后端 card/session 数据对齐。 |

### 5.7 MyPage / 我的、图鉴、历史、分享

**目标：** 作为用户留存核心，展示训练成就、卡片收藏、历史记录和复刻入口。

**当前需求：**

- 展示个人主页与训练统计。
- 展示卡片图鉴/卡片集合。
- 展示卡片详情、故事、属性加成、分享页。
- 展示训练日历/历史入口。
- 支持从卡片或历史复刻训练。复刻是否已实现待确认。

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| 最新 MyPage 风格集中在 `cosmic_profile_pages.dart`。 | `frontend/lib/features/profile/screens/cosmic_profile_pages.dart`; `docs/design/UI/2/我的-*.png` | MyPage 已从普通资料页升级为卡片宇宙/收藏成长模块。 | Low | 以后需求中将 MyPage 作为核心闭环终点，而不是附属设置页。 |
| 旧 `MyPage` 和 provider 仍存在。 | `frontend/lib/features/profile/screens/my_page.dart`; `frontend/lib/core/providers/my_page_provider.dart` | 新旧个人中心能力可能割裂。 | Medium | Stage 2 对齐 cosmic UI 与真实 provider/API 数据。 |

---

## 6. 后端与数据需求

### 6.1 后端当前职责

后端应继续作为 SnapRep 的业务数据层与推荐/会话/卡片能力承载层。

**当前领域对象：**

- Scenario：训练场景
- Equipment：身边物品/器材
- Exercise：动作库
- WorkoutSession：训练会话
- SessionExercise：会话内动作
- ShareCard：成果卡/分享卡
- RarityTable：稀有度
- UserPreference：用户偏好
- ThemeWeek：主题周
- ChallengeItem / ChallengeCompletion：物品挑战
- Subscription / PaymentTransaction / DailyUsage：订阅与使用限制

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| Prisma schema 是当前最完整的领域模型图。 | `backend/prisma/schema.prisma` | 需求和接口重整时应以 schema 为主要事实源。 | Low | 后续需求评审逐模型确认哪些属于当前版本，哪些延期。 |
| 后端项目 metadata 仍带 starter 模板痕迹。 | `backend/package.json` | 新成员会误解项目身份。 | Medium | 审批后再清理 metadata；本文档阶段不改业务代码。 |

### 6.2 推荐算法需求

**输入：**

- scenario / scenarioCode
- equipment / equipmentCodes
- intent / intents
- targetMuscles
- duration
- difficulty
- themeWeekId
- excludeExerciseIds
- isOffline
- currentStep

**输出：**

- 推荐动作组合
- 训练会话
- 替换候选动作
- 后续卡片生成所需字段

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| 推荐 API 和 DTO 已支持多维参数。 | `frontend/lib/core/services/api_service.dart`; `backend/src/exercises/dto/exercise-recommendation.dto.ts`; `backend/src/exercises/services/workout-recommendation.service.ts` | 产品需求应保留“上下文个性化推荐”方向。 | Low | Stage 2 将最新 UI 的选择状态接回推荐 API。 |

---

## 7. 本地存储、离线与 fallback

### 7.1 当前事实

当前仓库证据支持：

- 使用 `shared_preferences` 保存轻量本地状态/token。
- 前端 provider 中存在 fallback/default data 机制。
- 部分结果页/卡片页在 API 失败时会创建 fallback 数据。

当前仓库证据不支持直接确认：

- Hive 已集成。
- Isar 已集成。
- SQLite/sqflite 已作为一线本地数据库。
- 完整 offline-first 数据同步已经完成。

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| `shared_preferences` 是当前明确存在的本地依赖。 | `frontend/pubspec.yaml`; `frontend/lib/core/services/token_service.dart` | 适合轻量 token/设置，不等价于完整离线数据库。 | Medium | 文档将本地存储写为 shared_preferences + fallback。 |
| fallback/default data 存在，但不是完整 offline-first。 | `frontend/lib/core/services/default_data_service.dart`; `frontend/lib/core/providers/home_provider.dart`; `frontend/lib/core/providers/workout_result_provider.dart`; `frontend/lib/core/providers/result_card_provider.dart` | 弱网可展示部分内容，但不能承诺完整闭环离线同步。 | High | 定义离线验收范围：哪些页面必须离线可用，哪些只提示网络。待确认。 |

---

## 8. AI 识别与相机需求边界

### 8.1 当前应写入需求的准确表述

当前 SnapRep 应支持：

- 相机入口和相机视觉体验。
- 识别成功/失败的 UI 状态。
- 识别失败后可手动选择物品继续。
- 后端/前端保留 AI recognition API 方向。

当前不能写成已完成：

- 真机 camera 依赖完整启用。
- TensorFlow Lite 模型已接入。
- 本地端侧推理已可用。
- AI 识别准确率已达到旧文档目标。

| finding | evidence file path | impact | risk level | recommended action |
|---|---|---|---|---|
| 旧文档把 TensorFlow Lite 写成架构能力，但当前代码依赖/资产证据不足。 | `docs/architecture/业务流程.md`; `frontend/pubspec.yaml`; `frontend/lib/main.dart` | 发布或验收时会产生能力错配。 | High | 将 TFLite 标为“目标能力/待确认”，先保留手选继续路径。 |
| API service 中存在 recognizeEquipment 请求入口。 | `frontend/lib/core/services/api_service.dart` | 表示产品曾规划 AI 识别接口，但不代表端侧模型完成。 | Medium | 后续检查后端是否存在 `/api/v1/ai/recognize-equipment` 实现。待确认。 |

---

## 9. 与旧文档的主要偏差

| Old statement | Current evidence | Current requirement |
|---|---|---|
| `业务流程.md` 是完整业务流程文档。 | 文件时间为 2025-11-21，晚于它的最新 UI 与入口文件已在 2026-05-05 变化。 | 它是历史参考，不是最新 PRD。 |
| 使用 TensorFlow Lite 做物体识别。 | 未发现一线 TFLite 依赖/模型资产；`camera` 依赖被注释。 | 当前只承诺相机视觉/fallback；真实识别待确认。 |
| 使用 Riverpod。 | `frontend/pubspec.yaml` 存在 provider，不存在 flutter_riverpod。 | 当前状态管理写 Provider/StatefulWidget。 |
| 本地数据库 Hive/Isar/SQLite。 | `frontend/pubspec.yaml` 未见相关依赖。 | 当前只写 shared_preferences + fallback；本地数据库待确认。 |
| MyPage 是普通个人中心。 | `cosmic_profile_pages.dart` 与最新 UI 图显示卡片宇宙/图鉴/分享增强。 | MyPage 是卡片收藏与留存核心。 |
| 前端主流程完全依赖模块化 routes。 | `frontend/lib/main.dart` 直接 `MaterialApp(home: AppShell())`。 | 当前最新运行 UI 可能绕开旧 routes，需要重新确认主入口。 |

---

## 10. 当前版本建议验收标准

### 10.1 Stage 1 必验路径

```text
启动 App
→ 首页可见
→ 点击“给我60秒”进入引导
→ 完成 Step 1 / Step 2 / Step 3
→ 进入动作结果页
→ 进入跟练页
→ 返回或完成到成果卡页
→ 进入我的页
→ 打开卡片图鉴
→ 打开卡片详情
→ 打开分享页
```

### 10.2 Stage 1 只做事实验证，不扩大承诺

| verification item | expected result | risk if failed |
|---|---|---|
| 最新 UI 入口能启动 | `frontend/lib/main.dart` 渲染 AppShell | High |
| 图片资产可加载 | `frontend/assets/images/**`、`frontend/assets/backup/old/**` 无缺失 | High |
| 底部导航可切换 Home / Camera / My | AppShell index 切换正常 | Medium |
| 相机模拟识别可切状态 | recognized false/true 交互正常 | Medium |
| Guide 三步能连到 Result | Navigator push 正常 | High |
| Result 能进入 Practice/Card | 训练闭环不中断 | High |
| My 能进入 Collection/Card detail/Share | 留存闭环不中断 | Medium |
| 后端 API 可启动 | NestJS + Prisma/Supabase 配置可用 | High |
| 推荐/会话/卡片 API 与前端真实接入程度 | 若未接入，必须记录为缺口 | High |

---

## 11. Stage 2 建议方向（非当前执行）

这些不是当前阶段要做的功能，只是基于现状的后续建议：

1. **确认唯一运行入口**
   - 决定当前 `frontend/lib/main.dart` 单文件 UI 是否作为新版主入口保留。
   - 若保留，需要把状态、API、路由逐步抽回模块化结构。

2. **统一新旧页面体系**
   - Home / Guide / Result / Card / My 都存在新旧实现。
   - Stage 2 应建立“当前页面清单”和“废弃页面清单”。

3. **把最新 UI 接回真实数据**
   - 场景、物品、动作推荐、训练会话、成果卡从后端 API 获取。
   - 静态数据只保留为 fallback。

4. **明确相机与 AI 策略**
   - 选项 A：恢复真机 camera + 后端识别 API。
   - 选项 B：使用 image_picker 上传照片识别。
   - 选项 C：短期保留手选优先，相机做视觉入口。
   - TensorFlow Lite 是否端侧推理待确认。

5. **明确本地数据库策略**
   - 若产品需要完整 offline-first，应选择 Hive/Isar/SQLite 之一。
   - 若只是弱网兜底，则 shared_preferences + default data 足够。

6. **卡片系统产品化**
   - 明确卡片稀有度、系列、属性加成、收藏、分享统计、复刻训练的最小闭环。

---

## 12. 当前需求基线摘要

SnapRep 当前最可信的需求基线是：

> 一个以 60 秒快速训练为入口、以场景/物品/身体部位选择为推荐上下文、以跟练完成和成果卡片为闭环、以“我的卡片图鉴/历史/分享”为留存核心的移动端随地健身应用。

当前不应承诺为已完成的能力：

- TensorFlow Lite 端侧 AI 识别
- Hive/Isar/SQLite 完整本地数据库
- Riverpod 状态管理
- 完整 offline-first 同步
- 最新 UI 与后端推荐/会话/卡片 API 已完全打通

这些能力可以作为 Stage 2/Stage 3 的确认与实施项，但不能在当前 PRD 中写成既成事实。

