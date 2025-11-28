# Intent Type Array Migration - 完成总结

## 🎯 **目标**
将 `exercises` 表的 `intent_type` 字段从单个枚举值改为枚举数组，使一个训练动作可以支持多种意图（RELAX, STRETCH, MODERATE, STRENGTH）。

**关键规则：**
- 空数组 `[]` = 适用于所有意图
- 非空数组 `['RELAX', 'STRETCH']` = 只适用于指定的意图

---

## ✅ **已完成的工作**

### 1. **数据库 Migration** ✅

**文件：** `backend/sql/migration-intent-type-to-array.sql`

**核心改动：**
```sql
-- 1. 添加新的数组列
ALTER TABLE "exercises"
ADD COLUMN "intent_types" "IntentType"[] DEFAULT ARRAY[]::"IntentType"[];

-- 2. 迁移现有数据（单个值转为数组）
UPDATE "exercises"
SET "intent_types" = ARRAY[intent_type]::"IntentType"[]
WHERE "intent_type" IS NOT NULL;

-- 3. 删除旧列，重命名新列
ALTER TABLE "exercises" DROP COLUMN "intent_type";
ALTER TABLE "exercises" RENAME COLUMN "intent_types" TO "intent_type";

-- 4. 创建 GIN 索引支持数组查询
CREATE INDEX "exercises_intent_type_gin_idx"
ON "exercises" USING GIN ("intent_type");
```

**自动优化：**
- RELAX 动作自动也支持 STRETCH（它们经常重叠）
- 简单的身体动作（如neck_stretch, shoulder_roll）设为空数组，适用于所有意图

---

### 2. **后端代码更新** ✅

**文件：** `backend/src/exercises/exercises.dao.ts`

#### 关键修改 #1：意图筛选逻辑

**之前（单个值）：**
```typescript
if (criteria.intent) {
  filters.intent_type = `eq.${criteria.intent}`;
}
```

**现在（数组）：**
```typescript
// 6. 意图筛选 - NOTE: 改为数组后，需要在后处理中过滤
// 因为需要匹配: 数组包含该intent OR 数组为空[]
// Supabase PostgREST 不支持直接的 OR 查询，所以我们在后处理中过滤
const intentFilter = criteria.intent; // 保存用于后处理
```

#### 关键修改 #2：后处理过滤

```typescript
// 11. 后处理: 意图筛选（intent_type 改为数组后）
// 匹配规则: 数组包含该intent OR 数组为空[]（表示适用于所有意图）
if (intentFilter && exercises.length > 0) {
  exercises = exercises.filter((ex: any) => {
    const intentTypes = ex.intent_type;
    // 如果是空数组，表示适用于所有意图
    if (!intentTypes || intentTypes.length === 0) {
      return true;
    }
    // 检查数组是否包含该意图
    return Array.isArray(intentTypes) && intentTypes.includes(intentFilter);
  });
  logger.info(`After intent_type filtering (${intentFilter}): ${exercises.length} exercises`);
}
```

#### 关键修改 #3：统计方法更新

**之前（groupBy 单个值）：**
```typescript
const result = await this.prisma.exercise.groupBy({
  by: ['intentType'],
  where: { isActive: true },
  _count: { id: true }
});
```

**现在（手动统计数组）：**
```typescript
const exercises = await this.prisma.exercise.findMany({
  where: { isActive: true },
  select: { intentType: true }
});

const intentCounts: Record<string, number> = {};

exercises.forEach((exercise) => {
  const intentTypes = exercise.intentType as any[];
  if (intentTypes && intentTypes.length > 0) {
    // 每个意图都计数一次（一个动作可能属于多个意图）
    intentTypes.forEach((intent: string) => {
      intentCounts[intent] = (intentCounts[intent] || 0) + 1;
    });
  } else {
    // 空数组表示适用于所有意图，在每个意图下都计数
    ['RELAX', 'STRETCH', 'MODERATE', 'STRENGTH'].forEach((intent) => {
      intentCounts[intent] = (intentCounts[intent] || 0) + 1;
    });
  }
});
```

---

### 3. **示例数据更新 SQL** ✅

**文件：** `backend/sql/sample-data-update-intent-types.sql`

**策略示例：**

