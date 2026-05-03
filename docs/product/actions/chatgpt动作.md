下面把“场景 → 物品 → 动作”做成一套能直接落库与生成卡片的可执行方法。我分 3 部分回答：①先给出高频场景与物品优先级（别拍脑袋，用它当冷启动先验）；②给一套动作设计“配方法”（Capability-first，把物品能力映射到动作家族）；③给出可直接落库的模板与表结构（含示例 JSON），你一贴就能跑。

① 高频“使用场景 → 最可能出现的物品”（冷启动先验）

先用它做推荐先验；上线后用埋点实时更新每个场景的物品分布（Bayes 更新）。

场景	约束	最常见物品（按概率/可用性排序）
办公室工位	静音、小空间、衣着限制	椅子、墙面/门框、水杯/水瓶、桌沿/台阶、书/笔记本、毛巾/外套
客厅/卧室（居家）	空间中等	沙发/椅子、瑜伽垫/地毯、墙面/门框、水瓶/书、毛巾、台阶/凳
高铁/地铁/飞机	必须静音、常坐姿、稳态差	座椅、行李/背包、水瓶、墙面/隔板（锚点轻用）、书本
酒店房间	安静、空间中等	床沿/椅子、枕头/毛巾、行李箱、墙面/门框、水瓶
校园/宿舍	空间小到中等	床沿/椅子、书本/水瓶、墙面/门框、扫把/拖把（长杆）、毛巾
户外公园	可做稍大幅度	长椅、栏杆/单杠、台阶/矮墙、矿泉水、背包
公司走廊/会议前	强静音、1–2 分钟	墙面、椅子、门框、名片夹/水杯（小负重）
厨房/阳台	地面不可脏、可短时	台阶/门槛、墙面、瓶罐/米袋、抹布/毛巾

动作如何“从物品设计出来”：Capability-first 配方法

不是从“椅子/水瓶”出发，而是从“它能提供什么能力”出发。

A. 先给物品贴“能力标签”

支撑面（高度/稳固性）：椅面、台阶、桌沿、床沿、长椅

固定锚点（可轻拉/靠）：墙、门框、栏杆

即兴负重：水瓶（0.3–1.5kg）、书（0.5–2kg）、背包/行李（1–8kg）

弹性/非弹性牵引：弹力带、毛巾/床单

滚压放松：泡沫轴/球

垫子/护膝：地面舒适与防滑
并记录：噪音等级、稳定性、卫生约束、空间约束（站/坐/跪是否可行）。

B. 将“能力 → 动作家族（原子动作）”

支撑面：坐到站（Squat系）、踏步（Step-up）、臀桥、倾斜俯撑/靠墙俯撑、提踵、等长“早安式”

固定锚点：靠墙胸椎打开、墙天使、门框胸大肌拉伸、等长划船（毛巾夹门）

即兴负重：杯式抱物深蹲、抱物前推/前平举、单臂划船、罗马尼亚硬拉（小幅）、等长抗侧倾（Suitcase Hold）

弹性/非弹性：外旋/内旋、面对/背对划船、胸推、腘绳肌拉伸（PNF）、肩关节牵引

滚压：小腿/股四头/臀中肌/背阔肌滚压

垫类：跪撑/前臂撑（Bird-Dog、前臂平板）

C. 生成一张动作卡的 七步配方

读取约束：scene（静音/空间/卫生/稳定）+ capabilities

选家族：按意图（放松/舒展/适当运动/主体锻炼）选 1–2 个合适家族

定体位：坐姿 / 窄站 / 靠墙 / 倾斜（优先满足静音与空间）

定动作型：等长优先（静音场景）→ 小幅动态（可控 ROM）

定剂量：20s × 1（MVP），节拍/停顿（如 2-1-2，或等长）

④ 选卡算法落地（和你 PRD 的 S 公式对齐）

白名单过滤：scene 限制（静音/卫生/空间），只留匹配 tags 的模板；

候选池：objects ∩ user_objects ≠ ∅ 且 intent、view 匹配；

打分 S = 0.35适配 + 0.25覆盖 + 0.20安全 + 0.10多样性 + 0.10难度；

