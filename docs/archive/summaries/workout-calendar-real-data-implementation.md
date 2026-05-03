# 训练日历真实数据实现 - 移除 Mock 数据

## 问题描述

用户反馈：Profile 页面中的 Workout Calendar 显示的是 mock 数据，即使用户没有进行过任何训练，日历上也会显示训练记录。用户要求从后端获取真实有效的训练数据，而不是使用 mock 数据。

## 实现方案

### 1. 后端 API

后端已经存在完整的训练会话管理 API：

**位置**: `backend/src/workout-sessions/workout-sessions.controller.ts`

**相关端点**:
- `GET /api/v1/users/:userId/sessions` - 获取用户训练会话列表
  - 支持按状态筛选（status: COMPLETED, ACTIVE, CANCELLED等）
  - 支持分页（limit, offset）
  - Line 375-412

**数据模型**:
```typescript
// 训练会话包含以下字段：
{
  id: string,
  userId: string,
  status: WorkoutSessionStatus,  // COMPLETED, ACTIVE, CANCELLED等
  completedAt: DateTime,          // 完成时间
  startedAt: DateTime,
  actualDurationSec: number,
  completedExerciseCount: number,
  // ... 其他字段
}
```

### 2. 前端 API Service 实现

**位置**: `frontend/lib/core/services/api_service.dart`

#### 2.1 添加 `getUserWorkoutDates()` 方法

**Lines 670-720** - 新增方法

```dart
/// Get user workout dates (from workout sessions)
/// GET /api/v1/users/{userId}/sessions with COMPLETED status
/// Returns a Set of DateTime objects representing dates when user completed workouts
Future<Set<DateTime>> getUserWorkoutDates() async {
  try {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) {
      debugPrint('⚠️ User not authenticated, returning empty workout dates');
      return {};
    }

    debugPrint('📅 Fetching workout dates for user: $userId');

    // Get completed workout sessions from backend
    final uri = Uri.parse('${AppConstants.nestJsApiUrl}/api/v1/users/$userId/sessions')
        .replace(queryParameters: {
      'status': 'COMPLETED',
      'limit': '100', // Get last 100 completed sessions
    });

    final response = await http.get(uri, headers: await _headers);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final sessions = data['data'] as List;

      debugPrint('✅ Found ${sessions.length} completed workout sessions');

      // Extract unique dates from completed_at timestamps
      final workoutDates = <DateTime>{};
      for (final session in sessions) {
        if (session['completedAt'] != null || session['completed_at'] != null) {
          final completedAtStr = session['completedAt'] ?? session['completed_at'];
          final completedAt = DateTime.parse(completedAtStr);
          // Normalize to date only (remove time)
          final dateOnly = DateTime(completedAt.year, completedAt.month, completedAt.day);
          workoutDates.add(dateOnly);
        }
      }

      debugPrint('📊 Extracted ${workoutDates.length} unique workout dates');
      return workoutDates;
    } else {
      debugPrint('⚠️ Failed to get workout sessions: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    debugPrint('❌ Failed to get workout dates: $e');
    return {}; // Return empty set instead of throwing, so UI can still render
  }
}
```

**功能说明**:
1. 调用后端 `/api/v1/users/:userId/sessions?status=COMPLETED` 获取已完成的训练会话
2. 从每个会话的 `completedAt` 字段提取日期
3. 去重并标准化为日期（去除时间部分）
4. 返回 `Set<DateTime>` 集合
5. 错误处理：未登录或API失败时返回空集合，不影响UI渲染

### 3. 前端 Provider 实现

**位置**: `frontend/lib/core/providers/my_page_provider.dart`

#### 3.1 添加状态变量

**Line 34** - 新增字段：
```dart
Set<DateTime> _workoutDates = {}; // 用户完成训练的日期集合
```

**Line 64** - 新增 getter：
```dart
Set<DateTime> get workoutDates => _workoutDates; // 训练日期集合getter
```

