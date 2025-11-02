# SnapRep 数据库架构一致性报告

> **生成时间**: 2024-10-30
> **版本**: v2.0 Simplified (MVP)
> **状态**: ✅ 三个文件完全一致

---

## 📋 文件列表

1. **[docs/db.md](../docs/db.md)** - 数据库设计文档（权威标准）
2. **[backend/prisma/schema.prisma](./prisma/schema.prisma)** - Prisma ORM 模式文件
3. **[backend/supabase_migration.sql](./supabase_migration.sql)** - Supabase SQL 迁移脚本

---

## ✅ 一致性验证

### 1. 枚举类型 (8个)

| Enum | db.md | schema.prisma | supabase_migration.sql |
|------|-------|---------------|------------------------|
| NoiseLevel | ✅ | ✅ | ✅ |
| SpaceSize | ✅ | ✅ | ✅ |
| EquipmentCategory | ✅ | ✅ | ✅ |
| PrimaryMuscle | ✅ | ✅ | ✅ |
| IntentType | ✅ | ✅ | ✅ |
| Difficulty | ✅ | ✅ | ✅ |
| DurationType | ✅ | ✅ | ✅ |
| SessionStatus | ✅ | ✅ | ✅ |

### 2. 数据表 (14个)

| 表名 | db.md | schema.prisma | supabase_migration.sql | 字段一致性 |
|------|-------|---------------|------------------------|------------|
| scenarios | ✅ | ✅ | ✅ | ✅ 100% |
| equipment | ✅ | ✅ | ✅ | ✅ 100% |
| exercises | ✅ | ✅ | ✅ | ✅ 100% (简化版) |
| exercise_scenarios | ✅ | ✅ | ✅ | ✅ 100% |
| exercise_equipment | ✅ | ✅ | ✅ | ✅ 100% |
| users | ✅ | ✅ | ✅ | ✅ 100% |
| workout_sessions | ✅ | ✅ | ✅ | ✅ 100% |
| session_exercises | ✅ | ✅ | ✅ | ✅ 100% |
| share_cards | ✅ | ✅ | ✅ | ✅ 100% |
| daily_trainings | ✅ | ✅ | ✅ | ✅ 100% |
| equipment_frequencies | ✅ | ✅ | ✅ | ✅ 100% (简化版) |
| user_preferences | ✅ | ✅ | ✅ | ✅ 100% |
| theme_weeks | ✅ | ✅ | ✅ | ✅ 100% |
| theme_week_participations | ✅ | ✅ | ✅ | ✅ 100% |

---

## 🎯 简化改进（v2.0 MVP）

### Exercise 表简化

**移除的字段**:
- ❌ `spaceRequirement` (SpaceSize)
- ❌ `noiseLevel` (NoiseLevel)
- ❌ `isSilent` (Boolean)

**理由**: 这些约束信息应该通过场景（Scenario）和器材（Equipment）的组合来隐式推断，而不是在每个动作上显式标记。

### EquipmentFrequency 表简化

**移除的字段**:
- ❌ `dailyUsageCount` (Int)
- ❌ `weeklyUsageCount` (Int)
- ❌ `monthlyUsageCount` (Int)
- ❌ `globalDailyRank` (Int)
- ❌ `globalWeeklyRank` (Int)

**保留的核心字段**:
- ✅ `rarityScore` (Float) - 稀有度分数
- ✅ `rarityLevel` (String) - 稀有度等级
- ✅ `statisticsDate` (Date) - 统计日期
- ✅ `region` (String?) - 地区标识

**理由**: MVP 阶段只需要核心的稀有度计算结果，详细的统计数据可以后期添加。

---

## 📊 架构统计

```
✅ 枚举类型: 8 个
✅ 数据表: 14 个
✅ 索引: 35+ 个
✅ 外键约束: 12 个
✅ Updated_at 触发器: 11 个
✅ RLS 策略: ~20 个
```

---

## 🔧 字段命名规范

### 数据库层（SQL/Supabase）
- 使用 `snake_case` 命名
- 示例: `created_at`, `user_id`, `noise_tolerance`

### Prisma 层（ORM）
- 使用 `camelCase` 命名
- 使用 `@map()` 映射到数据库字段
- 示例: `createdAt @map("created_at")`

### 应用层（前端/NestJS）
- 使用 `camelCase` 命名
- 通过 Prisma Client 自动映射
- 示例: `user.createdAt`, `scenario.noiseTolerance`

---

## 📝 数据类型映射