最大边际覆盖 选 3 张（尽量不同肌群/体位/动作型）；

微调：“更温和/更有感觉”仅在同模板家族里切 regression/progression，不跳家族。

⑤ 你接下来可以立刻做的三件事

把上面的先验与模板入库（3 张表即可跑）；

埋点：记录 scene/object 选择与识别结果 → 每周更新 scene_object_prior.prior_prob；

每类物品先做 8–12 个“金标模板”（照我给的 JSON 结构），优先覆盖 椅子、墙、瓶、包、沙发/床沿、台阶、毛巾、垫子 八大高频。

P0（必须改）— 直接支撑推荐引擎与安全锚点
1) 器材分类改为“功能导向”+ 能力字段（保留旧字段做兼容）

问题：当前 EquipmentCategory 把“户外/场景”与“器材功能”混在一起，导致匹配与扩展困难。
改法：新增功能导向枚举 EquipmentCategoryV2 + 能力字段，分两步迁移；旧枚举保留一段时间兼容前端。

// 新枚举（功能导向）
enum EquipmentCategoryV2 {
  BODYWEIGHT       // 徒手
  SUPPORT_SURFACE  // 支撑/踏步：椅/凳/台阶/沙发/床沿/地垫
  FIXED_ANCHOR     // 固定锚点：墙/门框/栏杆/横杆
  IMPROVISED_LOAD  // 即兴负重：水瓶/书/背包/行李箱/米袋
  ELASTIC_BAND     // 弹力带
  STRAP_FABRIC     // 毛巾/床单（非弹性牵引）
  STICK_POLE       // 扫把/拖把/雨伞/棍
  ROLLER_BALL      // 泡沫轴/按摩球
  BALL             // 球/药球
  MAT              // 垫类
  OTHER
}

// Equipment 增加能力字段（满足“配方”所需）
model Equipment {
  // ...原字段不动
  categoryV2         EquipmentCategoryV2? @map("category_v2")

  // 能力（能力优先匹配）
  providesLoad       Boolean   @default(false) @map("provides_load")
  loadMinKg          Float?    @map("load_min_kg")
  loadMaxKg          Float?    @map("load_max_kg")
  providesSupport    Boolean   @default(false) @map("provides_support")
  supportHeightCm    Float?    @map("support_height_cm")
  providesAnchor     Boolean   @default(false) @map("provides_anchor")
  anchorHeightCm     Float?    @map("anchor_height_cm")
  stability          String    @default("fixed")  // fixed/movable/flexible/unsteady
  hygiene            String    @default("ok")     // clean/ok/avoidFloor
  envTags            String[]  @default([])       // ['office','home','train','outdoor']
  subtypeTags        String[]  @default([])       // ['chair','bench','step','doorframe','bottle','bag',...]

  @@index([categoryV2])
  @@index([providesLoad, providesSupport, providesAnchor])
}


迁移步骤：

添加 category_v2 与能力字段；上线后后端优先读 category_v2。

编写一次性迁移脚本（根据 code/category 推断 category_v2 与能力值）；

前端逐步切到 category_v2；稳定后移除旧 category。

2) 新增：场景-物品“先验分布表”（Bayes 自学习）

问题：ScenarioEquipment 只有布尔“常见/偶见”，无法支持概率与随时间更新。
改法：新增 SceneObjectPrior（存概率与样本数，按周滚动）。

model SceneObjectPrior {
  id        String   @id @default(cuid())
  sceneCode String   // 'office' | 'home' | 'train' | ...
  equipmentCode String // 'chair' | 'wall' | 'bottle' | ...
  priorProb Float    // 0~1 冷启动先验+在线更新
  sampleSize Int     @default(0) // 样本量（用于置信度）
  windowStart DateTime @db.Date  // 统计窗口（如周一）
  source     String   @default("MIXED") // 'USER_SELECT' | 'VISION' | 'MIXED'

  createdAt DateTime @default(now()) @db.Timestamptz(6)
  updatedAt DateTime @updatedAt @db.Timestamptz(6)

  @@unique([sceneCode, equipmentCode, windowStart])
  @@index([sceneCode, windowStart])
  @@index([equipmentCode, windowStart])
  @@map("scene_object_prior")
}


