# SnapRep 项目调试配置指南

## 🚀 VSCode 调试配置说明

这个 `.vscode` 目录包含了完整的 VSCode 调试配置，支持前后端的开发和调试。

### 📁 配置文件

```
.vscode/
├── launch.json      # 调试启动配置（后端+前端）
├── tasks.json       # 构建任务配置
├── settings.json    # 工作区设置
└── extensions.json  # 推荐扩展列表
```

### 🎯 可用的调试配置

#### 后端调试 (NestJS)

1. **Debug NestJS Backend (开发模式)** ⭐ 主要使用
   - 按 **F5** 启动
   - 效果等同于：`cd backend && npm run start:dev`
   - 支持热重载 + 断点调试
   - 端口：3000 (HTTP) + 9229 (调试)

2. **Debug NestJS Backend (生产模式)**
   - 生产环境模拟
   - 自动构建后启动

3. **Debug Backend Tests**
   - 单元测试调试
   - 支持断点和监听模式

4. **Debug Backend E2E Tests**
   - 端到端测试调试

5. **Attach to NestJS Process**
   - 附加到已运行的后端进程

#### 前端调试 (Flutter)

6. **Launch Flutter App (Debug)**
   - Flutter 应用调试启动
   - 支持热重载和断点调试

#### 全栈调试

7. **Launch Full Stack (Backend + Frontend)** 🌟
   - 同时启动后端和前端
   - 一键启动全栈开发环境

### 🛠️ 使用方法

#### 方法 1: F5 快捷键（推荐）
```
1. 在 VSCode 中打开项目根目录 D:\lyh\AI\SnapRep
2. 按 F5 键
3. 选择 "Debug NestJS Backend (开发模式)"
4. 开始调试！
```

#### 方法 2: 调试面板
```
1. 打开调试面板：Ctrl+Shift+D
2. 从下拉菜单选择配置
3. 点击绿色启动按钮
```

#### 方法 3: 全栈调试
```
1. 按 F5
2. 选择 "Launch Full Stack (Backend + Frontend)"
3. 同时启动后端和前端
```

### 🔍 断点调试技巧

#### 设置断点
- 点击代码行号左侧设置断点
- 红点表示断点已设置
- 支持条件断点（右键断点）

#### 调试快捷键
- **F5**: 继续执行
- **F10**: 单步跳过（Step Over）
- **F11**: 单步进入（Step Into）
- **Shift+F11**: 单步跳出（Step Out）
- **Shift+F5**: 停止调试
- **Ctrl+Shift+F5**: 重启调试

#### 调试面板功能
- **变量**: 查看当前作用域变量
- **监视**: 添加表达式监视
- **调用堆栈**: 查看函数调用链
- **断点**: 管理所有断点
- **调试控制台**: 执行代码和查看输出

### 🌐 后端服务访问地址

启动后端调试后可以访问：

- **GraphQL Playground**: http://localhost:3000/graphql
- **REST API 文档**: http://localhost:3000/api (Swagger)
- **健康检查**: http://localhost:3000/health

### 📊 数据库管理

#### Prisma Studio（可视化数据库管理）
```bash
# 方法 1: 使用 VSCode 任务
Ctrl+Shift+P -> Tasks: Run Task -> Backend: Prisma Studio

# 方法 2: 命令行
cd backend
npm run prisma:studio
```

#### 数据库操作命令
```bash
cd backend

# 生成 Prisma 客户端
npm run prisma:generate

# 创建并应用迁移
npm run migrate:dev

# 查看迁移状态
npm run migrate:status

# 填充种子数据
npm run seed
```

### 🐳 Docker 支持

#### 启动数据库容器
```bash
# 方法 1: 使用 VSCode 任务
Ctrl+Shift+P -> Tasks: Run Task -> Backend: Docker Database

# 方法 2: 命令行
cd backend
npm run docker:db
```

### 🧪 测试

#### 后端测试
```bash
cd backend

# 运行所有测试
npm test

# 完整测试套件
npm run test:full

# 业务流程测试
npm run test:flows

# E2E 测试
npm run test:e2e

# 带覆盖率
npm run test:cov
```

#### 前端测试
```bash
cd frontend

# 运行测试
flutter test

# 代码分析
flutter analyze
```

### 📦 构建与运行

#### 后端
```bash
cd backend

# 开发模式（热重载）
npm run start:dev

# 生产构建
npm run build
npm run start:prod
```

#### 前端
```bash
cd frontend

# 运行应用
flutter run

# 构建 APK
flutter build apk

# 构建 iOS（仅 macOS）
flutter build ios --release
```

### ⚙️ 环境配置

#### 后端环境变量
确保 `backend/.env` 文件配置正确：

```env
# Database
DATABASE_URL="postgresql://postgres:Snaprep%40123@db.tvjcmleckqovnieuexgu.supabase.co:5432/postgres?sslmode=require"

# JWT Secret
JWT_SECRET="your-jwt-secret-key"

# Environment
NODE_ENV="development"
```

#### 前端配置
前端的 API 配置在 `frontend/lib/core/constants/app_constants.dart`：

```dart
// API URLs
static const String supabaseUrl = 'https://tvjcmleckqovnieuexgu.supabase.co';
static const String nestJsApiUrl = 'http://localhost:3000/api/v1';
```

### 🚨 常见问题

#### 1. 端口被占用
```bash
# 检查端口占用
netstat -ano | findstr :3000

# 终止进程（替换 PID）
taskkill /PID <进程ID> /F
```

#### 2. Prisma 客户端未生成
```bash
cd backend
npm run prisma:generate
```

#### 3. 数据库连接失败
- 检查 `.env` 文件中的 `DATABASE_URL`
- 确保数据库服务正在运行
- 测试数据库连接

#### 4. Flutter 依赖问题
```bash
cd frontend
flutter clean
flutter pub get
```

#### 5. 调试器无法附加
- 确保没有其他进程占用调试端口 9229
- 重启 VSCode
- 检查防火墙设置

### 📚 推荐扩展

首次打开项目时，VSCode 会提示安装以下推荐扩展：

**后端开发**:
- Prisma
- ESLint
- Prettier
- GraphQL

**前端开发**:
- Dart
- Flutter
- Flutter Snippets

**通用工具**:
- GitLens
- Docker
- REST Client

### 💡 开发技巧

1. **热重载**:
   - 后端：修改代码后自动重启，断点保持有效
   - 前端：Flutter 支持热重载（r）和热重启（R）

2. **多项目管理**:
   - 使用 VSCode 的多根工作区功能
   - 可以同时调试前后端

3. **日志查看**:
   - 后端日志在集成终端
   - 前端日志在调试控制台

4. **API 测试**:
   - 使用 GraphQL Playground
   - 使用 REST Client 扩展
   - 使用 Postman

### 🎉 开始使用

现在你可以：

1. **按 F5** 启动后端调试
2. **设置断点** 在关键代码处
3. **发送请求** 测试 API
4. **逐步调试** 查看执行流程

**快速启动全栈开发**:
```
按 F5 -> 选择 "Launch Full Stack (Backend + Frontend)"
```

祝你开发愉快！🚀✨

---

## 📖 详细文档

- [后端 API 文档](./docs/API.md)
- [业务流程文档](./docs/业务流程.md)
- [前端开发指南](./frontend/CLAUDE.md)
- [后端开发指南](./CLAUDE.md)