| Prisma 类型 | PostgreSQL 类型 | 说明 |
|------------|----------------|------|
| String | TEXT | 可变长度字符串 |
| String @db.VarChar(N) | VARCHAR(N) | 限定长度字符串 |
| Int | INTEGER | 32位整数 |
| Float | DOUBLE PRECISION | 双精度浮点数 |
| Boolean | BOOLEAN | 布尔值 |
| DateTime @db.Timestamptz(6) | TIMESTAMPTZ(6) | 带时区的时间戳（微秒精度） |
| DateTime @db.Date | DATE | 日期（不含时间） |
| Json | JSONB | 二进制JSON（支持索引） |
| String[] | TEXT[] | 文本数组 |
| Enum[] | "Enum"[] | 枚举数组 |

---

## 🚀 部署流程

### 1. 部署到 Supabase

```bash
# 打开 Supabase SQL Editor
# URL: https://app.supabase.com/project/tvjcmleckqovnieuexgu/sql

# 复制 backend/supabase_migration.sql 的全部内容
# 粘贴到 SQL Editor
# 点击 "Run" 执行
```

### 2. 验证 Prisma 同步

```bash
cd backend

# 生成 Prisma Client
npx prisma generate

# 从数据库拉取 schema（验证同步）
npx prisma db pull

# 打开 Prisma Studio 查看数据
npx prisma studio
```

### 3. 创建种子数据

```bash
# 创建种子脚本
npx prisma db seed

# 或手动插入基础数据
# - scenarios: office, home, gym, park
# - equipment: chair, wall, bottle, none
# - exercises: 初始动作库
```

---

## 🔒 Row Level Security (RLS) 策略

### 公开数据（只读）
- `scenarios` - 所有活跃场景
- `equipment` - 所有活跃器材
- `exercises` - 所有活跃动作
- `theme_weeks` - 所有可见主题周
- `equipment_frequencies` - 稀有度数据

### 用户私有数据
- `users` - 只能查看/更新自己的资料
- `workout_sessions` - 只能访问自己的训练会话
- `session_exercises` - 只能访问自己会话的动作
- `share_cards` - 可以查看自己的卡片或公开的卡片
- `daily_trainings` - 只能访问自己的每日记录
- `user_preferences` - 只能访问自己的偏好数据
- `theme_week_participations` - 只能访问自己的参与记录

---

## 📂 文件关系图

```
SnapRep/
├── docs/
│   └── db.md                          # 📘 权威设计文档（中文注释）
│
└── backend/
    ├── prisma/
    │   └── schema.prisma              # 🔧 Prisma ORM 模式
    │
    ├── supabase_migration.sql         # 🗄️ Supabase SQL 脚本
    │
    └── SCHEMA_CONSISTENCY_REPORT.md   # 📊 本文档
```

**同步原则**:
1. **db.md** 是权威标准，所有修改从这里开始
2. **schema.prisma** 根据 db.md 更新（手动同步）
3. **supabase_migration.sql** 根据 schema.prisma 生成（手动同步）

---

## ✅ 验证清单

- [x] 所有 8 个枚举类型一致
- [x] 所有 14 个表结构一致
- [x] Exercise 表移除了 space_requirement, noise_level, is_silent
- [x] EquipmentFrequency 表只保留核心字段
- [x] 所有字段名映射正确（snake_case ↔ camelCase）
- [x] 所有数据类型映射正确
- [x] 所有索引定义一致
- [x] 所有外键约束一致
- [x] 所有 RLS 策略定义正确
- [x] 注释和文档完整

---

## 📌 注意事项

1. **字段名约定**:
   - 数据库使用 `snake_case`
   - Prisma/应用层使用 `camelCase`
   - 使用 `@map()` 映射

2. **时间戳精度**:
   - 统一使用 `TIMESTAMPTZ(6)` （微秒精度）
   - 自动触发器管理 `updated_at`

3. **数组字段**:
   - Prisma: `String[]`
   - PostgreSQL: `TEXT[]`
   - 枚举数组: `"IntentType"[]`

4. **JSON 字段**:
   - Prisma: `Json`
   - PostgreSQL: `JSONB`（支持索引和查询）

5. **外键行为**:
   - 用户数据: `ON DELETE CASCADE`（删除用户时级联删除）
   - 场景关联: `ON DELETE SET NULL`（删除场景时设为null）
   - 动作关联: `ON DELETE RESTRICT`（防止删除被使用的动作）

---

## 🎉 总结

✅ **三个文件完全一致**，可以放心部署！

- [docs/db.md](../docs/db.md) - 设计标准 ✅
- [prisma/schema.prisma](./prisma/schema.prisma) - ORM 模式 ✅
- [supabase_migration.sql](./supabase_migration.sql) - SQL 迁移 ✅

**下一步**: 运行 `supabase_migration.sql` 在 Supabase 中创建数据库！

---

*SnapRep v2.0 Simplified - 从 MVP 出发，避免过度设计* 🚀