行为埋点（手选/识别Top-k）每周聚合更新 priorProb，推荐打分 适配度 直接使用。

3) 把“金标动作模板”的关键字段显式化（避免只塞进 description JSON）

问题：现在 Exercise.description Json 包含要点/红线/禁忌，检索与排序困难。
改法：在 Exercise 增加可检索字段（仍保留原 JSON，便于 i18n）。

model Exercise {
  // ...原字段不动
  view           String[] @default([]) // ['seat','narrow-stand','wall','supine','quadruped','incline-push']
  cuesTop3       String[] @default([]) @map("cues_top3")            // 三要点
  redFlagsTop2   String[] @default([]) @map("red_flags_top2")       // 两红线
  contraindications String[] @default([]) @map("contraindications") // 禁忌
  regression     String?  // 回归
  progression    String?  // 进阶
  dose           Json?    // {"time_sec":20,"sets":1,"tempo":"2-1-2"}
  familyCode     String?  // 动作家族：如 'SQUAT_FAMILY','ROW_FAMILY'
  isSilentFriendly Boolean @default(true) @map("is_silent_friendly") // 静音友好
  spaceNeed      SpaceSize? @map("space_need")                        // 推荐空间需要

  // 用于 RAG/过滤
  objectTags     String[] @default([]) @map("object_tags") // ['chair','wall','bottle'...]
  postureTags    String[] @default([]) @map("posture_tags") // ['standing','seated','supine','prone','quadruped']

  @@index([intentType, difficulty])
  @@index([isSilentFriendly])
  @@index([familyCode])
}


这样推荐时可以：scene 过滤静音→ objectTags 命中 → familyCode 保强度“更温和/更有感觉”的同族切换。

4) Supabase Auth 对齐：User 表去掉本地密码，并与 auth.users 同步

问题：User.password 会与 Supabase Auth 冲突、带来合规风险。
改法：去除 password；email 变非唯一（允许多身份场景）；RLS 用 auth.uid()。

model User {
  id String @id @db.Uuid  // = auth.users.id
  email     String?       // 非唯一，作为冗余可读
  // password 字段删除
  // ...其余不变
  @@index([email])
}


RLS 提示（SQL 在 Supabase 控制台执行）：

alter table public.users enable row level security;

policy：using (id = auth.uid()) with check (id = auth.uid());

另设只读“金标内容表”（如 exercises）面向匿名可读的 policy。

P1（强烈建议）— 性能、检索与内容生产
5) 给多值字段加 GIN 索引（数组/JSON）

Prisma 不直接声明运算符类，使用 SQL 迁移：

-- tags / objectTags / postureTags / view / cuesTop3 等数组字段
create index if not exists idx_exercises_tags_gin on exercises using gin (tags);
create index if not exists idx_exercises_objtags_gin on exercises using gin (object_tags);
create index if not exists idx_exercises_view_gin on exercises using gin (view);

-- description / dose JSONB（若改为 JsonB）
-- create index if not exists idx_exercises_desc_gin on exercises using gin ((description jsonb_path_ops));

太对路了！按你给的「能力标签 → 动作家族」思路，我直接给你一套可落库的动作设计蓝本：先讲清“怎么从能力生成动作”，再给6 大能力场景 × 每类 4 个 = 24 个金标模板（每个含：三要点、两红线、剂量、回归/进阶），最后附可直接入库的 JSON 样例与一段TS 生成器，方便你批量产出模板。

0️⃣ 能力 → 家族 → 模板：生成规则（落地版）

识别可用能力（来自器材能力字段）：
providesSupport / providesAnchor / providesLoad / stability / spaceNeed / isSilentFriendly

映射到可用家族（白名单）：

支撑面 ↦ SQUAT_FAMILY / STEP_UP_FAMILY / PUSH_INCLINE_FAMILY / BRIDGE_FAMILY / CALF_FAMILY / HINGE_ISO_FAMILY

