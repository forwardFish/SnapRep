# Flutter 命令行调试指南

## 🎯 使用 `flutter run -d windows` 进行断点调试

你现在有 **3种** 方式进行 Flutter 断点调试：

## 方法 1：VSCode 直接启动调试 (最简单)

1. 按 `F5` 或点击 "运行 > 启动调试"
2. 选择 **"Flutter Run Windows (命令行方式)"**
3. VSCode 会自动启动 Flutter 并连接调试器
4. 直接设置断点即可！

## 方法 2：命令行启动 + VSCode attach (你常用的方式)

**步骤 1：命令行启动 Flutter**
```bash
cd frontend
flutter run -d windows --debug
```

**步骤 2：VSCode 连接调试器**
1. 等待 Flutter 应用启动完成
2. 按 `F5` 选择 **"Attach to Flutter (连接到已运行的Flutter应用)"**
3. 或者按 `Ctrl+Shift+P` → 输入 "Flutter: Attach to Device"

## 方法 3：全栈联调 (推荐)

选择 **"全栈调试 (后端 + 前端 Windows)"** - 同时启动后端和前端调试

## 🔧 断点调试功能

设置断点后，你可以：

### 在 Dart 代码中调试
- **变量查看**: 在 VARIABLES 面板查看所有变量值
- **监视表达式**: 在 WATCH 面板添加自定义表达式
- **调用栈**: 查看完整的函数调用路径
- **单步调试**:
  - `F10` - 跳过 (Step Over)
  - `F11` - 步入 (Step Into)
  - `Shift+F11` - 步出 (Step Out)

### Debug Console 使用
在 DEBUG CONSOLE 中可以：
```dart
// 查看变量值
print(variableName)

// 执行表达式
widget.title
context.size
Theme.of(context).primaryColor

// 调用方法
setState(() {})
```

## 📍 推荐的断点位置

### 1. API 调用调试
在 `frontend/lib/core/services/api_service.dart` 中：
```dart
Future<ThemeWeek?> getCurrentThemeWeek() async {
  // 在这里设置断点 ⭐
  final url = '${AppConstants.nestJsApiUrl}/theme-weeks/current';

  final response = await http.get(Uri.parse(url), headers: _headers);

  // 在这里设置断点 ⭐
  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    // 在这里设置断点 ⭐
    return ThemeWeek.fromJson(data['current']);
  }
}
```

### 2. 状态管理调试
在 `frontend/lib/core/providers/home_provider.dart` 中：
```dart
Future<void> loadCurrentThemeWeek() async {
  // 在这里设置断点 ⭐
  _isLoadingThemeWeek = true;
  notifyListeners();

  try {
    // 在这里设置断点 ⭐
    _currentThemeWeek = await _apiService.getCurrentThemeWeek();

    // 在这里设置断点 ⭐
    if (_currentThemeWeek != null) {
      print('✅ Successfully loaded theme week: ${_currentThemeWeek!.title}');
    }
  } catch (e) {
    // 在这里设置断点 ⭐
    _currentThemeWeek = _defaultDataService.getDefaultThemeWeek();
  }
}
```

### 3. UI 渲染调试
在 `frontend/lib/features/home/widgets/theme_week_section.dart` 中：
```dart
Widget build(BuildContext context) {
  // 在这里设置断点 ⭐
  return Consumer<HomeProvider>(
    builder: (context, homeProvider, child) {
      // 在这里设置断点 ⭐
      if (homeProvider.isLoadingThemeWeek) {
        return const CircularProgressIndicator();
      }

      final themeWeek = homeProvider.currentThemeWeek;
      // 在这里设置断点 ⭐
      if (themeWeek == null) {
        return const Text('No theme week available');
      }

      // 在这里设置断点 ⭐
      return Column(/* 渲染 UI */);
    },
  );
}
```

## 🚀 调试工作流程

### 完整的 ThemeWeeks 调试流程：

1. **启动后端调试**
   - 在 `theme-weeks.controller.ts` 的 `getCurrentThemeWeek` 方法设置断点

2. **启动前端调试**
   - 使用 "Flutter Run Windows (命令行方式)" 或命令行 + attach

3. **设置关键断点**
   - API 服务: `api_service.dart` → `getCurrentThemeWeek()`
   - 状态管理: `home_provider.dart` → `loadCurrentThemeWeek()`
   - UI 渲染: `theme_week_section.dart` → `build()`

4. **触发数据加载**
   - 重启应用或刷新首页
   - 观察数据流: 后端 API → 前端服务 → 状态管理 → UI

## 🔥 热重载 + 断点调试

在调试过程中，你依然可以：
- **热重载**: 保存文件 (Ctrl+S) 更新 UI
- **热重启**: 按 `Shift+Ctrl+F5` 重启应用但保持调试连接
- **完全重启**: 停止调试再重新启动

## 💡 调试技巧

### 1. 条件断点
右键断点 → "编辑断点" → 添加条件：
```dart
themeWeek != null
response.statusCode == 404
_currentThemeWeek?.title.contains('挑战')
```

### 2. 日志断点
右键断点 → "编辑断点" → 勾选 "记录消息"：
```dart
Current theme week: {_currentThemeWeek?.title}
API Response: {response.body}
```

### 3. 异常断点
在 BREAKPOINTS 面板中：
- 勾选 "Uncaught Exceptions" - 捕获未处理异常
- 勾选 "All Exceptions" - 捕获所有异常

## 🎉 现在开始调试！

1. 在 VSCode 中按 `F5`
2. 选择 **"Flutter Run Windows (命令行方式)"**
3. 在关键位置设置断点
4. 触发功能，观察数据流程！

这样你就可以完美结合命令行启动方式和 VSCode 的强大断点调试功能了！