# Google Play 订阅配置完整指南

## 📋 目录
1. [Google Play Console 配置](#第一部分google-play-console-配置)
2. [Google Cloud 服务账号配置](#第二部分google-cloud-服务账号配置)
3. [后端配置](#第三部分后端配置)
4. [数据库迁移](#第四部分数据库迁移)
5. [测试订阅功能](#第五部分测试订阅功能)

---

## 第一部分：Google Play Console 配置

### Step 1: 创建订阅产品

1. **访问 Google Play Console**
   - 登录 https://play.google.com/console
   - 选择你的应用 "SnapRep"

2. **导航到订阅页面**
   - 左侧菜单: **Monetize** → **Products** → **Subscriptions**
   - 点击 **"Create subscription"** 按钮

3. **配置订阅产品基本信息**
   ```
   Product ID: snaprep_premium
   Name: SnapRep Premium
   Description: Unlock unlimited workouts, premium challenges, and exclusive features
   ```

4. **创建月付计划（Base Plan 1）**
   ```
   Base plan ID: monthly-plan
   Billing period: P1M (1 month)
   Price: $4.99 USD

   Free trial:
   ✅ Enable free trial
   Trial period: 7 days
   ```

5. **创建年付计划（Base Plan 2）**
   ```
   Base plan ID: yearly-plan
   Billing period: P1Y (1 year)
   Price: $29.99 USD

   Free trial:
   ✅ Enable free trial
   Trial period: 7 days
   ```

6. **保存并激活**
   - 点击 **"Save"**
   - 点击 **"Activate"** 激活订阅产品

---

## 第二部分：Google Cloud 服务账号配置

### Step 2: 创建服务账号

1. **访问 Google Cloud Console**
   - 登录 https://console.cloud.google.com/
   - 选择与 Google Play 关联的项目

2. **创建服务账号**
   - 导航: **IAM & Admin** → **Service Accounts**
   - 点击 **"Create Service Account"**
   - 填写信息:
     ```
     Name: snaprep-subscription-service
     Description: Service account for SnapRep subscription verification
     ```
   - 点击 **"Create and Continue"**

3. **授予权限**
   - 选择角色: **Service Account User**
   - 点击 **"Continue"** → **"Done"**

### Step 3: 生成 JSON 密钥

1. **创建密钥**
   - 点击刚创建的服务账号
   - 进入 **"Keys"** 标签
   - 点击 **"Add Key"** → **"Create new key"**
   - 选择格式: **JSON**
   - 点击 **"Create"**

2. **保存密钥文件**
   - JSON 密钥文件会自动下载
   - 文件名类似: `snaprep-xxxxx-xxxxxxxxxx.json`
   - ⚠️ **妥善保管此文件，不要泄露！**

### Step 4: 关联服务账号到 Google Play

1. **回到 Google Play Console**
   - 导航: **Setup** → **API access**

2. **授予服务账号权限**
   - 在 "Service accounts" 部分，找到你创建的服务账号
   - 点击 **"Grant access"**
   - 勾选权限:
     ```
     ✅ View app information and download bulk reports
     ✅ View financial data, orders, and cancellation survey responses
     ✅ Manage orders and subscriptions
     ```
   - 点击 **"Invite user"**

---

## 第三部分：后端配置

### Step 5: 上传 Google Play 密钥

1. **创建密钥目录**
   ```bash
   cd d:\lyh\AI\SnapRep\backend
   mkdir keys
   ```

2. **复制密钥文件**
   - 将下载的 JSON 密钥文件复制到 `backend/keys/` 目录
   - 重命名为: `google-play-service-account.json`
   ```bash
   # 最终路径应该是:
   # d:\lyh\AI\SnapRep\backend\keys\google-play-service-account.json
   ```

3. **添加到 .gitignore**
   - 编辑 `backend/.gitignore`，确保包含:
   ```
   # Google Play 密钥
   keys/
   *.json
   ```

### Step 6: 配置环境变量

编辑 `backend/.env` 文件，添加以下配置:

```env
# ==========================================
# Google Play 订阅配置
# ==========================================

# 应用包名（必须与 Google Play Console 一致）
GOOGLE_PLAY_PACKAGE_NAME=com.yourcompany.snaprep

# 服务账号密钥文件路径
GOOGLE_PLAY_SERVICE_ACCOUNT_KEY_PATH=./keys/google-play-service-account.json

# 订阅产品配置
GOOGLE_PLAY_PRODUCT_ID=snaprep_premium
GOOGLE_PLAY_MONTHLY_PLAN_ID=monthly-plan
GOOGLE_PLAY_YEARLY_PLAN_ID=yearly-plan

# 订阅价格配置（USD）
SUBSCRIPTION_MONTHLY_PRICE=4.99
SUBSCRIPTION_YEARLY_PRICE=29.99

# 免费用户每日训练限制
FREE_DAILY_EXERCISE_LIMIT=3

# 试用期配置
FREE_TRIAL_DAYS=7
```

**⚠️ 重要说明:**
- `GOOGLE_PLAY_PACKAGE_NAME` 需要与你在 Google Play Console 中的应用包名**完全一致**
- 密钥文件路径使用相对路径，从后端项目根目录开始

### Step 7: 检查后端订阅模块

确认以下文件存在并正确配置:

```
backend/src/subscription/
├── subscription.module.ts          ✅ 订阅模块
├── subscription.service.ts         ✅ 订阅服务
├── subscription.controller.ts      ✅ 订阅控制器
├── google-play.service.ts          ✅ Google Play 服务
├── daily-usage.service.ts          ✅ 每日使用统计服务
└── guards/
    ├── subscription.guard.ts       ✅ 订阅权限守卫
    └── usage.guard.ts              ✅ 使用限制守卫
```

---

## 第四部分：数据库迁移

### Step 8: 确保 Supabase 数据库连接

1. **检查数据库连接**
   ```bash
   cd d:\lyh\AI\SnapRep\backend
   ```

2. **确认 .env 中的数据库配置**
   ```env
   DATABASE_URL=postgresql://postgres.[YOUR_PROJECT_REF]:[YOUR_PASSWORD]@db.tvjcmleckqovnieuexgu.supabase.co:5432/postgres
   DIRECT_URL=postgresql://postgres.[YOUR_PROJECT_REF]:[YOUR_PASSWORD]@db.tvjcmleckqovnieuexgu.supabase.co:5432/postgres
   ```

3. **测试数据库连接**
   ```bash
   npx prisma db pull
   ```

### Step 9: 运行数据库迁移

1. **检查 Prisma Schema**
   - 确认 `prisma/schema.prisma` 包含订阅相关的表定义
   - 已包含的表:
     - `Subscription` (订阅表)
     - `DailyUsage` (每日使用统计表)
     - `PaymentTransaction` (支付交易表)

2. **生成迁移**
   ```bash
   npx prisma migrate dev --name add_subscription_system
   ```

3. **生成 Prisma Client**
   ```bash
   npx prisma generate
   ```

4. **验证表是否创建成功**
   - 登录 Supabase Dashboard
   - 进入 **Table Editor**
   - 检查以下表是否存在:
     - `subscriptions`
     - `daily_usage`
     - `payment_transactions`

### Step 10: 初始化订阅系统

1. **重启后端服务**
   ```bash
   npm run start:dev
   ```

2. **检查启动日志**
   - 应该看到订阅模块成功初始化的日志
   - 例如: `✅ SubscriptionModule initialized`

---

## 第五部分：测试订阅功能

### Step 11: 测试 API 端点

使用 Postman 或 curl 测试以下端点:

#### 1. 获取订阅状态
```bash
GET http://localhost:3000/subscription/status
Authorization: Bearer <YOUR_JWT_TOKEN>
```

**预期响应:**
```json
{
  "statusCode": 200,
  "data": {
    "subscription": {
      "isActive": false,
      "tier": "FREE",
      "status": "ACTIVE",
      "isTrialActive": false,
      "canStartTrial": true
    },
    "dailyUsage": {
      "exercisesUsed": 0,
      "exerciseLimit": 3,
      "canStartExercise": true
    }
  }
}
```

#### 2. 开始免费试用
```bash
POST http://localhost:3000/subscription/trial/start
Authorization: Bearer <YOUR_JWT_TOKEN>
Content-Type: application/json

{
  "timezone": "Asia/Shanghai"
}
```

**预期响应:**
```json
{
  "statusCode": 200,
  "message": "Free trial started successfully"
}
```

### Step 12: 前端测试

1. **运行 Flutter 应用**
   ```bash
   cd d:\lyh\AI\SnapRep\frontend
   flutter run
   ```

2. **测试流程**
   - 登录应用
   - 导航到训练结果页面
   - 点击 **"Start Workout"** 按钮
   - 应该看到订阅付费弹窗
   - 点击 **"Start Free Trial"** 按钮
   - 检查是否成功开始试用

3. **查看日志**
   ```
   ✅ 成功日志:
   flutter: 🎁 Starting free trial...
   flutter: 📊 Start trial response: 200
   flutter: ✅ Free trial started successfully

   ❌ 失败日志（如果仍然报错）:
   flutter: 📊 Start trial response: 400
   flutter: 📄 Response body: {"message": "错误信息"}
   ```

---

## 🔧 常见问题排查

### 问题 1: "Subscription system is being initialized"

**原因:** 后端订阅服务未正确初始化

**解决方案:**
1. 检查 `.env` 配置是否正确
2. 检查 Google Play 密钥文件是否存在
3. 重启后端服务
4. 检查后端启动日志是否有错误

### 问题 2: "User not found"

**原因:** 用户未在数据库中注册

**解决方案:**
1. 确保用户已通过登录接口注册
2. 检查 JWT token 是否有效
3. 检查数据库 `users` 表是否有该用户记录

### 问题 3: 数据库连接失败

**原因:** Supabase 数据库连接配置错误

**解决方案:**
1. 检查 `.env` 中的 `DATABASE_URL` 是否正确
2. 确认 Supabase 项目是否处于活跃状态
3. 检查数据库密码是否正确
4. 尝试直接从 Supabase Dashboard 连接

### 问题 4: Google Play 验证失败

**原因:** Google Play API 凭证配置错误

**解决方案:**
1. 确认服务账号 JSON 密钥文件路径正确
2. 检查服务账号是否已关联到 Google Play Console
3. 确认服务账号权限是否正确授予
4. 检查 `GOOGLE_PLAY_PACKAGE_NAME` 是否与应用包名一致

---

## 📊 配置检查清单

在开始测试前，请确认以下项目都已完成:

### Google Play Console
- [ ] 创建订阅产品 `snaprep_premium`
- [ ] 配置月付计划 `monthly-plan` ($4.99)
- [ ] 配置年付计划 `yearly-plan` ($29.99)
- [ ] 启用 7 天免费试用
- [ ] 激活订阅产品

### Google Cloud
- [ ] 创建服务账号
- [ ] 下载 JSON 密钥文件
- [ ] 关联服务账号到 Google Play Console
- [ ] 授予正确的权限

### 后端配置
- [ ] 上传 Google Play 密钥文件到 `backend/keys/`
- [ ] 配置 `.env` 环境变量
- [ ] 数据库迁移成功
- [ ] 订阅模块正确初始化
- [ ] 后端服务正常运行

### 前端配置
- [ ] 订阅服务已创建
- [ ] 订阅模型已定义
- [ ] 付费弹窗组件已实现
- [ ] Start Workout 逻辑已更新

### 测试
- [ ] API 端点测试通过
- [ ] 前端付费弹窗显示正常
- [ ] 免费试用功能正常工作
- [ ] 每日限制功能正常工作

---

## 🎉 完成后

配置完成后，你的应用将拥有完整的订阅功能:

✅ **免费用户**
- 每天可以做 3 次训练
- 可以开始 7 天免费试用

✅ **试用期用户**
- 无限制训练
- 7 天试用期结束后自动转为付费

✅ **付费用户**
- 无限制训练
- 访问所有高级功能

---

## 📞 需要帮助？

如果在配置过程中遇到问题:

1. 检查后端日志: `npm run start:dev` 的控制台输出
2. 检查前端日志: Flutter 应用的控制台输出
3. 查看 Supabase Dashboard 的实时日志
4. 参考 `backend/src/subscription/README.md` 获取更多文档

祝配置顺利！🚀