固定锚点 ↦ THORACIC_OPEN_FAMILY / WALL_MOBILITY_FAMILY / PEC_STRETCH_FAMILY / ROW_ISO_FAMILY

即兴负重 ↦ GOBLET_SQUAT_FAMILY / ROW_FAMILY / RDL_FAMILY / ANTI_LATERAL_FAMILY / PRESS_FAMILY

弹性/非弹性 ↦ ROTATOR_CUFF_FAMILY / ROW_BAND_FAMILY / PRESS_BAND_FAMILY / PNF_HAM_FAMILY / TRACTION_FAMILY

滚压 ↦ SMR_CALF / SMR_QUAD / SMR_GLUTE / SMR_LAT / T_EXT_ROLL

垫类 ↦ BIRD_DOG_FAMILY / PLANK_FAMILY / DEAD_BUG_FAMILY / SIDE_PLANK_FAMILY / BRIDGE_FAMILY

在家族内选“变式”：按 variantRank（-1 回归 / 0 基础 / +1 进阶），匹配 intentType/difficulty/isSilent/spaceNeed，并打分挑 3 张卡（你已有打分公式，可直接用）。

1️⃣ 支撑面（椅/台阶/桌沿/床沿）— 4 动作
1. 椅上坐到站（基础）

family: SQUAT_FAMILY｜肌群：LEGS/GLUTES → CORE｜意图/难度：STRENGTH / GREEN

剂量：20s×1（节奏 2-1-2），静音，小空间

三要点：脚尖膝盖同向；髋向后坐轻触椅沿；抬胸收紧核心

两红线：膝内扣；塌腰驼背

回归：半程坐立（椅更高）｜进阶：抱水瓶杯式坐到站（+0.5–2kg）

2. 台阶交替踏步

family: STEP_UP_FAMILY｜肌群：LEGS/GLUTES

剂量：左右交替 20s×1，静音（落脚轻）

三要点：整脚踏稳；发力膝不过度内收；上台阶髋伸直再下

两红线：踩边缘不稳；下台阶“跺”地

回归：低台阶/慢速｜进阶：抱书/水瓶

3. 桌沿倾斜俯撑

family: PUSH_INCLINE_FAMILY｜肌群：CHEST/SHOULDERS/CORE

剂量：20s×1，静音

三要点：身体成直线；肘略向后 45°；下去吸气上来呼气

两红线：耸肩挤颈；腰塌/撅臀

回归：墙推（站远一点）｜进阶：降低支撑高度（椅沿）

4. 椅后提踵

family: CALF_FAMILY｜肌群：CALVES

剂量：20s×1，静音

三要点：扶椅保平衡；脚跟下沉再蹬高峰停 1s；脚尖正前

两红线：外八内八发力；弹震蹬地

回归：小幅度｜进阶：单腿/抱书

2️⃣ 固定锚点（墙/门框/栏杆）— 4 动作
5. 靠墙胸椎打开

family: THORACIC_OPEN_FAMILY｜肌群：BACK（上背活动）

剂量：20s×1

三要点：臀背靠墙；呼气时胸骨上提；手肘向外打开

两红线：颈后仰；腰过度塌陷

回归：离墙 5–10cm｜进阶：加入上举滑动

6. 墙天使（Wall Angels）

family: WALL_MOBILITY_FAMILY｜肌群：SHOULDERS/UPPER BACK

剂量：20s×1

三要点：后脑勺/背/骨盆轻贴墙；肘腕尽量贴墙上滑；保持肋骨收

两红线：耸肩；腰代偿拱起

回归：坐姿做｜进阶：增加上举范围

7. 门框胸大肌拉伸

family: PEC_STRETCH_FAMILY｜肌群：CHEST（拉伸）

剂量：20s×1（每侧）

三要点：前臂贴门框；身体微转离开；肩远离耳朵

两红线：肘高于肩 过头拉；颈前伸

回归：角度小｜进阶：分三角度（下/平/上）

8. 门夹毛巾等长划船（安全锚）

family: ROW_ISO_FAMILY｜肌群：BACK/BICEPS/CORE

剂量：20s×1 等长用力

