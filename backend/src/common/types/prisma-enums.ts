/**
 * Prisma Enum Types
 * Manually defined enum types from the Prisma schema
 * This is a temporary solution until Prisma client generation is working
 */

// 训练会话状态
export enum SessionStatus {
  PENDING = 'PENDING',     // 待开始
  IN_PROGRESS = 'IN_PROGRESS', // 进行中
  COMPLETED = 'COMPLETED',     // 已完成
  ABANDONED = 'ABANDONED'      // 已放弃
}

// 运动意图（v3.0 统一）
export enum IntentType {
  RELAX = 'RELAX',       // 放松模式 - 缓解肌肉紧张
  STRETCH = 'STRETCH',   // 拉伸模式 - 增加柔韧性
  MODERATE = 'MODERATE', // 适度运动 - 轻微提升心率
  STRENGTH = 'STRENGTH'  // 力量训练 - 增强肌肉力量
}

// 难度等级（v3.0 改为颜色编码）
export enum Difficulty {
  GREEN = 'GREEN', // 简单 - 适合健身新手
  BLUE = 'BLUE',   // 中等 - 需要一定技巧
  RED = 'RED'      // 困难 - 技术要求高
}

// 主要肌群
export enum PrimaryMuscle {
  CHEST = 'CHEST',             // 胸部肌群
  BACK = 'BACK',               // 背部肌群
  LEGS = 'LEGS',               // 腿部肌群
  GLUTES = 'GLUTES',           // 臀部肌群
  SHOULDERS = 'SHOULDERS',     // 肩部肌群
  ARMS = 'ARMS',               // 手臂肌群
  CORE = 'CORE',               // 核心肌群
  FULL_BODY = 'FULL_BODY',     // 全身综合
  NECK_SHOULDER = 'NECK_SHOULDER' // 颈肩部位
}

// 稀有度等级（v3.0 升级为9档三层结构）
export enum RarityLevel {
  COMMON = 'COMMON',         // 常见 (≥8%使用率) - 灰白简洁
  UNCOMMON = 'UNCOMMON',     // 不常见 (3-8%) - 柔色渐变
  FINE = 'FINE',             // 细致 (1-3%) - 细微金属颗粒
  RARE = 'RARE',             // 稀有 (0.3-1%) - 斜向金属光泽
  ELITE = 'ELITE',           // 精英 (0.1-0.3%) - 细密拉丝金属
  EPIC = 'EPIC',             // 史诗 (0.03-0.1%) - 炫彩棱镜
  MYTHIC = 'MYTHIC',         // 神话 (0.01-0.03%) - 深色全息纹
  LEGENDARY = 'LEGENDARY',   // 传说 (0.003-0.01%) - 动态细闪+细纹
  APEX = 'APEX'              // 顶点 (<0.003% 且样本≥阈值) - 微动粒子/呼吸光
}

// 数据来源（v3.0 新增）
export enum DataSource {
  WEEKLY_TABLE = 'WEEKLY_TABLE',           // 权威周表数据（每周一更新）
  ON_THE_FLY_ESTIMATE = 'ON_THE_FLY_ESTIMATE' // 即时估算（仅供预览）
}

// 器材分类
export enum EquipmentCategory {
  NONE = 'NONE',           // 徒手/无器材
  FURNITURE = 'FURNITURE', // 家具系 - 椅子、沙发、桌子
  WALL = 'WALL',           // 墙面系 - 墙壁、门框
  BOTTLE = 'BOTTLE',       // 水瓶系 - 水瓶、饮料瓶
  BAG = 'BAG',             // 背包系 - 背包、手提包
  STAIRS = 'STAIRS',       // 台阶系 - 楼梯、台阶
  FABRIC = 'FABRIC',       // 布料系 - 毛巾、床单
  STICK = 'STICK',         // 棍棒系 - 扫把、拖把、雨伞
  OUTDOOR = 'OUTDOOR',     // 户外系 - 树木、长椅、石头
  CREATIVE = 'CREATIVE'    // 创意系 - 其他创意物品
}

// 噪音等级
export enum NoiseLevel {
  SILENT = 'SILENT', // 必须静音 - 适合办公室、图书馆
  QUIET = 'QUIET',   // 安静 - 适合酒店房间、宿舍
  NORMAL = 'NORMAL'  // 正常 - 适合家中、健身房
}

// 空间大小
export enum SpaceSize {
  SMALL = 'SMALL',   // 小空间 (1-2m²) - 如办公桌旁边
  MEDIUM = 'MEDIUM', // 中等 (2-4m²) - 如客厅一角
  LARGE = 'LARGE'    // 大空间 (>4m²) - 如公园、健身房
}

// 时长计量方式
export enum DurationType {
  TIME = 'TIME', // 按时间计量 - 以秒为单位
  REPS = 'REPS'  // 按次数计量 - 以重复次数为单位
}

// 深链目标类型（v3.0 新增）
export enum DeeplinkTargetType {
  WORKOUT_SESSION = 'WORKOUT_SESSION', // 训练会话
  THEME_WEEK = 'THEME_WEEK',           // 主题周
  SHARE_CARD = 'SHARE_CARD',           // 分享卡片
  EXERCISE = 'EXERCISE'                // 单个动作
}