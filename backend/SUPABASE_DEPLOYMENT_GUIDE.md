# SnapRep Supabase 数据库部署指南

## 🎯 快速部署步骤

### 方法 1: 使用 Supabase Dashboard SQL Editor（推荐）

这是最简单直接的方法，无需安装任何工具。

#### 步骤：

1. **登录 Supabase Dashboard**
   - 访问: https://app.supabase.com/project/tvjcmleckqovnieuexgu
   - 使用你的 Supabase 账号登录

2. **打开 SQL Editor**
   - 在左侧菜单中点击 `SQL Editor`
   - 或直接访问: https://app.supabase.com/project/tvjcmleckqovnieuexgu/sql

3. **创建新查询**
   - 点击右上角的 `New Query` 按钮

4. **复制并粘贴迁移脚本**
   - 打开文件: `backend/supabase_migration.sql`
   - 全选并复制所有内容（872行）
   - 粘贴到 SQL Editor 中

5. **执行脚本**
   - 点击右下角的 `Run` 按钮（或按 Ctrl+Enter / Cmd+Enter）
   - 等待执行完成（约5-10秒）

6. **验证部署**
   - 在左侧菜单点击 `Table Editor`
   - 应该看到 16 张新创建的表

---

## ✅ 预期结果

执行完成后，你应该看到：

### 📊 创建的数据库对象

#### 11 个枚举类型 (ENUMs)
- `NoiseLevel` - 噪音等级
- `SpaceSize` - 空间大小
- `EquipmentCategory` - 器材分类
- `PrimaryMuscle` - 主要肌群
- `IntentType` - 运动意图
- `Difficulty` - 难度等级
- `DurationType` - 时长计量方式
- `SessionStatus` - 训练会话状态
- `RarityLevel` - 稀有度等级
- `DataSource` - 数据来源
- `DeeplinkTargetType` - 深链目标类型

#### 16 张表 (Tables)
1. `scenarios` - 场景表（office, home, gym, park）
2. `equipment` - 器材表（chair, wall, bottle, etc.）
3. `exercises` - 动作表（50+ exercises）
4. `exercise_scenarios` - 动作-场景关联表
5. `exercise_equipment` - 动作-器材关联表
6. `users` - 用户表
7. `user_preferences` - 用户偏好表
8. `workout_sessions` - 训练会话表
9. `session_exercises` - 会话动作记录表
10. `daily_trainings` - 每日训练统计表
11. `share_cards` - 分享卡片表
12. `rarity_table` - 稀有度表
13. `theme_weeks` - 主题周表
14. `theme_week_participations` - 主题周参与表
15. `deeplinks` - 深链表
16. `deeplink_clicks` - 深链点击统计表

#### 40+ 索引 (Indexes)
- 为高频查询优化的复合索引
- 唯一约束索引
- 外键关系索引

#### 14 个外键 (Foreign Keys)
- 保证数据完整性的关系约束

#### 30+ RLS 策略 (Row Level Security Policies)
- 用户数据保护策略
- 级联权限策略
- 公开读取策略
- 无需认证的数据访问策略

---

## 🔍 验证部署成功

### 方法 1: 在 Supabase Dashboard 验证

1. **检查表是否创建**
   ```
   进入 Table Editor → 应该看到 16 张表
   ```

2. **检查 RLS 是否启用**
   ```
   选择任意表 → 点击 "RLS" 标签 → 应该看到相关策略
   ```

### 方法 2: 使用 Prisma CLI 验证

在本地终端运行：

```bash
cd backend

# 生成 Prisma Client（应该不报错）
npx prisma generate

# 验证数据库连接
npx prisma db pull

# 如果成功，会显示数据库中的表结构
```

### 方法 3: 使用 SQL 查询验证

在 Supabase SQL Editor 中执行：

```sql
-- 查看所有表
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;

-- 查看所有枚举类型
SELECT typname
FROM pg_type
WHERE typtype = 'e'
ORDER BY typname;

-- 查看 RLS 策略数量
SELECT schemaname, tablename, COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
GROUP BY schemaname, tablename
ORDER BY tablename;
```

预期结果：
- 16 张表
- 11 个枚举类型
- 30+ 个 RLS 策略

