# Flutter 前端调试指南

## 前置条件

确保你已经安装了以下 VSCode 扩展：
- ✅ `Dart` (dart-code.dart-code)
- ✅ `Flutter` (dart-code.flutter)
- ✅ `Flutter Snippets` (alexisvt.flutter-snippets)
- ✅ `Awesome Flutter Snippets` (nash.awesome-flutter-snippets)

## 调试方法

### 1. 使用 VSCode 内置调试器 (推荐)

**步骤：**
1. 按 `F5` 或者点击菜单 `运行 > 启动调试`
2. 选择以下调试配置之一：
   - **Flutter Debug (Windows)** - 在 Windows 桌面运行
   - **Flutter Debug (Chrome)** - 在 Chrome 浏览器运行
   - **Flutter Profile (性能分析)** - 性能分析模式

**调试功能：**
- ✅ 设置断点 (在代码行号左侧点击)
- ✅ 单步调试 (F10/F11)
- ✅ 查看变量值
- ✅ 调用栈分析
- ✅ 热重载 (Ctrl+S 保存文件即可)

### 2. 全栈联调 (后端 + 前端)

选择以下组合配置：
- **全栈调试 (后端 + 前端 Windows)** - 同时启动 NestJS 后端和 Flutter Windows 前端
- **全栈调试 (后端 + 前端 Chrome)** - 同时启动 NestJS 后端和 Flutter Web 前端

### 3. 命令行调试

```bash
# 基础调试运行
cd frontend
flutter run -d windows --debug

# 详细调试信息
flutter run -d windows --debug --verbose

# Profile 模式 (性能分析)
flutter run -d windows --profile

# Release 模式
flutter run -d windows --release
```

## 调试工具

### 1. Flutter DevTools

**启动方式：**
1. 在调试运行时，VSCode 会显示 DevTools 链接
2. 点击链接或按 `Ctrl+Shift+P` → 输入 "Flutter: Open DevTools"

**功能：**
- 🎯 Widget 树检查
- 📊 性能分析
- 🔍 网络请求监控
- 💾 内存分析
- 🎨 UI 布局调试

### 2. VSCode Flutter 快捷键

- `Ctrl+Shift+P` → "Flutter: Hot Reload" - 热重载
- `Ctrl+Shift+P` → "Flutter: Hot Restart" - 热重启
- `Ctrl+Shift+P` → "Flutter: Open DevTools" - 打开 DevTools
- `Ctrl+Shift+P` → "Flutter: Run Flutter Doctor" - 检查环境

### 3. 日志查看

在 VSCode 的 `DEBUG CONSOLE` 面板中查看：
- Flutter 应用日志
- 异常信息
- Debug 输出 (print 语句)

## 常见问题与解决方案

### 1. 断点不生效
**解决方案：**
- 确保在 Debug 模式下运行 (不是 Profile 或 Release)
- 重启调试会话
- 检查代码是否被执行到

### 2. 热重载不工作
**解决方案：**
- 按 `r` 键手动重载
- 按 `R` 键热重启
- 检查是否有语法错误

### 3. Windows 构建失败
**解决方案：**
- 运行 `flutter doctor` 检查环境
- 确保已安装 Visual Studio 2019/2022 和 Windows 10 SDK
- 运行 `flutter clean` 清理缓存

### 4. 性能调试
**使用 Profile 模式：**
- 启动 "Flutter Profile (性能分析)" 配置
- 使用 DevTools 进行性能分析
- 查看渲染性能和内存使用

## API 调试技巧

### 1. 网络请求调试
```dart
// 在 api_service.dart 中添加详细日志
print('🌐 Making API call to: $url');
print('📋 Headers: $_headers');
print('📊 Response status: ${response.statusCode}');
print('📄 Response body: ${response.body}');
```

### 2. 状态管理调试
```dart
// 在 Provider 中添加日志
print('🔄 Loading state changed: $_isLoading');
print('✅ Data loaded: ${data?.length} items');
```

### 3. 路由调试
在 VSCode 中设置断点在：
- `Navigator.push` / `Navigator.pop` 调用
- `RouteObserver` 回调
- 路由配置代码

## 推荐调试流程

1. **启动全栈调试** - 同时运行后端和前端
2. **设置关键断点** - 在数据获取、状态更新、UI 渲染处
3. **使用 DevTools** - 检查 Widget 树和性能
4. **查看网络请求** - 确认 API 调用正确
5. **测试不同设备** - Windows 和 Chrome 都测试

## VS Code 调试面板说明

- **VARIABLES** - 查看当前作用域变量
- **WATCH** - 添加监视表达式
- **CALL STACK** - 查看调用栈
- **BREAKPOINTS** - 管理所有断点
- **DEBUG CONSOLE** - 查看输出和执行表达式