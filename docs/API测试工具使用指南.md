# SnapRep API测试工具使用指南

本文档介绍如何使用SnapRep项目中的各种API测试工具，帮助开发者进行全面的API测试和监控。

## 📋 可用测试命令

### 核心测试命令
```bash
cd backend

# 🚀 全面API测试 (推荐) - 测试所有29个端点 + 7个业务流程
npm run test:comprehensive

# 🔍 快速健康检查 - 检查核心API端点状态
npm run test:health

# ⚡ 快速冒烟测试 - 验证基本系统状态
npm run test:quick

# 🔧 完整测试套件 - 运行原有的完整测试
npm run test:full
```

### 专项测试命令
```bash
# 📋 业务流程测试 - 7个核心业务流程
npm run test:flows

# 🔌 API集成测试 - 29个API端点
npm run test:api

# 🛠️ 测试助手工具
npm run test:helper help          # 显示帮助
npm run test:helper db-check      # 检查数据库状态
npm run test:helper clean         # 清理测试环境
npm run test:helper flow 1        # 测试特定业务流程(1-7)
```

## 🎯 测试工具详解

### 1. 全面API测试器 (`test:comprehensive`)

**功能**: 最全面的API测试工具，覆盖所有端点和业务流程
**文件**: `scripts/comprehensive-api-tester.js`
**适用场景**:
- 版本发布前的完整测试
- 定期的系统健康检查
- 问题诊断和分析

**测试内容**:
- ✅ 12个Supabase REST API端点
- ✅ 14个NestJS Custom API端点
- ✅ 7个业务流程测试
- ✅ 性能基准测试
- ✅ 环境状态检查

**输出报告**:
- `docs/全面API测试报告.md` - 详细测试报告
- `docs/comprehensive-test-results.json` - JSON格式数据

**示例执行**:
```bash
npm run test:comprehensive
```

### 2. API健康检查器 (`test:health`)

**功能**: 快速的API健康状态监控
**文件**: `scripts/api-health-checker.js`
**适用场景**:
- 日常健康监控
- CI/CD pipeline集成
- 生产环境状态检查

**测试内容**:
- ✅ 核心API端点可用性
- ✅ 响应时间监控
- ✅ 错误状态检测
- ✅ 关键端点优先级检查

**输出报告**:
- `docs/api-health-check.md` - 健康检查报告
- 控制台实时输出

**示例执行**:
```bash
npm run test:health
```

### 3. 快速测试工具 (`test:quick`)

**功能**: 最快速的系统状态验证
**文件**: `scripts/test-helper.js`
**适用场景**:
- 开发环境启动验证
- 快速问题排查
- 基础功能确认

**测试内容**:
- ✅ 数据库连接
- ✅ 服务器状态
- ✅ 基础API端点
- ✅ 测试数据完整性

### 4. 测试助手工具 (`test:helper`)

**功能**: 多功能测试辅助工具
**文件**: `scripts/test-helper.js`
**适用场景**:
- 测试环境管理
- 问题诊断
- 特定功能测试

**可用子命令**:
```bash
npm run test:helper quick        # 快速冒烟测试
npm run test:helper flow <1-7>   # 测试特定业务流程
npm run test:helper api          # API集成测试
npm run test:helper db-check     # 数据库状态检查
npm run test:helper clean        # 清理测试环境
npm run test:helper seed         # 重新生成测试数据
npm run test:helper coverage     # 测试覆盖率
npm run test:helper help         # 显示帮助
```

## 📊 测试报告说明

### 报告类型

1. **全面测试报告** (`全面API测试报告.md`)
   - 最详细的测试结果
   - 包含所有API端点状态
   - 业务流程测试详情
   - 性能基准数据
   - 错误分析和建议

2. **执行总结报告** (`全面API测试执行总结.md`)
   - 高层次的测试总结
   - 问题分类和优先级
   - 修复建议和行动计划
   - 系统健康度评估

