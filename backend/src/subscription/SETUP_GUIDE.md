# SnapRep 订阅系统设置指南

## 当前状态

✅ **已完成**：
- 后端订阅系统代码已实现
- 使用 sleep 间隔时间的后台任务（按您的要求）
- 临时服务避免 Prisma 错误
- 所有 TypeScript 编译错误已修复

⚠️ **待完成**：
- 数据库迁移
- Prisma 客户端生成

## 设置步骤

### 1. 运行数据库迁移

您需要在 Supabase SQL 编辑器中执行迁移脚本：

1. 登录 Supabase 控制台
2. 进入您的项目
3. 点击 "SQL Editor"
4. 复制以下文件的内容：
   ```
   backend/sql/supabase_migration.sql
   ```
   （从 "-- ============================================================================" 开始的订阅系统部分）

5. 在 SQL 编辑器中执行脚本

### 2. 生成 Prisma 客户端

数据库迁移完成后，运行：

```bash
cd backend
npx prisma generate
```

### 3. 替换临时服务

迁移完成后，将以下文件重命名：

```bash
# 备份临时文件
mv subscription.service.temp.ts subscription.service.temp.backup
mv daily-usage.service.temp.ts daily-usage.service.temp.backup

# 在 subscription.module.ts 中改回正常导入：
# import { SubscriptionService } from './subscription.service';
# import { DailyUsageService } from './daily-usage.service';
```

## 后台任务配置

✅ **已按您要求改写**：

- **过期订阅处理**: 每小时运行一次
- **使用记录清理**: 每24小时运行一次
- **Google Play 验证**: 每15分钟运行一次
- **分析报告生成**: 每6小时运行一次

所有任务使用 `sleep()` 函数控制间隔，在模块初始化时自动启动。

## API 端点

订阅系统提供以下端点：

### 订阅管理
```http
GET    /subscription/status           # 获取订阅状态
POST   /subscription/trial/start      # 开始免费试用
POST   /subscription/verify           # 验证 Google Play 购买
POST   /subscription/cancel           # 取消订阅
GET    /subscription/details          # 获取详细订阅信息
```

### 使用量跟踪
```http
POST   /subscription/exercise/record  # 记录运动完成
GET    /subscription/usage/check      # 检查是否可以开始运动
GET    /subscription/usage/history    # 获取使用历史
```

## 下一步

1. **完成数据库迁移** （最重要）
2. **测试 API 端点**
3. **前端集成**
4. **Google Play 配置**

## 价格策略

- **免费版**: 每天3个运动 + 7天试用
- **月订阅**: $4.99/月 - 无限运动
- **年订阅**: $29.99/年（节省50%）

## 故障排除

如果遇到问题：

1. **检查数据库连接**
2. **确认迁移已执行**
3. **重新生成 Prisma 客户端**
4. **查看应用日志**

---

**注意**: 目前系统使用临时服务，在完成数据库迁移之前，订阅功能会返回模拟数据。