三要点：毛巾夹在门铰链侧关紧；肩胛向后下收；躯干中立

两红线：门未锁紧；猛拉后仰

回归：小力道｜进阶：半蹲位拉

3️⃣ 即兴负重（水瓶/书/背包/行李）— 4 动作
9. 杯式抱物深蹲（Goblet）

family: GOBLET_SQUAT_FAMILY｜肌群：LEGS/GLUTES/CORE

剂量：20s×1，负重 0.5–2kg

三要点：物贴胸；髋后坐再下蹲；核心收紧防塌

两红线：抱物远离胸；膝内扣

回归：空手｜进阶：背包 3–6kg

10. 背包划船

family: ROW_FAMILY｜肌群：BACK/BICEPS

剂量：20s×1

三要点：髋折 30–45°；背包贴身向髋拉；肩胛后下

两红线：耸肩牵拉；腰弓塌

回归：轻背包｜进阶：停顿 1s 顶峰

11. 小幅罗马尼亚硬拉（RDL）

family: RDL_FAMILY｜肌群：HAMSTRINGS/GLUTES

剂量：20s×1，负重轻

三要点：髋折主导，背直；沿腿下滑到腘绳轻拉感；髋伸站直

两红线：弯腰驼背；下放过深

回归：空手摸膝练幅度｜进阶：单手偏负重（防侧倾）

12. 单侧抗侧倾静力（Suitcase Hold）

family: ANTI_LATERAL_FAMILY｜肌群：CORE（斜腹/方肌）

剂量：每侧 20s×1

三要点：肩平；骨盆水平；身体不向负重侧倒

两红线：侧屈或塌腰；耸肩提包

回归：超轻瓶｜进阶：背包 4–8kg

4️⃣ 弹性/非弹性牵引（弹力带/毛巾）— 4 动作
13. 外旋（肩袖）

family: ROTATOR_CUFF_FAMILY｜肌群：SHOULDERS（深层）

剂量：20s×1（弹力最轻）

三要点：肘夹身体；旋转幅度小而控；肩远离耳

两红线：肘漂移；耸肩补偿

回归：毛巾等长轻拉｜进阶：站姿弹力带

14. 面对锚点划船（弹力带）

family: ROW_BAND_FAMILY｜肌群：BACK

剂量：20s×1

三要点：肩胛后下；手向肋部；全程肋骨收

两红线：猛拉弹震；腰代偿

回归：阻力更轻｜进阶：半蹲位

15. 胸前推（弹力带/毛巾绕柱）

family: PRESS_BAND_FAMILY｜肌群：CHEST/TRICEPS

剂量：20s×1

三要点：身体成直线；下放 2 秒上推 1 秒；手肘略外

两红线：带子锚不稳；耸肩推

回归：墙推｜进阶：单臂交替

16. 毛巾腘绳肌 PNF

family: PNF_HAM_FAMILY｜肌群：HAMSTRINGS（拉伸）

剂量：每侧 20s（10s 拉伸 + 5s 等长 + 5s 再拉）

三要点：小腿绕毛巾；膝尽量伸；骨盆中立

两红线：猛拽；腰抬离地

回归：常规静态拉伸｜进阶：踝背屈联动

5️⃣ 滚压放松（泡沫轴/球）— 4 动作
17. 小腿滚压

family: SMR_CALF｜意图：RELAX/STRETCH

剂量：20s/侧

三要点：从跟腱到腓肠全程；找到点位停 3–5s；轻深呼吸

两红线：压痛 >7/10；膝关节直接压

回归：靠墙球滚｜进阶：叠腿加压

18. 股四头滚压

family: SMR_QUAD｜剂量：20s/侧

三要点：俯卧支撑；从髋到膝上；慢速扫描

两红线：压髌骨；屏气紧张

回归：靠墙球｜进阶：边滚边屈伸膝

19. 臀中肌球点压

family: SMR_GLUTE｜剂量：20s/侧

三要点：侧后臀找结节；小范围点压；呼气放松

两红线：坐骨神经强烈放射痛；硬顶骨点

回归：泡沫轴大面｜进阶：更小更硬球