---

## 🚨 常见问题处理

### 问题 1: "type already exists" 错误

**原因**: 枚举类型已存在

**解决方案**:

选项 A - 删除现有类型（如果表中无数据）：
```sql
-- 先删除依赖的表
DROP TABLE IF EXISTS users, exercises, equipment CASCADE;

-- 删除枚举类型
DROP TYPE IF EXISTS "NoiseLevel", "SpaceSize", "EquipmentCategory" CASCADE;

-- 重新执行 supabase_migration.sql
```

选项 B - 跳过枚举创建部分，直接从表创建开始执行

### 问题 2: "table already exists" 错误

**原因**: 表已存在

**解决方案**: 清空数据库后重新执行

```sql
-- ⚠️ 警告：此操作会删除所有数据！
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- 重新执行 supabase_migration.sql
```

### 问题 3: RLS 策略错误

**原因**: 策略名称冲突

**解决方案**:
```sql
-- 查看现有策略
SELECT * FROM pg_policies WHERE schemaname = 'public';

-- 删除特定表的所有策略
DROP POLICY IF EXISTS policy_name ON table_name;

-- 或删除所有策略
DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN (SELECT schemaname, tablename, policyname
              FROM pg_policies
              WHERE schemaname = 'public')
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS ' || quote_ident(r.policyname) ||
                ' ON ' || quote_ident(r.schemaname) || '.' || quote_ident(r.tablename);
    END LOOP;
END $$;
```

---

## 📝 下一步操作

部署完成后：

### 1. 生成 Prisma Client

```bash
cd backend
npx prisma generate
```

### 2. 创建种子数据（可选）

```bash
npm run seed
```

这会创建：
- 4 个场景 (office, home, gym, park)
- 10+ 种器材 (chair, wall, bottle, etc.)
- 50+ 个动作

### 3. 配置 Supabase Storage

在 Supabase Dashboard 中创建存储桶：

1. **share-cards** (公开读取)
   - 用于存储分享卡片图片
   - 设置为 Public

2. **user-uploads** (私有)
   - 用于存储用户上传的文件
   - 使用 RLS 保护

### 4. 测试 API 连接

创建测试文件 `backend/test-connection.js`:

```javascript
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function testConnection() {
  try {
    // 测试查询
    const scenariosCount = await prisma.scenarios.count();
    console.log('✅ 数据库连接成功!');
    console.log(`📊 场景表记录数: ${scenariosCount}`);

    const equipmentCount = await prisma.equipment.count();
    console.log(`📊 器材表记录数: ${equipmentCount}`);

    const exercisesCount = await prisma.exercises.count();
    console.log(`📊 动作表记录数: ${exercisesCount}`);
  } catch (error) {
    console.error('❌ 连接失败:', error.message);
  } finally {
    await prisma.$disconnect();
  }
}

testConnection();
```

运行测试：
```bash
node test-connection.js
```

---

## 🔐 安全提示

1. **数据库密码**: 确保 `.env` 文件不要提交到 Git
   ```bash
   # 检查 .gitignore 是否包含
   cat .gitignore | grep .env
   ```

2. **RLS 策略**: 已为所有用户表启用 RLS，确保用户只能访问自己的数据

3. **API Keys**:
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`: 可以公开（用于前端）
   - Service Role Key: 绝不能泄露（仅用于后端）

---

## 📚 相关文档

- [Prisma Schema](./prisma/schema.prisma) - 数据模型定义
- [Supabase Migration SQL](./supabase_migration.sql) - 完整的迁移脚本
- [README.md](./README.md) - 数据库架构文档
- [API Improvements](./API_IMPROVEMENTS.md) - API 设计规范

---

## 🆘 获取帮助

如果遇到问题：

1. 检查 Supabase Dashboard 的 Logs 页面
2. 查看 SQL Editor 中的错误信息
3. 确认 `.env` 文件配置正确
4. 确保 Supabase 项目处于活动状态

---

**部署脚本版本**: v3.0 (Production Ready)
**最后更新**: 2025-10-31
**总表数**: 16 张表
**总行数**: 872 行 SQL

🚀 祝部署顺利！
