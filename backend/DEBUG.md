# SnapRep 后端调试配置使用指南

## 🚀 VSCode 调试配置说明

现在你已经有了完整的 VSCode 调试配置，可以通过按 **F5** 键来启动后端服务并进行断点调试！

### 📁 配置文件概览

创建了以下 VSCode 配置文件：

```
backend/.vscode/
├── launch.json      # 调试启动配置
├── tasks.json       # 构建任务配置
├── settings.json    # 工作区设置
└── extensions.json  # 推荐扩展列表
```

### 🎯 调试配置选项

#### 1. **Debug NestJS (开发模式)** - 主要调试选项 ⭐
- **效果**: 等同于 `npm run start:dev`
- **特点**: 热重载 + 断点调试
- **端口**: 3000 (HTTP) + 9229 (调试)
- **环境**: 开发环境
- **自动任务**: 启动前自动执行 `prisma:generate`

#### 2. **Debug NestJS (生产模式)**
- **效果**: 等同于 `npm run start:prod`
- **特点**: 生产环境模拟
- **自动任务**: 启动前自动执行 `npm run build`

#### 3. **Debug Tests (单元测试)**
- **效果**: Jest 单元测试调试
- **特点**: 监听模式 + 断点调试
- **用途**: 调试测试代码

#### 4. **Debug E2E Tests (端到端测试)**
- **效果**: E2E 测试调试
- **配置**: 使用 `test/jest-e2e.json` 配置

#### 5. **Attach to NestJS Process**
- **用途**: 附加到运行中的 NestJS 进程
- **端口**: 9229

### 🛠️ 使用方法

#### 方法 1: F5 快速启动 (推荐)
1. 在 VSCode 中打开 `backend` 文件夹
2. 按 **F5** 键
3. 选择 "Debug NestJS (开发模式)"
4. 等待启动完成

#### 方法 2: 调试面板启动
1. 打开调试面板 (Ctrl+Shift+D)
2. 从下拉菜单选择配置
3. 点击绿色启动按钮

#### 方法 3: 命令面板启动
1. 按 Ctrl+Shift+P 打开命令面板
2. 输入 "Debug: Start Debugging"
3. 选择调试配置

### 🔍 断点调试

#### 设置断点
- 点击行号左侧设置断点
- 红点表示断点已设置
- 支持条件断点和日志点

#### 调试控制
- **F5**: 继续执行
- **F10**: 单步跳过
- **F11**: 单步进入
- **Shift+F11**: 单步跳出
- **Shift+F5**: 停止调试

#### 调试面板功能
- **变量**: 查看当前作用域变量
- **监视**: 添加表达式监视
- **调用堆栈**: 查看函数调用链
- **断点**: 管理所有断点

### 🌐 API 访问地址

启动后可以访问：

- **GraphQL Playground**: http://localhost:3000/graphql
- **REST API 文档**: http://localhost:3000/api (Swagger)
- **健康检查**: http://localhost:3000/health

### 📊 数据库管理

#### Prisma Studio
```bash
npm run prisma:studio
# 或者使用 VSCode 任务: Ctrl+Shift+P -> "Tasks: Run Task" -> "Prisma: Studio"
```

#### 数据库操作
```bash
# 生成 Prisma 客户端
npm run prisma:generate

# 创建并应用迁移
npm run migrate:dev

# 查看迁移状态
npm run migrate:status

# 重置数据库
npm run migrate:reset

# 填充种子数据
npm run seed
```

### 🐳 Docker 支持

#### 启动数据库容器
```bash
npm run docker:db
# 或者使用 VSCode 任务: "Docker: Start Database"
```

#### 完整容器化
```bash
npm run docker:build
npm run docker
```

### ⚙️ 环境配置

确保你的 `.env` 文件配置正确：

```env
# Database
DATABASE_URL="postgresql://用户名:密码@localhost:5432/数据库名?schema=public"

# JWT Secret
JWT_SECRET="your-jwt-secret-key"

# Other configurations...
```

### 🧪 测试执行

#### 完整测试套件
```bash
npm run test:full      # 完整测试编排
npm run test:quick     # 快速验证
npm run test:flows     # 业务流程测试
npm run test:api       # API 集成测试
```

#### 调试测试
1. 在测试文件中设置断点
2. 选择 "Debug Tests" 配置
3. 按 F5 启动调试

### 📝 推荐扩展

系统会自动推荐安装以下扩展：

- **Prisma**: 数据库模式支持
- **GraphQL**: GraphQL 语法高亮
- **ESLint**: 代码质量检查
- **Prettier**: 代码格式化
- **Jest**: 测试支持
- **Docker**: 容器管理
- **GitLens**: Git 增强

### 🚨 故障排除

#### 端口被占用
```bash
# 检查端口占用
netstat -ano | findstr :3000

# 终止进程 (替换 PID)
taskkill /PID <进程ID> /F
```

#### Prisma 问题
```bash
# 重新生成客户端
npm run prisma:generate

# 重置数据库
npm run migrate:reset
```

#### 调试器无法附加
1. 确保没有其他 Node.js 进程占用调试端口 (9229)
2. 检查防火墙设置
3. 重启 VSCode

### 💡 开发技巧

1. **热重载**: 修改代码后自动重启，断点保持有效
2. **环境变量**: 在 `launch.json` 中可以设置调试专用环境变量
3. **多个配置**: 可以同时运行多个调试会话（不同端口）
4. **性能分析**: 使用 Chrome DevTools 进行性能分析

### 🎉 开始调试

现在你可以：

1. **按 F5** 启动调试模式
2. **设置断点** 在关键业务逻辑处
3. **发送请求** 到 GraphQL 或 REST 接口
4. **逐步调试** 查看代码执行流程

祝你调试愉快！🐛✨