3. **健康检查报告** (`api-health-check.md`)
   - 简洁的健康状态概览
   - 核心指标监控
   - 实时状态更新

### 关键指标解读

#### 测试通过率
- **90%以上**: 🟢 优秀 - 系统状态良好
- **70-89%**: 🟡 良好 - 需要关注部分问题
- **50-69%**: 🟠 一般 - 存在较多问题需修复
- **50%以下**: 🔴 差 - 需要立即修复

#### 响应时间标准
- **<100ms**: 🟢 优秀
- **100-500ms**: 🟡 良好
- **500-1000ms**: 🟠 可接受
- **>1000ms**: 🔴 需要优化

#### HTTP状态码说明
- **200**: ✅ 正常
- **401**: ⚠️ 认证问题(Supabase常见)
- **404**: ❌ 端点不存在
- **500**: 🚨 服务器错误(需立即修复)

## 🔧 常见问题和解决方案

### 1. Supabase认证问题 (HTTP 401)

**问题**: 所有Supabase REST API返回401错误
**原因**: API key配置问题或权限设置
**解决方案**:
```bash
# 检查环境变量
echo $SUPABASE_ANON_KEY

# 更新环境变量
export SUPABASE_ANON_KEY="your-actual-key"

# 重新测试
npm run test:health
```

### 2. 服务器连接失败

**问题**: 本地API端点无法连接
**原因**: 开发服务器未启动
**解决方案**:
```bash
# 启动开发服务器
npm run start:dev

# 验证服务器状态
npm run test:quick
```

### 3. 业务流程测试失败

**问题**: Jest找不到测试文件
**原因**: Jest配置路径问题
**解决方案**:
```bash
# 使用正确的e2e配置运行
npx jest test/business-flows/ --config test/jest-e2e.json

# 或使用修复后的命令
npm run test:flows
```

### 4. TypeScript编译错误

**问题**: 测试文件类型错误
**原因**: Prisma schema与测试代码不匹配
**解决方案**:
```bash
# 重新生成Prisma客户端
npm run prisma:generate

# 检查schema同步
npm run test:helper db-check
```

## 🚀 最佳实践

### 1. 日常开发流程
```bash
# 1. 开发环境启动验证
npm run test:quick

# 2. 功能开发...

# 3. 提交前完整测试
npm run test:comprehensive

# 4. 部署后健康检查
npm run test:health
```

### 2. CI/CD集成
```yaml
# .github/workflows/api-test.yml
name: API Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Setup Node.js
        uses: actions/setup-node@v2
        with:
          node-version: '18'
      - name: Install dependencies
        run: npm ci
        working-directory: backend
      - name: Run API health check
        run: npm run test:health
        working-directory: backend
      - name: Run comprehensive tests
        run: npm run test:comprehensive
        working-directory: backend
```

### 3. 定期监控
```bash
# 每日健康检查 (可配置cron job)
0 9 * * * cd /path/to/snaprep/backend && npm run test:health

# 每周完整测试
0 9 * * 1 cd /path/to/snaprep/backend && npm run test:comprehensive
```

### 4. 问题排查顺序
1. **快速检查**: `npm run test:quick`
2. **健康监控**: `npm run test:health`
3. **数据库检查**: `npm run test:helper db-check`
4. **完整诊断**: `npm run test:comprehensive`

## 📞 获取帮助

### 查看工具帮助
```bash
npm run test:helper help
```

### 检查工具版本
```bash
node scripts/comprehensive-api-tester.js --version
```

### 常用调试命令
```bash
# 检查环境状态
npm run test:helper db-check

# 清理并重置
npm run test:helper clean
npm run test:helper seed

# 查看详细日志
npm run test:comprehensive 2>&1 | tee test-log.txt
```

---

**更新时间**: 2025年11月6日
**工具版本**: v2.0
**维护者**: SnapRep开发团队
**文档版本**: 1.0