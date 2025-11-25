# 统一错误处理系统使用指南

## 概述

前端的统一错误处理系统由两个核心文件组成：

1. **`error_codes.dart`** - 错误码常量定义（与后端 `error-codes.ts` 保持一致）
2. **`error_handler.dart`** - 错误处理器和错误信息映射

## 文件结构

```
frontend/lib/core/
├── constants/
│   └── error_codes.dart          # 错误码常量定义
└── utils/
    └── error_handler.dart         # 错误处理器
```

## 使用方式

### 1. 在 Service 层处理后端错误

**ExerciseService 示例：**

```dart
import '../utils/error_handler.dart';

class ExerciseService {
  Future<Map<String, dynamic>> getQuickRecommendation(...) async {
    try {
      final response = await http.post(...);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // ✅ 使用 ErrorHandler 解析后端错误响应
        final errorResponse = json.decode(response.body);
        final errorInfo = ErrorHandler.parseErrorResponse(errorResponse);
        throw errorInfo;  // 抛出 ErrorInfo 对象
      }
    } catch (e) {
      if (e is ErrorInfo) {
        rethrow;  // 重新抛出 ErrorInfo
      }
      // 网络错误等其他异常，包装成 ErrorInfo
      throw ErrorInfo(
        code: 1004,
        message: '网络连接失败，请检查网络后重试',
        category: 'NETWORK',
      );
    }
  }
}
```

### 2. 在 Provider 层处理错误

**WorkoutGuideProvider 示例：**

```dart
import '../utils/error_handler.dart';

class WorkoutGuideProvider {
  Future<Map<String, dynamic>?> generateWorkoutRecommendation() async {
    try {
      final response = await _exerciseService.getQuickRecommendation(...);
      return response;
    } catch (e) {
      String errorMessage;

      if (e is ErrorInfo) {
        // ✅ 直接使用 ErrorInfo 的用户友好消息
        errorMessage = e.message;
        debugPrint('Error code: ${e.code}, category: ${e.category}');
      } else {
        errorMessage = '操作失败，请稍后重试';
      }

      setError(errorMessage);
      return null;
    }
  }
}
```

### 3. 在 UI 层显示错误

**Widget 示例：**

```dart
// Provider 已经处理了错误，UI 直接显示
if (provider.error != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(provider.error!)),
  );
}
```

## 后端错误响应格式

后端返回的错误响应结构：

```json
{
  "success": false,
  "error": {
    "code": 10001,
    "message": "没有找到符合您所选条件的训练动作。建议: 尝试选择不同的场景...",
    "category": "BUSINESS",
    "timestamp": "2025-11-25T10:57:09.209Z",
    "context": {
      "operation": "generateQuickRecommendation",
      "resource": "exercises",
      "suggestions": ["尝试选择不同的场景", "..."]
    }
  },
  "path": "/api/v1/recommendations/quick",
  "method": "POST",
  "statusCode": 500
}
```

## ErrorInfo 对象

`ErrorInfo` 是统一的错误信息对象，包含以下字段：

```dart
class ErrorInfo {
  final int code;              // 错误码（与后端一致）
  final String message;         // 用户友好的中文错误消息
  final String category;        // 错误类别 (BUSINESS, SYSTEM, NETWORK, AUTH, VALIDATION)
  final String? timestamp;      // 错误时间戳
  final Map<String, dynamic>? context;  // 错误上下文（用于调试）
  final String? originalMessage;        // 后端原始错误消息（用于调试）

  // 便捷方法
  bool get isBusinessError => category == 'BUSINESS';
  bool get isSystemError => category == 'SYSTEM';
  bool get isAuthError => category == 'AUTH';
  bool get isValidationError => category == 'VALIDATION';
}
```

## 错误码范围

| 范围 | 类别 | 说明 |
|------|------|------|
| 1000-1999 | 通用错误 | 请求、验证等通用错误 |
| 2000-2999 | 用户相关 | 用户账号、信息相关错误 |
| 3000-3999 | 认证相关 | 登录、token、授权相关错误 |
| 4000-4999 | AI服务 | AI内容生成相关错误 |
| 5000-5999 | PayPal | 支付相关错误 |
| 6000-6999 | 数据库 | 数据库连接、查询相关错误 |
| 7000-7999 | 场景 | 场景管理相关错误 |
| 8000-8999 | 器材 | 器材管理相关错误 |
| 9000-9999 | 主题周 | 主题周活动相关错误 |
| 10000-10999 | 推荐 | **训练推荐相关错误** |
| 11000-11999 | 动作 | 训练动作相关错误 |
| 11500-11599 | 训练会话 | 训练记录相关错误 |
| 12000-12999 | 分享卡片 | 分享卡片相关错误 |
| 13000-13999 | 稀有度 | 稀有度计算相关错误 |
| 14000-14999 | 卡片 | 卡片生成相关错误 |
| 15000-15999 | AI识别 | AI图像识别相关错误 |
| 16000-16999 | 场景器材 | 场景器材管理相关错误 |

