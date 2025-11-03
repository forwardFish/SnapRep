# E2E测试指南

## 概述

本文档提供SnapRep后端的端到端(E2E)测试指南，包括测试架构、运行方法和调试技巧。

## 测试架构

### 测试场景覆盖

```
E2E测试/
├── scenario-1-new-user-full-flow.e2e-spec.ts    # 新用户完整流程
├── scenario-2-ai-recognition.e2e-spec.ts         # AI识别流程
├── scenario-3-copy-same-workout.e2e-spec.ts      # 复刻同款流程
└── scenario-4-theme-week.e2e-spec.ts             # 主题周参与流程
```

### 辅助工具

```
helpers/
├── test-data.helper.ts         # 测试数据管理
└── api-client.helper.ts        # API客户端封装
```

## 测试数据准备

### 1. 初始化测试数据

```bash
cd backend
psql -d snaprep_test -f prisma/test-data.sql
```

### 2. 验证数据加载

```sql
SELECT
  (SELECT COUNT(*) FROM scenarios) as scenarios,
  (SELECT COUNT(*) FROM equipment) as equipment,
  (SELECT COUNT(*) FROM exercises) as exercises,
  (SELECT COUNT(*) FROM theme_weeks) as theme_weeks;
```

## 运行E2E测试

### 运行所有E2E测试

```bash
npm run test:e2e
```

### 运行单个场景

```bash
# 场景1: 新用户完整流程
npm run test:e2e -- scenario-1-new-user-full-flow

# 场景2: AI识别
npm run test:e2e -- scenario-2-ai-recognition

# 场景3: 复刻同款
npm run test:e2e -- scenario-3-copy-same-workout

# 场景4: 主题周
npm run test:e2e -- scenario-4-theme-week
```

### 调试模式

```bash
npm run test:e2e -- --detectOpenHandles --forceExit
```

## 场景测试详情

### 场景1: 新用户首次完整流程

**测试目标**: 验证从打开到分享的完整用户旅程

**关键步骤**:
1. 匿名登录 → JWT Token验证
2. 加载首页 → 性能验证(≤2秒)
3. 快速推荐 → 生成3个动作(≤5秒)
4. 开始跟练 → 状态更新验证
5. 完成训练 → 时长记录验证
6. 生成卡片 → 稀有度计算(≤800ms)
7. 验证统计 → 数据一致性

**性能指标**:
- TTV (Time to Value): ≤30秒
- 推荐生成: ≤5秒
- 卡片生成: ≤800ms

### 场景2: AI识别流程

**测试目标**: 验证AI识别物品后的完整流程

**关键验证**:
- AI识别时间 ≤3秒
- 置信度 ≥85% 自动预选
- 识别准确率 ≥70%
- 低置信度有fallback

### 场景3: 复刻同款流程

**测试目标**: 验证一键同款功能

**关键验证**:
- 条件完全复刻(器材、意图、场景)
- 推荐动作可能不同(随机性)
- 流程无错误

### 场景4: 主题周参与

**测试目标**: 验证主题周完整流程

**关键验证**:
- 进度追踪准确(0/3 → 3/3)
- 奖励正确解锁
- 不能重复加入

## 测试环境配置

### 环境变量

创建 `.env.test`:

```env
DATABASE_URL="postgresql://postgres:password@localhost:5432/snaprep_test"
JWT_SECRET="test_jwt_secret"
SUPABASE_URL="https://test.supabase.co"
SUPABASE_KEY="test_key"
```

### 数据库配置

```bash
# 创建测试数据库
createdb snaprep_test

# 运行迁移
npx prisma migrate deploy --schema=./prisma/schema.prisma

# 加载测试数据
psql -d snaprep_test -f prisma/test-data.sql
```

## 调试技巧

### 1. 查看测试日志

```bash
npm run test:e2e -- --verbose
```

### 2. 单步调试

在测试文件中添加:
```typescript
it.only('specific test', async () => {
  // 只运行这个测试
});
```

### 3. 数据库状态检查

在测试中添加:
```typescript
const data = await prisma.workoutSession.findMany();
console.log('Current sessions:', data);
```

### 4. 性能分析

```typescript
const startTime = Date.now();
// ... 操作
const duration = Date.now() - startTime;
console.log(`Operation took ${duration}ms`);
```

## CI/CD集成

### GitHub Actions配置

```yaml
name: E2E Tests

on: [push, pull_request]

jobs:
  e2e:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'

      - run: npm install
      - run: npx prisma migrate deploy
      - run: psql -f prisma/test-data.sql
      - run: npm run test:e2e
```

## 常见问题

### Q: 测试超时怎么办？

A: 增加超时时间:
```typescript
jest.setTimeout(30000); // 30秒
```

### Q: 数据库连接失败？

A: 检查 `.env.test` 配置和数据库是否运行

### Q: 测试数据冲突？

A: 在每个测试后清理数据:
```typescript
afterEach(async () => {
  await testData.cleanupTestData();
});
```

## 测试最佳实践

1. **隔离性**: 每个测试应该独立，不依赖其他测试的状态
2. **可重复性**: 测试应该可以多次运行并得到相同结果
3. **清晰性**: 测试名称应该清楚描述测试内容
4. **性能**: 避免不必要的等待，使用合理的超时时间
5. **清理**: 测试后清理数据，避免污染数据库

## 下一步

- [ ] 添加更多边界情况测试
- [ ] 实现性能基准测试
- [ ] 添加负载测试
- [ ] 集成到CI/CD pipeline

---

**最后更新**: 2025-11-03
**维护者**: SnapRep测试团队