20. 胸椎伸展（轴下）

family: T_EXT_ROLL｜剂量：20s

三要点：轴横放肩胛下；双臂抱胸；轻微伸展

两红线：颈后仰；腰椎过伸

回归：毛巾垫｜进阶：双臂上举

6️⃣ 垫类/护膝（地面）— 4 动作
21. Bird-Dog（交替对侧伸展）

family: BIRD_DOG_FAMILY｜肌群：CORE/背伸肌

剂量：20s

三要点：脊柱中立；手脚远伸非上抬；骨盆稳

两红线：塌腰/耸肩；左右扭摆

回归：只伸手或脚｜进阶：顶峰停 2s

22. 前臂平板（基础）

family: PLANK_FAMILY｜肌群：CORE

剂量：20s

三要点：从耳→踝成直线；肋骨收；臀微夹

两红线：塌腰/撅臀；耸肩

回归：膝支撑｜进阶：肩触碰

23. Dead Bug（基础）

family: DEAD_BUG_FAMILY｜肌群：CORE

剂量：20s

三要点：腰背轻贴地；对侧伸展缓慢；呼气回收

两红线：腰离地；摆臂甩腿

回归：只动上肢或下肢｜进阶：抱水瓶

24. 仰卧臀桥

family: BRIDGE_FAMILY｜肌群：GLUTES/HAMSTRINGS

剂量：20s

三要点：脚跟踩地；髋伸直顶峰夹臀；肋骨不外翻

两红线：顶峰腰拱；内脚边受力

回归：短幅度｜进阶：单腿交替

可直接入库的 JSON（与你的 Exercise 模型字段对齐）
A. 椅上坐到站（基础）
{
  "code": "chair_box_squat_basic",
  "name": "椅上坐到站（基础）",
  "primaryMuscle": "LEGS",
  "secondaryMuscles": ["GLUTES", "CORE"],
  "intentType": "STRENGTH",
  "difficulty": "GREEN",
  "description": {
    "steps": ["站在椅前，双脚与肩同宽","吸气髋向后坐，轻触椅沿","呼气起身，站直"],
    "keyPoints": ["脚尖膝盖同向","髋主导下蹲，抬胸收紧核心","轻触椅沿不坐实"],
    "warnings": ["膝内扣","塌腰驼背"],
    "breath": "下蹲吸气，上起呼气"
  },
  "defaultDuration": 20,
  "defaultSets": 1,
  "durationType": "TIME",
  "tags": ["静音","小空间","办公室适用"],
  "objectTags": ["chair"],
  "postureTags": ["standing"],
  "cuesTop3": ["脚尖膝盖同向","髋向后坐到椅沿","抬胸收紧核心"],
  "redFlagsTop2": ["膝内扣","塌腰驼背"],
  "contraindications": ["膝急性疼痛","近期腰伤"],
  "dose": {"time_sec": 20, "sets": 1, "tempo": "2-1-2"},
  "familyCode": "SQUAT_FAMILY",
  "variantRank": 0,
  "isSilentFriendly": true,
  "spaceNeed": "SMALL",
  "view": ["seat","hip-hinge"]
}

B. 水瓶前平举
{
  "code": "bottle_front_raise",
  "name": "水瓶前平举",
  "primaryMuscle": "SHOULDERS",
  "secondaryMuscles": ["CORE"],
  "intentType": "MODERATE",
  "difficulty": "GREEN",
  "description": {
    "steps": ["双手各持水瓶于大腿前","抬至肩高略低停1秒","控制放下至起点"],
    "keyPoints": ["肘微屈","肩远离耳朵","全程肋骨收"],
    "warnings": ["耸肩代偿","摆臂借力"]
  },
  "defaultDuration": 20,
  "defaultSets": 1,
  "durationType": "TIME",
  "tags": ["静音","小空间"],
  "objectTags": ["bottle","book"],
  "postureTags": ["standing"],
  "cuesTop3": ["肘微屈不锁死","肩远离耳朵","抬至肩高略低"],
  "redFlagsTop2": ["耸肩","摆臂借力"],
  "contraindications": ["肩急性疼痛"],
  "dose": {"time_sec": 20, "sets": 1, "tempo": "2-1-2"},
  "familyCode": "PRESS_FAMILY",
  "variantRank": 0,
  "isSilentFriendly": true,
  "spaceNeed": "SMALL",
  "view": ["narrow-stand"]
}