## 常用错误码示例

### 推荐相关错误 (10000-10999)

```dart
ErrorCodes.recommendationGenerationFailed  // 10000 - 训练计划生成失败
ErrorCodes.recommendationNoExercisesFound  // 10001 - 没有找到符合条件的训练动作
ErrorCodes.recommendationInvalidParameters // 10002 - 训练参数有误
ErrorCodes.recommendationReplaceFailed     // 10003 - 替换动作失败
ErrorCodes.recommendationSessionNotFound   // 10004 - 训练计划不存在
ErrorCodes.recommendationAlgorithmError    // 10005 - 推荐算法出错
```

### 认证相关错误 (3000-3999)

```dart
ErrorCodes.authInvalidToken        // 3000 - 登录状态无效
ErrorCodes.authTokenExpired        // 3001 - 登录已过期
ErrorCodes.authInvalidCredentials  // 3010 - 用户名或密码错误
```

## 特殊处理逻辑

### 1. 优先使用后端消息的错误类型

某些业务错误（如推荐系统、AI识别）后端会提供更详细的上下文信息和建议，这些错误会优先使用后端返回的详细消息：

- **推荐相关错误 (10000-10999)** - 后端会提供具体的建议（如"尝试选择不同的场景"）
- **AI识别相关错误 (15000-15999)** - 后端会提供详细的识别结果

```dart
// ErrorHandler 内部逻辑
static bool _shouldUseBackendMessage(int errorCode) {
  if (errorCode >= 10000 && errorCode <= 10999) return true;  // 推荐相关
  if (errorCode >= 15000 && errorCode <= 15999) return true;  // AI识别相关
  return false;
}
```

### 2. 默认错误消息

如果找不到特定的错误码映射，`ErrorHandler` 会根据错误码范围返回合适的默认消息。

## 调试技巧

### 查看完整错误信息

```dart
if (e is ErrorInfo) {
  debugPrint(e.toDebugString());
  // 输出：
  // ErrorInfo {
  //   code: 10001
  //   message: 没有找到符合您所选条件的训练动作...
  //   category: BUSINESS
  //   timestamp: 2025-11-25T10:57:09.209Z
  //   originalMessage: RECOMMENDATION_NO_EXERCISES_FOUND
  //   context: {...}
  // }
}
```

### 判断错误类型

```dart
if (e is ErrorInfo) {
  if (e.isBusinessError) {
    // 业务错误，显示给用户
    showErrorDialog(e.message);
  } else if (e.isAuthError) {
    // 认证错误，跳转到登录页
    navigateToLogin();
  } else if (e.isSystemError) {
    // 系统错误，记录日志
    logError(e);
  }
}
```

## 维护指南

### 添加新的错误码

1. **后端** - 在 `backend/src/exception/error-codes.ts` 添加新的错误码定义
2. **前端** - 在 `frontend/lib/core/constants/error_codes.dart` 添加对应的常量
3. **前端** - 在 `frontend/lib/core/utils/error_handler.dart` 的 `_errorMessages` Map 中添加中文错误消息

### 保持前后端同步

- 错误码的数值必须完全一致
- 错误码范围的划分必须一致
- 定期检查两边的错误码定义是否同步

## 最佳实践

1. ✅ **Service 层**：解析后端错误，抛出 `ErrorInfo` 对象
2. ✅ **Provider 层**：捕获 `ErrorInfo`，提取用户友好的消息
3. ✅ **UI 层**：显示 Provider 处理后的错误消息
4. ✅ **业务错误**：显示给用户，引导用户如何解决
5. ✅ **系统错误**：记录日志，显示通用错误提示
6. ✅ **网络错误**：提示用户检查网络连接
7. ✅ **认证错误**：引导用户重新登录

## 注意事项

- ❌ 不要在 UI 层直接解析后端错误响应
- ❌ 不要向用户显示技术性的错误信息（如堆栈跟踪）
- ❌ 不要在多个地方重复编写错误码映射逻辑
- ✅ 始终使用 `ErrorHandler` 进行统一处理
- ✅ 业务错误要提供明确的解决建议
- ✅ 记录详细的调试信息（使用 `debugPrint`）
