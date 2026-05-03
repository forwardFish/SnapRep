# SnapRep Flutter 前端开发完整指南

## 📋 目录结构分析

### 核心架构概览

本项目采用清晰的分层架构：

- **lib/main.dart**: 应用入口点，配置Provider和路由
- **lib/core/**: 核心模块
  - config/: 配置文件(API地址等)
  - models/: 数据模型定义
  - providers/: 状态管理
  - services/: 服务层(API调用)
- **lib/features/**: 功能模块(按业务划分)
  - auth/: 认证登录
  - home/: 首页
  - exercises/: 运动相关
  - workout_guide/: 训练引导
- **lib/shared/**: 共享组件
  - widgets/: 可复用的UI组件
- **lib/routes/**: 路由配置

## 🏗️ Flutter 基础概念

### 1. Widget 系统

Flutter 中一切都是 Widget。Widget 分为两种主要类型：

#### StatelessWidget (无状态组件)

无状态组件不会改变，一旦创建就不会变化：

```dart
class ThemeWeekSection extends StatelessWidget {
  final ThemeWeek? currentThemeWeek;
  final bool isLoading;

  const ThemeWeekSection({
    super.key,
    this.currentThemeWeek,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: isLoading
        ? CircularProgressIndicator()
        : _buildContent(),
    );
  }
}
```

#### StatefulWidget (有状态组件)

有状态组件可以改变状态，会动态更新UI：

```dart
class WorkoutGuideStep1Page extends StatefulWidget {
  const WorkoutGuideStep1Page({super.key});

  @override
  State<WorkoutGuideStep1Page> createState() => _WorkoutGuideStep1PageState();
}

class _WorkoutGuideStep1PageState extends State<WorkoutGuideStep1Page> {
  String? _selectedMode;  // 可变状态

  @override
  void initState() {
    super.initState();
    // 初始化逻辑
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('选择模式')),
      body: _buildModeSelection(),
    );
  }
}
```

### 2. Widget 生命周期

```dart
class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  void initState() {
    super.initState();
    // Widget创建时调用，只执行一次
    print('Widget初始化');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 依赖变化时调用
  }

  @override
  Widget build(BuildContext context) {
    // 构建UI，每次状态改变都会调用
    return Container();
  }

  @override
  void dispose() {
    super.dispose();
    // Widget销毁时调用，用于清理资源
    print('Widget销毁');
  }
}
```

## 📊 状态管理 - Provider 模式

### Provider 设置

在 main.dart 中设置Provider：

```dart
class SnapRepApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutGuideProvider()),
        ChangeNotifierProvider(create: (_) => WorkoutResultProvider()),
      ],
      child: MaterialApp(
        // ... 应用配置
      ),
    );
  }
}
```

### Provider 实现

```dart
class HomeProvider extends ChangeNotifier {
  // 私有状态
  bool _isLoading = false;
  List<Scenario> _scenarios = [];
  String? _error;

  // 公共访问器
  bool get isLoading => _isLoading;
  List<Scenario> get scenarios => _scenarios;
  String? get error => _error;

  // 状态更新方法
  Future<void> loadScenarios() async {
    _setLoading(true);

    try {
      final response = await ApiService.getScenarios();
      _scenarios = response;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners(); // 通知UI更新
  }
}
```

### 在 Widget 中使用 Provider

```dart
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return CircularProgressIndicator();
          }

          if (provider.error != null) {
            return Text('错误: ${provider.error}');
          }

          return ListView.builder(
            itemCount: provider.scenarios.length,
            itemBuilder: (context, index) {
              return ScenarioCard(scenario: provider.scenarios[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 触发数据加载
          context.read<HomeProvider>().loadScenarios();
        },
        child: Icon(Icons.refresh),
      ),
    );
  }
}
```

## 🌐 后端接口集成

### API 服务配置

```dart
// api_config.dart
class ApiConfig {
  static const String devBaseUrl = 'http://192.168.1.110:3000';
  static const String prodBaseUrl = 'https://your-production-url.com';

  static String get baseUrl {
    return kDebugMode ? devBaseUrl : prodBaseUrl;
  }
}

// api_service.dart
class ApiService {
  static final _client = http.Client();
  static const _timeout = Duration(seconds: 30);

  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (SupabaseService.instance.isAuthenticated)
      'Authorization': 'Bearer ${SupabaseService.instance.accessToken}',
  };

  // GET 请求示例
  static Future<List<Exercise>> getExercises() async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/exercises'),
            headers: _headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Exercise.fromJson(json)).toList();
      } else {
        throw ApiException('获取运动列表失败');
      }
    } catch (e) {
      throw ApiException('网络请求失败: $e');
    }
  }

  // POST 请求示例
  static Future<WorkoutSession> createWorkoutSession({
    required String scenarioId,
    required List<String> exerciseIds,
  }) async {
    final body = json.encode({
      'scenario_id': scenarioId,
      'exercise_ids': exerciseIds,
    });

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/workout-sessions'),
            headers: _headers,
            body: body,
          )
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return WorkoutSession.fromJson(json.decode(response.body));
      } else {
        throw ApiException('创建训练会话失败');
      }
    } catch (e) {
      throw ApiException('创建失败: $e');
    }
  }
}
```

### 数据模型与序列化

```dart
@JsonSerializable()
class Exercise {
  final String id;
  final String name;
  final String description;

  @JsonKey(name: 'duration_seconds')
  final int durationSeconds;

  @JsonKey(name: 'demo_video_url')
  final String? demoVideoUrl;

  @JsonKey(name: 'primary_muscle')
  final Muscle primaryMuscle;

  final Difficulty difficulty;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.durationSeconds,
    this.demoVideoUrl,
    required this.primaryMuscle,
    required this.difficulty,
  });

  // 自动生成的序列化方法
  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseToJson(this);

  // 业务逻辑方法
  String get durationText => '${durationSeconds}秒';
  bool get hasVideo => demoVideoUrl != null && demoVideoUrl!.isNotEmpty;
}
```

### 生成序列化代码

```bash
# 一次性生成
flutter packages pub run build_runner build

# 监听文件变化自动生成
flutter packages pub run build_runner watch
```

## 🎨 自定义绘图 - CustomPainter

### 基础绘图示例 - 圆形进度条

```dart
import 'dart:math' as math;

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    this.backgroundColor = Colors.grey,
    this.progressColor = Colors.blue,
    this.strokeWidth = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 背景圆环
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // 进度圆弧
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // 从顶部开始
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return progress != oldDelegate.progress ||
           backgroundColor != oldDelegate.backgroundColor ||
           progressColor != oldDelegate.progressColor;
  }
}

// 使用CustomPainter
class ProgressWidget extends StatelessWidget {
  final double progress;

  const ProgressWidget({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: CircularProgressPainter(
          progress: progress,
          backgroundColor: Colors.grey[300]!,
          progressColor: const Color(0xFFFFD700),
        ),
        child: Center(
          child: Text(
            '${(progress * 100).toInt()}%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
```

## 🛣️ 路由与导航

### 路由配置

```dart
class AppRoutes {
  static const String splash = '/';
  static const String home = '/home';
  static const String workoutGuide = '/workout-guide';
  static const String exerciseDetail = '/exercise-detail';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => const SplashPage(),
      home: (context) => const AuthWrapper(),
      workoutGuide: (context) => const WorkoutGuidePage(),
      exerciseDetail: (context) => const ExerciseDetailPage(),
    };
  }

  // 导航辅助方法
  static Future<void> navigateToExerciseDetail(
    BuildContext context,
    String exerciseId,
  ) async {
    await Navigator.pushNamed(
      context,
      exerciseDetail,
      arguments: {'exerciseId': exerciseId},
    );
  }

  // 替换当前页面
  static Future<void> replaceWith(
    BuildContext context,
    String routeName,
  ) async {
    await Navigator.pushReplacementNamed(context, routeName);
  }
}
```

### 页面间传递数据

```dart
// 发送数据
Navigator.pushNamed(
  context,
  '/exercise-detail',
  arguments: {
    'exerciseId': '123',
    'fromPage': 'home',
  },
);

// 接收数据
class ExerciseDetailPage extends StatefulWidget {
  @override
  _ExerciseDetailPageState createState() => _ExerciseDetailPageState();
}

class _ExerciseDetailPageState extends State<ExerciseDetailPage> {
  String? exerciseId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      exerciseId = args['exerciseId'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('运动详情'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: exerciseId != null
        ? ExerciseContent(exerciseId: exerciseId!)
        : Center(child: Text('无效的运动ID')),
    );
  }
}
```

## ⚡ 性能优化技巧

### 1. 列表性能优化

```dart
// 使用 ListView.builder 而不是 ListView
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return ItemWidget(item: items[index]);
  },
);

// 对于大量数据使用 ListView.separated
ListView.separated(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(item: items[index]),
  separatorBuilder: (context, index) => const Divider(),
);
```

### 2. 图片缓存优化

```dart
// 使用 cached_network_image 进行图片缓存
CachedNetworkImage(
  imageUrl: imageUrl,
  memCacheWidth: 300, // 限制内存中的图片宽度
  memCacheHeight: 300, // 限制内存中的图片高度
  maxWidthDiskCache: 600, // 磁盘缓存最大宽度
  maxHeightDiskCache: 600, // 磁盘缓存最大高度
)
```

### 3. Widget重建优化

```dart
// 使用 const 构造函数
const Text('固定文本内容');

// 使用 RepaintBoundary 隔离重绘
RepaintBoundary(
  child: ExpensiveWidget(),
);
```

## 📚 常用资源

### 官方文档
- [Flutter 官方文档](https://docs.flutter.dev/)
- [Dart 语言指南](https://dart.dev/guides)
- [Material Design](https://material.io/design)

### 推荐包
- **provider**: 状态管理
- **http / dio**: 网络请求
- **cached_network_image**: 图片缓存
- **shared_preferences**: 本地存储
- **go_router**: 路由管理

## 🎯 实战项目总结

通过分析 SnapRep 项目，一个典型的 Flutter 应用架构包含：

1. **清晰的目录结构**: core、features、shared的分层设计
2. **统一的状态管理**: Provider模式管理应用状态
3. **完善的API集成**: HTTP服务层与后端NestJS API交互
4. **可复用的UI组件**: 共享Widget组件库
5. **类型安全的数据模型**: JSON序列化与反序列化
6. **灵活的路由系统**: 命名路由与参数传递

这个指南涵盖了从基础概念到高级技巧的完整Flutter开发知识体系，帮助你快速上手并精通Flutter应用开发！

---

*📝 本指南基于 SnapRep 项目实际代码分析编写*
