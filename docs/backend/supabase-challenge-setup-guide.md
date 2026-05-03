# Supabase 挑战系统数据生成指南

## 问题背景
在 Supabase 中执行 `challenge_items` 表插入时遇到外键约束错误，因为引用的 `equipment_id` 在 `equipment` 表中不存在。当前 Supabase 中只有一条 equipment 记录。

## 解决方案
采用分步执行的方式，确保按照正确的依赖顺序插入数据。

## 执行步骤

**⚠️ 重要更新**: 如果之前执行过程中遇到错误，请使用修复后的 `step3-simple-challenge-completions.sql` 文件。

### 步骤 1: 生成 Equipment 数据
**文件**: `backend/sql/step1-equipment-data.sql`

```bash
# 在 Supabase SQL Editor 中执行
```

**此步骤会**:
- 保留现有的 equipment 记录 (`cuid_1762866203978_r6v3npx7i`)
- 插入 20 个新的器材记录，涵盖所有类别
- 验证插入结果并显示统计信息

**预期结果**:
- Equipment 表应该有 21 条记录（包括原有的 1 条）
- 覆盖 NONE, FURNITURE, WALL, BOTTLE, BAG, STAIRS, FABRIC, STICK, OUTDOOR, CREATIVE 等类别

### 步骤 2: 生成 Challenge Items 数据
**文件**: `backend/sql/step2-challenge-data.sql`

```bash
# 在 Supabase SQL Editor 中执行（必须在步骤1完成后）
```

**此步骤会**:
- 验证 equipment 表是否有足够的数据
- 插入 12 个挑战项目，引用步骤1中创建的器材
- 显示挑战与器材的关联关系

**预期结果**:
- challenge_items 表应该有 12 条记录
- 每个挑战都正确关联到对应的器材

### 步骤 3: 生成 Challenge Completions 数据
**文件**: `backend/sql/step3-simple-challenge-completions.sql`

```bash
# 在 Supabase SQL Editor 中执行（必须在步骤1和2完成后）
```

**此步骤会**:
- 验证前置数据（equipment, challenge_items, users）
- ✅ **使用你现有的用户数据** (Alice, Bob, Charlie, 高级用户等)
- 为现有用户生成 14 条真实的挑战完成记录
- 包含各种状态：COMPLETED, IN_PROGRESS, STARTED, ABANDONED
- 显示完成统计和用户参与情况

**预期结果**:
- challenge_completions 表应该有 14 条记录
- 使用你实际的用户 ID，无需创建新用户
- 包含多种完成状态和真实用户反馈

**用户映射**:
- Alice (`550e8400-e29b-41d4-a716-446655440003`): 4条记录
- Bob (`550e8400-e29b-41d4-a716-446655440004`): 4条记录
- Charlie (`550e8400-e29b-41d4-a716-446655440005`): 3条记录
- 高级用户 (`550e8400-e29b-41d4-a716-446655440008`): 3条记录

## 数据概览

### Equipment 类别
| 类别 | 器材数量 | 示例 |
|------|----------|------|
| NONE | 1 | 无器材 |
| FURNITURE | 4 | 椅子、沙发、桌子、床 |
| WALL | 2 | 墙面、门框 |
| BOTTLE | 2 | 水瓶、酒瓶 |
| BAG | 3 | 背包、手提包、行李箱 |
| STAIRS | 2 | 楼梯、长椅 |
| FABRIC | 1 | 毛巾 |
| STICK | 2 | 雨伞、拖把 |
| OUTDOOR | 2 | 树木、石头 |
| CREATIVE | 1 | 书本 |

### Challenge Items 设计
| 难度级别 | 挑战数量 | 特点 |
|----------|----------|------|
| Easy (Row 1) | 4 | 基础器材，适合初学者 |
| Medium (Row 2) | 4 | 中等难度，需要一定技巧 |
| Hard (Row 3) | 4 | 高难度，挑战性强 |

## 注意事项

### 1. 执行顺序
⚠️ **严格按照步骤 1 → 2 → 3 的顺序执行，不可跳跃或颠倒**

### 2. 错误处理
如果执行过程中出现错误：

```sql
-- 检查 equipment 表数据
SELECT COUNT(*), STRING_AGG(DISTINCT category::text, ', ') as categories FROM equipment;

-- 检查 challenge_items 表数据
SELECT COUNT(*), STRING_AGG(title, ', ') as challenges FROM challenge_items;

-- 检查外键约束
SELECT ci.title, e.name
FROM challenge_items ci
LEFT JOIN equipment e ON ci.equipment_id = e.id
WHERE e.id IS NULL; -- 应该返回空结果
```

### 3. 数据清理
如果需要重新执行：

```sql
-- 按依赖关系逆序删除
DELETE FROM challenge_completions;
DELETE FROM challenge_items;
-- 注意：建议保留 equipment 数据，除非确定要完全重新开始
```

### 4. 用户数据
步骤 3 需要 users 表中有数据。如果 users 表为空，请先添加一些测试用户：

```sql
-- 添加测试用户（如果需要）
INSERT INTO users (id, email, name) VALUES
  ('550e8400-e29b-41d4-a716-446655440002', 'test@example.com', 'Test User'),
  ('550e8400-e29b-41d4-a716-446655440003', 'alice@example.com', 'Alice'),
  ('550e8400-e29b-41d4-a716-446655440004', 'bob@example.com', 'Bob')
ON CONFLICT (email) DO NOTHING;
```

## 验证完成

执行完所有步骤后，运行以下查询验证数据完整性：

```sql
-- 整体数据统计
SELECT
  'Equipment' as table_name, COUNT(*) as count FROM equipment
UNION ALL
SELECT 'Challenge Items', COUNT(*) FROM challenge_items
UNION ALL
SELECT 'Challenge Completions', COUNT(*) FROM challenge_completions;

-- 外键关系验证
SELECT
  ci.title,
  e.name as equipment_name,
  COUNT(cc.*) as completion_count
FROM challenge_items ci
JOIN equipment e ON ci.equipment_id = e.id
LEFT JOIN challenge_completions cc ON ci.id = cc.challenge_item_id
GROUP BY ci.id, ci.title, e.name
ORDER BY ci.display_order;
```

## 故障排除

### 常见错误
1. **外键约束错误**: 确保先执行步骤1
2. **用户ID不存在**: 确保 users 表有数据
3. **类型不匹配**: 确保 PostgreSQL enum 类型已正确创建

### 联系支持
如果遇到问题，请检查：
1. SQL 执行顺序是否正确
2. 错误消息中的具体表名和约束名
3. 数据库中已有的数据结构

---

**创建日期**: 2025-01-19
**最后更新**: 2025-01-19
**适用版本**: SnapRep v3.1 Challenge System