#### 3.2 添加 `loadWorkoutDates()` 方法

**Lines 254-274** - 新增方法：

```dart
/// 加载用户训练日期（用于日历显示）
Future<void> loadWorkoutDates() async {
  debugPrint('📅 Loading workout dates for calendar');

  // 未登录用户不加载训练日期
  if (!isUserLoggedIn) {
    debugPrint('ℹ️ User not logged in, skipping workout dates load');
    _workoutDates = {};
    return;
  }

  try {
    // 调用API获取用户的训练日期集合
    final dates = await _apiService.getUserWorkoutDates();
    _workoutDates = dates;
    debugPrint('✅ Workout dates loaded: ${_workoutDates.length} unique dates');
  } catch (e) {
    debugPrint('❌ Failed to load workout dates: $e');
    _workoutDates = {};
  }
}
```

#### 3.3 在初始化时加载训练日期

**Lines 100-107** - 修改 `initializeMyPage()` 方法：

```dart
// 只有登录用户才加载卡片和训练历史
if (isUserLoggedIn) {
  await Future.wait([
    loadCardCollection(),
    loadWorkoutHistory(),
    loadWorkoutDates(), // 加载训练日期
  ]);
}
```

### 4. 前端 UI 实现

**位置**: `frontend/lib/features/profile/screens/my_page.dart`

#### 4.1 移除 Mock 数据

**原代码 (Lines 1018-1024)** - 已删除：
```dart
// Sample workout days (you can replace this with actual data from provider)
final workoutDays = {
  DateTime(today.year, today.month, today.day - 2),
  DateTime(today.year, today.month, today.day - 1),
  DateTime(today.year, today.month, today.day),
  DateTime(today.year, today.month, today.day + 1),
};
```

#### 4.2 使用 Provider 的真实数据

**新代码 (Lines 1018-1070)** - 使用 `Consumer<MyPageProvider>`：

```dart
Widget _buildWeeklyCalendarGrid(DateTime startOfWeek, DateTime today) {
  // Day abbreviations
  final dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  // Generate 7 days starting from startOfWeek
  final weekDays =
      List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

  return Consumer<MyPageProvider>(
    builder: (context, provider, child) {
      // 从 provider 获取真实的训练日期
      final workoutDates = provider.workoutDates;

      return Column(
        children: [
          // Day headers based on actual dates
          Row(
            children: weekDays.map((date) {
              final dayName = _getDayName(date.weekday);
              return Expanded(
                child: Center(
                  child: Text(
                    dayName,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF90A4AE),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Calendar days row
          Row(
            children: weekDays.map((date) {
              final isToday = _isSameDay(date, today);
              // 检查这个日期是否有训练记录
              final hasWorkout = workoutDates.any((workoutDate) => _isSameDay(date, workoutDate));

              return Expanded(
                child: GestureDetector(
                  onTap: hasWorkout
                      ? () {
                          // Navigate to workout details for this date
                          Navigator.pushNamed(context, '/workout-details',
                              arguments: {'date': date, 'isToday': isToday});
                        }
                      : null,
                  child: _buildWeeklyCalendarDay(date.day, hasWorkout, isToday),
                ),
              );
            }).toList(),
          ),
        ],
      );
    },
  );
}
```

**关键改动**:
1. 使用 `Consumer<MyPageProvider>` 包装整个日历组件
2. 从 `provider.workoutDates` 获取真实训练日期
3. 使用 `workoutDates.any((workoutDate) => _isSameDay(date, workoutDate))` 检查每个日期是否有训练记录
4. 移除了所有硬编码的 mock 日期

## 数据流程