C. 门夹毛巾等长划船（安全锚）
{
  "code": "door_towel_iso_row",
  "name": "门夹毛巾等长划船",
  "primaryMuscle": "BACK",
  "secondaryMuscles": ["ARMS","CORE"],
  "intentType": "STRENGTH",
  "difficulty": "GREEN",
  "description": {
    "steps": ["将毛巾夹在门铰链侧并关紧","握住两端后坐半步感受拉力","保持肩胛后下收缩等长用力"],
    "keyPoints": ["选择门铰链侧并锁门","肩胛后下收不耸肩","躯干中立不后仰"],
    "warnings": ["门未锁紧禁止使用","猛拉后仰易失稳"]
  },
  "defaultDuration": 20,
  "defaultSets": 1,
  "durationType": "TIME",
  "tags": ["静音","小空间","家中/酒店"],
  "objectTags": ["doorframe","towel"],
  "postureTags": ["lean-back"],
  "cuesTop3": ["门铰链侧锁紧","肩胛后下收","躯干中立"],
  "redFlagsTop2": ["未锁门","猛拉后仰"],
  "contraindications": ["肩前侧疼痛急性期"],
  "dose": {"time_sec": 20, "sets": 1, "tempo": "iso-hold"},
  "familyCode": "ROW_ISO_FAMILY",
  "variantRank": 0,
  "isSilentFriendly": true,
  "spaceNeed": "SMALL",
  "view": ["door-anchor"]
}


其余 21 个按同结构录入即可（建议用你后端的 ExerciseI18n 作多语言拆分）。

3️⃣ 批量产模板的小工具（TypeScript 生成器）
type Difficulty = "GREEN" | "BLUE" | "RED";
type IntentType = "RELAX" | "STRETCH" | "MODERATE" | "STRENGTH";

interface ExerciseInput {
  code: string;
  name: string;
  familyCode: string;
  primaryMuscle: string;
  secondaryMuscles?: string[];
  intentType: IntentType;
  difficulty: Difficulty;
  objectTags: string[];
  postureTags: string[];
  isSilentFriendly?: boolean;
  spaceNeed?: "SMALL" | "MEDIUM" | "LARGE";
  cuesTop3: string[];
  redFlagsTop2: string[];
  contraindications?: string[];
  steps: string[];
  dose?: { time_sec?: number; reps?: number; sets: number; tempo?: string };
  variantRank?: number;
  tags?: string[];
  view?: string[];
}

export function makeExercise(e: ExerciseInput) {
  return {
    code: e.code,
    name: e.name,
    primaryMuscle: e.primaryMuscle,
    secondaryMuscles: e.secondaryMuscles ?? [],
    intentType: e.intentType,
    difficulty: e.difficulty,
    description: {
      steps: e.steps,
      keyPoints: e.cuesTop3,
      warnings: e.redFlagsTop2
    },
    defaultDuration: e.dose?.time_sec ?? (e.dose?.reps ? e.dose.reps : 20),
    defaultSets: e.dose?.sets ?? 1,
    durationType: e.dose?.reps ? "REPS" : "TIME",
    tags: e.tags ?? [],
    objectTags: e.objectTags,
    postureTags: e.postureTags,
    cuesTop3: e.cuesTop3,
    redFlagsTop2: e.redFlagsTop2,
    contraindications: e.contraindications ?? [],
    dose: {
      time_sec: e.dose?.time_sec,
      reps: e.dose?.reps,
      sets: e.dose?.sets ?? 1,
      tempo: e.dose?.tempo ?? "2-1-2"
    },
    familyCode: e.familyCode,
    variantRank: e.variantRank ?? 0,
    isSilentFriendly: e.isSilentFriendly ?? true,
    spaceNeed: e.spaceNeed ?? "SMALL",
    view: e.view ?? []
  };
}