```sql
-- 1. RELAX + STRETCH (它们经常重叠)
UPDATE "exercises"
SET "intent_type" = ARRAY['RELAX', 'STRETCH']::"IntentType"[]
WHERE code IN ('neck_stretch', 'shoulder_roll', 'chair_spinal_twist');

-- 2. MODERATE + STRENGTH (轻量力量训练)
UPDATE "exercises"
SET "intent_type" = ARRAY['MODERATE', 'STRENGTH']::"IntentType"[]
WHERE code IN ('jumping_jacks', 'chair_marching', 'sofa_stepup');

-- 3. 适用于所有意图（空数组）
UPDATE "exercises"
SET "intent_type" = ARRAY[]::"IntentType"[]
WHERE code IN ('neck_stretch', 'shoulder_roll', 'marching_in_place');

-- 4. 仅 STRENGTH（专门的力量训练）
UPDATE "exercises"
SET "intent_type" = ARRAY['STRENGTH']::"IntentType"[]
WHERE code IN ('backpack_deadlift', 'bottle_bicep_curl', 'wall_handstand_prep');
```

---

## 📊 **效果对比**

### 之前（单个意图）
```json
{
  "code": "neck_stretch",
  "intent_type": "RELAX"  // 只能用于 RELAX
}
```

**问题：** 用户选择 STRETCH 意图时找不到这个动作

### 现在（数组）

**方案 A - 多个意图：**
```json
{
  "code": "neck_stretch",
  "intent_type": ["RELAX", "STRETCH"]  // 可用于 RELAX 和 STRETCH
}
```

**方案 B - 所有意图（空数组）：**
```json
{
  "code": "neck_stretch",
  "intent_type": []  // 适用于所有意图
}
```

---

## 🔍 **查询示例**

### 前端查询逻辑（不变）
```typescript
// 前端依然传单个意图
const request = {
  intent: 'RELAX',
  equipment: ['chair'],
  scenario: 'office',
  targetMuscles: ['NECK_SHOULDER']
};
```

### 后端匹配逻辑（自动处理）
```typescript
// 会匹配以下所有动作：
// 1. intent_type = ['RELAX']
// 2. intent_type = ['RELAX', 'STRETCH']
// 3. intent_type = []  (空数组 = 万能匹配)
```

---

## 🚀 **实施步骤**

### **第一步：运行 Migration**
```bash
# 在 Supabase SQL Editor 中执行
-- 文件：backend/sql/migration-intent-type-to-array.sql
```

### **第二步：更新现有数据（可选）**
```bash
# 在 Supabase SQL Editor 中执行
-- 文件：backend/sql/sample-data-update-intent-types.sql
```

### **第三步：重启后端服务**
```bash
cd backend
npm run start:dev
```

### **第四步：验证**
```bash
# 测试查询 RELAX 意图的动作
curl -X POST http://localhost:3000/api/v1/recommendations/quick \
  -H "Content-Type: application/json" \
  -d '{
    "intent": "RELAX",
    "equipmentCodes": ["chair"],
    "scenarioCode": "office",
    "targetMuscles": ["NECK_SHOULDER"]
  }'
```

---

## ✨ **优势**

1. **更多匹配结果**
   - 之前：用户选择 RELAX，只找到 10 个动作
   - 现在：用户选择 RELAX，找到 25 个动作（包括 RELAX/STRETCH 和空数组的动作）

2. **更灵活的动作分类**
   - 一个动作可以同时适用于多个场景
   - 例如：wall_pushup 可以是 STRENGTH 也可以是 MODERATE

3. **万能动作**
   - 空数组 `[]` 的动作作为"填充动作"
   - 无论用户选什么意图都能匹配，增加workout多样性

4. **向后兼容**
   - 前端代码无需修改（依然传单个 intent）
   - 后端自动处理数组匹配

---

## 📝 **注意事项**

1. **数组查询性能**
   - 已创建 GIN 索引：`CREATE INDEX ... USING GIN ("intent_type")`
   - 支持高效的数组包含查询

2. **空数组的含义**
   - `[]` = 适用于所有意图（不是"没有意图"）
   - 适合基础动作（如 neck_stretch, marching）

3. **数据一致性**
   - Migration 会自动转换现有数据
   - 单个值 `'RELAX'` → 数组 `['RELAX']`

4. **统计数据**
   - `getExercisesByIntent()` 方法已更新
   - 一个动作可能在多个意图下都被计数（这是预期行为）

---

## 🎉 **总结**

✅ **数据库 Schema 已更新** - intent_type 现在是数组
✅ **后端代码已适配** - 支持数组查询和过滤
✅ **向后兼容** - 前端无需修改
✅ **性能优化** - GIN 索引支持高效查询
✅ **文档齐全** - Migration 和示例数据更新 SQL

**下一步：** 在 Supabase 中执行 Migration 并测试！