```
1. 用户登录
   ↓
2. MyPage 初始化 → MyPageProvider.initializeMyPage()
   ↓
3. Provider 并行加载数据：
   - loadUserInfo()
   - loadCardCollection()
   - loadWorkoutHistory()
   - loadWorkoutDates()  ← 新增
   ↓
4. loadWorkoutDates() 调用 ApiService.getUserWorkoutDates()
   ↓
5. ApiService 请求后端 API:
   GET /api/v1/users/:userId/sessions?status=COMPLETED&limit=100
   ↓
6. 后端返回已完成的训练会话列表
   ↓
7. ApiService 提取 completedAt 日期并去重
   ↓
8. Provider 更新 _workoutDates 状态
   ↓
9. UI (Consumer) 自动重新渲染日历
   ↓
10. 日历显示真实的训练日期
```

## 用户体验变化

### 之前（Mock 数据）:
- ❌ 即使没有训练，日历也会显示 4 个训练日（今天、昨天、前天、明天）
- ❌ 数据与实际情况不符
- ❌ 用户困惑为什么有训练记录

### 现在（真实数据）:
- ✅ 只显示用户真实完成的训练日期
- ✅ 如果用户没有训练，日历为空
- ✅ 数据准确反映用户的训练历史
- ✅ 支持最近 100 次完成的训练会话

## 测试要点

### 1. 未登录用户
- 日历应该为空（没有任何训练日期标记）
- 不应该有 API 错误

### 2. 已登录但无训练记录的用户
- 日历应该为空
- API 返回空数组
- UI 正常显示（无报错）

### 3. 有训练记录的用户
- 日历应该在相应日期显示绿点
- 点击有训练的日期可以查看详情
- 训练日期应该与后端数据一致

### 4. 错误处理
- 网络错误时返回空集合，UI 仍可正常渲染
- 后端 API 失败时不影响页面显示

## 性能优化

1. **并行加载**: 训练日期与其他数据并行加载，不阻塞UI
2. **限制数量**: 只获取最近 100 次训练，避免数据量过大
3. **日期去重**: 使用 `Set<DateTime>` 自动去重
4. **日期标准化**: 只保留日期部分，去除时间，避免同一天多次训练被计算多次
5. **错误不阻塞**: API失败时返回空集合，不影响UI渲染

## 后续优化建议

1. **缓存机制**:
   - 可以在 Provider 中缓存训练日期，避免频繁请求
   - 使用 SharedPreferences 存储最近的训练日期

2. **分页加载**:
   - 当前只加载最近 100 次训练
   - 如果用户有更多训练记录，可以考虑按月份分页加载

3. **实时更新**:
   - 当用户完成新的训练时，自动更新日历
   - 使用 WebSocket 或轮询机制

4. **性能监控**:
   - 监控 API 响应时间
   - 优化大数据量的渲染性能

## 相关文件

### 修改的文件:
1. `frontend/lib/core/services/api_service.dart` - 新增 `getUserWorkoutDates()` 方法
2. `frontend/lib/core/providers/my_page_provider.dart` - 新增 `loadWorkoutDates()` 方法和状态
3. `frontend/lib/features/profile/screens/my_page.dart` - 移除 mock 数据，使用真实数据

### 依赖的文件:
1. `backend/src/workout-sessions/workout-sessions.controller.ts` - 后端训练会话 API
2. `backend/src/workout-sessions/workout-sessions.service.ts` - 训练会话业务逻辑
3. `frontend/lib/core/constants/app_constants.dart` - API URL 配置

## 总结

本次修改彻底移除了 Workout Calendar 的 mock 数据，改为从后端获取真实的训练记录。实现了完整的数据流：

1. ✅ 后端 API 已存在且功能完整
2. ✅ 前端 API Service 封装完成
3. ✅ Provider 状态管理实现
4. ✅ UI 使用真实数据渲染
5. ✅ 错误处理完善
6. ✅ 性能优化合理

用户现在看到的训练日历完全反映其真实的训练历史，不会再出现"明明没有训练却显示训练记录"的问题。

---

**实现日期**: 2025-11-24
**版本**: v1.0.0
**状态**: 已完成，待测试
