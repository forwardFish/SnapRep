import 'package:flutter/foundation.dart';
import '../constants/error_codes.dart';

/// 统一的错误处理器
/// 负责将后端返回的错误码转换为用户友好的业务错误信息
class ErrorHandler {
  /// 根据错误码获取用户友好的错误消息
  ///
  /// [errorCode] 后端返回的错误码
  /// [backendMessage] 后端返回的原始错误消息（可选，某些业务错误会直接使用后端消息）
  ///
  /// 返回用户友好的中文错误消息
  static String getErrorMessage(int errorCode, {String? backendMessage}) {
    // 对于某些业务错误，如果后端提供了详细的错误消息，优先使用后端消息
    final useBackendMessage = _shouldUseBackendMessage(errorCode);
    if (useBackendMessage && backendMessage != null && backendMessage.isNotEmpty) {
      return backendMessage;
    }

    // 否则使用前端定义的错误消息映射
    return _errorMessages[errorCode] ?? _getDefaultErrorMessage(errorCode);
  }

  /// 判断是否应该直接使用后端返回的错误消息
  /// 某些业务错误（如推荐系统、AI识别等）后端会提供更详细的上下文信息
  static bool _shouldUseBackendMessage(int errorCode) {
    // 推荐相关错误 (10000-10999) - 后端会提供详细的建议信息
    if (errorCode >= 10000 && errorCode <= 10999) return true;

    // AI识别相关错误 (15000-15999) - 后端会提供详细的识别结果
    if (errorCode >= 15000 && errorCode <= 15999) return true;

    return false;
  }

  /// 根据错误码范围返回默认错误消息
  static String _getDefaultErrorMessage(int errorCode) {
    if (errorCode >= 1000 && errorCode < 2000) {
      return 'Request failed, please try again later';
    } else if (errorCode >= 2000 && errorCode < 3000) {
      return 'User information error, please login again';
    } else if (errorCode >= 3000 && errorCode < 4000) {
      return 'Session expired, please login again';
    } else if (errorCode >= 4000 && errorCode < 5000) {
      return 'AI service temporarily unavailable, please try again later';
    } else if (errorCode >= 5000 && errorCode < 6000) {
      return 'Payment service error, please contact support';
    } else if (errorCode >= 6000 && errorCode < 7000) {
      return 'Data loading failed, please try again later';
    } else if (errorCode >= 7000 && errorCode < 8000) {
      return 'Scenario data loading failed';
    } else if (errorCode >= 8000 && errorCode < 9000) {
      return 'Equipment data loading failed';
    } else if (errorCode >= 9000 && errorCode < 10000) {
      return 'Theme week activity error';
    } else if (errorCode >= 10000 && errorCode < 11000) {
      return 'Workout recommendation generation failed, please try again';
    } else if (errorCode >= 11000 && errorCode < 12000) {
      return 'Exercise data loading failed';
    } else if (errorCode >= 12000 && errorCode < 13000) {
      return 'Share card generation failed';
    } else if (errorCode >= 13000 && errorCode < 14000) {
      return 'Rarity calculation failed';
    } else if (errorCode >= 14000 && errorCode < 15000) {
      return 'Card generation failed';
    } else if (errorCode >= 15000 && errorCode < 16000) {
      return 'AI recognition failed, please try again';
    } else if (errorCode >= 16000 && errorCode < 17000) {
      return 'Scenario equipment data loading failed';
    } else {
      return 'Operation failed, please try again later';
    }
  }

  /// 错误消息映射表
  /// 将错误码映射为用户友好的口语化错误消息
  static final Map<int, String> _errorMessages = {
    // ============================================
    // 通用错误 (1000-1999)
    // ============================================
    ErrorCodes.common['BAD_REQUEST']!.code: 'Invalid request parameters. Please check and try again.',
    ErrorCodes.common['UNAUTHORIZED']!.code: 'You need to log in to access this feature.',
    ErrorCodes.common['FORBIDDEN']!.code: 'You don\'t have permission to perform this action.',
    ErrorCodes.common['NOT_FOUND']!.code: 'The requested resource was not found.',
    ErrorCodes.common['INTERNAL_SERVER_ERROR']!.code: 'Something went wrong on our server. Please try again later.',
    ErrorCodes.common['VALIDATION_ERROR']!.code: 'Please check your input and try again.',

    // ============================================
    // 用户相关错误 (2000-2999)
    // ============================================
    ErrorCodes.user['NOT_FOUND']!.code: 'The user account was not found.',
    ErrorCodes.user['ALREADY_EXISTS']!.code: 'This user account already exists.',
    ErrorCodes.user['INVALID_CREDENTIALS']!.code: 'Invalid username or password. Please try again.',
    ErrorCodes.user['ACCOUNT_DISABLED']!.code: 'Your account has been disabled. Please contact support.',
    ErrorCodes.user['EMAIL_EXISTS']!.code: 'This email address is already registered.',
    ErrorCodes.user['EMAIL_NOT_EXISTS']!.code: 'We couldn\'t find an account with this email address.',
    ErrorCodes.user['PASSWORD_INVALID']!.code: 'Password format is incorrect. Please check the requirements.',
    ErrorCodes.user['VERIFICATION_CODE_INVALID']!.code: 'The verification code is invalid or has expired.',
    ErrorCodes.user['EMAIL_SEND_FAIL']!.code: 'We couldn\'t send the email. Please try again later.',
    ErrorCodes.user['INVALID_USER_ID']!.code: 'Invalid user ID.',

    // ============================================
    // 认证相关错误 (3000-3999)
    // ============================================
    ErrorCodes.auth['INVALID_TOKEN']!.code: 'Your session has expired. Please log in again.',
    ErrorCodes.auth['TOKEN_EXPIRED']!.code: 'Your login session has expired. Please log in again.',
    ErrorCodes.auth['REFRESH_TOKEN_INVALID']!.code: 'Your session is invalid. Please log in again.',
    ErrorCodes.auth['UNAUTHORIZED_ACCESS']!.code: 'You need to log in to access this feature.',
    ErrorCodes.auth['REGISTRATION_FAILED']!.code: 'Registration failed. Please try again later.',
    ErrorCodes.auth['USER_ACCOUNT_NOT_FOUND']!.code: 'Account not found.',
    ErrorCodes.auth['PASSWORD_UPDATE_FAILED']!.code: 'Failed to update password. Please try again.',
    ErrorCodes.auth['USER_INFO_FETCH_FAILED']!.code: 'Failed to retrieve user information.',
    ErrorCodes.auth['EMAIL_SEND_FAILED']!.code: 'Failed to send email.',
    ErrorCodes.auth['PASSWORD_RESET_FAILED']!.code: 'Failed to reset password. Please try again.',
    ErrorCodes.auth['INVALID_CREDENTIALS']!.code: 'Invalid username or password.',
    ErrorCodes.auth['OTP_VERIFICATION_FAILED']!.code: 'Verification code is incorrect.',
    ErrorCodes.auth['USER_DATA_PROCESSING_FAILED']!.code: 'Failed to process user data.',
    ErrorCodes.auth['SUPABASE_API_ERROR']!.code: 'Authentication service error.',
    ErrorCodes.auth['SUPABASE_LOGIN_FAILED']!.code: 'Login failed. Please check your credentials.',
    ErrorCodes.auth['SUPABASE_SEND_OTP_FAILED']!.code: 'Failed to send verification code.',
    ErrorCodes.auth['GET_USER_INFO_FAILED']!.code: 'Failed to get user information.',
    ErrorCodes.auth['LOGOUT_FAILED']!.code: 'Failed to log out.',

    // ============================================
    // AI服务相关错误 (4000-4999)
    // ============================================
    ErrorCodes.ai['UNSUPPORTED_MODEL']!.code: 'This AI model is not supported.',
    ErrorCodes.ai['CONTENT_GENERATION_FAILED']!.code: 'AI content generation failed.',
    ErrorCodes.ai['UI_GENERATION_FAILED']!.code: 'AI interface generation failed.',
    ErrorCodes.ai['JOB_NOT_FOUND']!.code: 'AI task not found.',
    ErrorCodes.ai['JOB_CREATION_FAILED']!.code: 'Failed to create AI task.',
    ErrorCodes.ai['JOB_UPDATE_FAILED']!.code: 'Failed to update AI task.',

    // ============================================
    // PayPal相关错误 (5000-5999)
    // ============================================
    ErrorCodes.paypal['SUBSCRIPTION_FETCH_FAILED']!.code: 'Failed to retrieve subscription information.',
    ErrorCodes.paypal['SUBSCRIPTION_CANCEL_FAILED']!.code: 'Failed to cancel subscription.',
    ErrorCodes.paypal['WEBHOOK_VERIFICATION_FAILED']!.code: 'Payment verification failed.',
    ErrorCodes.paypal['SUBSCRIPTION_CREATE_FAILED']!.code: 'Failed to create subscription.',
    ErrorCodes.paypal['ORDER_CAPTURE_FAILED']!.code: 'Payment processing failed.',

    // ============================================
    // 数据库相关错误 (6000-6999)
    // ============================================
    ErrorCodes.database['CONNECTION_ERROR']!.code: 'Database connection failed. Please try again later.',
    ErrorCodes.database['QUERY_ERROR']!.code: 'Data retrieval failed. Please try again later.',
    ErrorCodes.database['TRANSACTION_ERROR']!.code: 'Data operation failed. Please try again later.',

    // ============================================
    // 场景相关错误 (7000-7999)
    // ============================================
    ErrorCodes.scenario['NOT_FOUND']!.code: 'The workout scenario was not found.',
    ErrorCodes.scenario['ALREADY_EXISTS']!.code: 'This workout scenario already exists.',
    ErrorCodes.scenario['CODE_EXISTS']!.code: 'Scenario code already exists.',
    ErrorCodes.scenario['CREATE_FAILED']!.code: 'Failed to create workout scenario.',
    ErrorCodes.scenario['UPDATE_FAILED']!.code: 'Failed to update workout scenario.',
    ErrorCodes.scenario['DELETE_FAILED']!.code: 'Failed to delete workout scenario.',
    ErrorCodes.scenario['FETCH_FAILED']!.code: 'Failed to load workout scenario.',
    ErrorCodes.scenario['LIST_FAILED']!.code: 'Failed to load workout scenarios.',
    ErrorCodes.scenario['COUNT_FAILED']!.code: 'Failed to count workout scenarios.',
    ErrorCodes.scenario['INVALID_CODE']!.code: 'Invalid scenario code.',
    ErrorCodes.scenario['INACTIVE_SCENARIO']!.code: 'This workout scenario is currently unavailable.',

    // ============================================
    // 器材相关错误 (8000-8999)
    // ============================================
    ErrorCodes.equipment['NOT_FOUND']!.code: 'The equipment was not found.',
    ErrorCodes.equipment['ALREADY_EXISTS']!.code: 'This equipment already exists.',
    ErrorCodes.equipment['CODE_EXISTS']!.code: 'Equipment code already exists.',
    ErrorCodes.equipment['CREATE_FAILED']!.code: 'Failed to add equipment.',
    ErrorCodes.equipment['UPDATE_FAILED']!.code: 'Failed to update equipment.',
    ErrorCodes.equipment['DELETE_FAILED']!.code: 'Failed to remove equipment.',
    ErrorCodes.equipment['FETCH_FAILED']!.code: 'Failed to load equipment information.',
    ErrorCodes.equipment['LIST_FAILED']!.code: 'Failed to load equipment list.',
    ErrorCodes.equipment['COUNT_FAILED']!.code: 'Failed to count equipment.',
    ErrorCodes.equipment['INVALID_CODE']!.code: 'Invalid equipment code.',
    ErrorCodes.equipment['INACTIVE_EQUIPMENT']!.code: 'This equipment is currently unavailable.',

    // ============================================
    // 主题周相关错误 (9000-9999)
    // ============================================
    ErrorCodes.themeWeek['NOT_FOUND']!.code: 'The challenge was not found.',
    ErrorCodes.themeWeek['ALREADY_JOINED']!.code: 'You have already joined this challenge.',
    ErrorCodes.themeWeek['ENDED']!.code: 'This challenge has ended.',
    ErrorCodes.themeWeek['NOT_STARTED']!.code: 'This challenge hasn\'t started yet.',
    ErrorCodes.themeWeek['PARTICIPATION_FAILED']!.code: 'Failed to join the challenge.',
    ErrorCodes.themeWeek['UPDATE_FAILED']!.code: 'Failed to update challenge.',
    ErrorCodes.themeWeek['CREATE_FAILED']!.code: 'Failed to create challenge.',
    ErrorCodes.themeWeek['FETCH_FAILED']!.code: 'Failed to load challenge information.',

    // ============================================
    // 推荐相关错误 (10000-10999)
    // ============================================
    // 注意：推荐相关错误优先使用后端返回的详细消息（包含具体建议）
    ErrorCodes.recommendation['GENERATION_FAILED']!.code: 'Failed to generate workout plan. Please try again.',
    ErrorCodes.recommendation['NO_EXERCISES_FOUND']!.code: 'No exercises found matching your criteria. Try adjusting your preferences.',
    ErrorCodes.recommendation['INVALID_PARAMETERS']!.code: 'Invalid workout parameters. Please check your selections.',
    ErrorCodes.recommendation['REPLACE_FAILED']!.code: 'Failed to replace exercise. Please try again.',
    ErrorCodes.recommendation['SESSION_NOT_FOUND']!.code: 'Workout plan not found.',
    ErrorCodes.recommendation['ALGORITHM_ERROR']!.code: 'Recommendation system error. Please try again later.',

    // ============================================
    // 动作相关错误 (11000-11999)
    // ============================================
    ErrorCodes.exercise['NOT_FOUND']!.code: 'The exercise was not found.',
    ErrorCodes.exercise['FETCH_FAILED']!.code: 'Failed to load exercise.',
    ErrorCodes.exercise['CREATE_FAILED']!.code: 'Failed to create exercise.',
    ErrorCodes.exercise['UPDATE_FAILED']!.code: 'Failed to update exercise.',
    ErrorCodes.exercise['DELETE_FAILED']!.code: 'Failed to delete exercise.',
    ErrorCodes.exercise['INVALID_CODE']!.code: 'Invalid exercise code.',

    // ============================================
    // 训练会话相关错误 (11500-11599)
    // ============================================
    ErrorCodes.workoutSession['NOT_FOUND']!.code: 'Workout session not found.',
    ErrorCodes.workoutSession['CREATE_FAILED']!.code: 'Failed to create workout session.',
    ErrorCodes.workoutSession['FETCH_FAILED']!.code: 'Failed to load workout session.',
    ErrorCodes.workoutSession['UPDATE_FAILED']!.code: 'Failed to update workout session.',
    ErrorCodes.workoutSession['INVALID_STATUS']!.code: 'Invalid workout session status.',

    // ============================================
    // 分享卡片相关错误 (12000-12999)
    // ============================================
    ErrorCodes.shareCard['CREATE_FAILED']!.code: 'Failed to create share card.',
    ErrorCodes.shareCard['FETCH_FAILED']!.code: 'Failed to load share card.',
    ErrorCodes.shareCard['UPDATE_FAILED']!.code: 'Failed to update share card.',
    ErrorCodes.shareCard['NOT_FOUND']!.code: 'Share card not found.',
    ErrorCodes.shareCard['GENERATION_FAILED']!.code: 'Failed to generate share card.',

    // ============================================
    // 稀有度相关错误 (13000-13999)
    // ============================================
    ErrorCodes.rarity['FETCH_FAILED']!.code: 'Failed to load rarity information.',
    ErrorCodes.rarity['UPSERT_FAILED']!.code: 'Failed to update rarity information.',
    ErrorCodes.rarity['CALCULATION_FAILED']!.code: 'Rarity calculation failed.',

    // ============================================
    // 卡片相关错误 (14000-14999)
    // ============================================
    ErrorCodes.card['GENERATION_FAILED']!.code: 'Failed to generate card.',
    ErrorCodes.card['NOT_FOUND']!.code: 'Card not found.',
    ErrorCodes.card['UPLOAD_FAILED']!.code: 'Failed to upload card.',
    ErrorCodes.card['RARITY_CALCULATION_FAILED']!.code: 'Card rarity calculation failed.',
    ErrorCodes.card['TEMPLATE_NOT_FOUND']!.code: 'Card template not found.',
    ErrorCodes.card['IMAGE_PROCESSING_FAILED']!.code: 'Card image processing failed.',

    // ============================================
    // AI识别相关错误 (15000-15999)
    // ============================================
    // 注意：AI识别相关错误优先使用后端返回的详细消息
    ErrorCodes.aiRecognition['MODEL_LOAD_FAILED']!.code: 'AI recognition model failed to load.',
    ErrorCodes.aiRecognition['IMAGE_PROCESSING_FAILED']!.code: 'Image processing failed. Please try taking another photo.',
    ErrorCodes.aiRecognition['INFERENCE_FAILED']!.code: 'AI recognition failed. Please try again.',
    ErrorCodes.aiRecognition['NO_OBJECTS_DETECTED']!.code: 'No objects detected. Please adjust the camera angle.',
    ErrorCodes.aiRecognition['INVALID_IMAGE_FORMAT']!.code: 'Unsupported image format.',
    ErrorCodes.aiRecognition['IMAGE_TOO_LARGE']!.code: 'Image is too large. Please compress and try again.',

    // ============================================
    // 场景器材相关错误 (16000-16999)
    // ============================================
    ErrorCodes.scenarioEquipment['NOT_FOUND']!.code: 'Scenario equipment not found.',
    ErrorCodes.scenarioEquipment['ALREADY_EXISTS']!.code: 'This scenario equipment already exists.',
    ErrorCodes.scenarioEquipment['CODE_EXISTS']!.code: 'Scenario equipment code already exists.',
    ErrorCodes.scenarioEquipment['CREATE_FAILED']!.code: 'Failed to create scenario equipment.',
    ErrorCodes.scenarioEquipment['UPDATE_FAILED']!.code: 'Failed to update scenario equipment.',
    ErrorCodes.scenarioEquipment['DELETE_FAILED']!.code: 'Failed to delete scenario equipment.',
    ErrorCodes.scenarioEquipment['FETCH_FAILED']!.code: 'Failed to load scenario equipment.',
    ErrorCodes.scenarioEquipment['LIST_FAILED']!.code: 'Failed to load scenario equipment list.',
    ErrorCodes.scenarioEquipment['COUNT_FAILED']!.code: 'Failed to count scenario equipment.',
    ErrorCodes.scenarioEquipment['INVALID_CODE']!.code: 'Invalid scenario equipment code.',
    ErrorCodes.scenarioEquipment['INACTIVE_SCENARIO_EQUIPMENT']!.code: 'This scenario equipment is currently unavailable.',
  };

  /// 解析后端返回的错误响应
  ///
  /// [errorResponse] 后端返回的错误JSON对象
  ///
  /// 返回格式化的错误信息对象
  static ErrorInfo parseErrorResponse(Map<String, dynamic> errorResponse) {
    try {
      final error = errorResponse['error'];
      if (error == null) {
        return ErrorInfo(
          code: ErrorCodes.common['INTERNAL_SERVER_ERROR']!.code,
          message: '未知错误',
          category: 'SYSTEM',
        );
      }

      final code = error['code'] as int? ?? ErrorCodes.common['INTERNAL_SERVER_ERROR']!.code;

      // Handle message field - can be String or List<String>
      String? backendMessage;
      final messageField = error['message'];
      if (messageField is String) {
        backendMessage = messageField;
      } else if (messageField is List) {
        // If it's an array, join with newlines
        backendMessage = messageField.join('\n');
      }

      final category = error['category'] as String? ?? 'SYSTEM';
      final timestamp = error['timestamp'] as String?;
      final context = error['context'] as Map<String, dynamic>?;

      // 获取用户友好的错误消息
      final userMessage = getErrorMessage(code, backendMessage: backendMessage);

      return ErrorInfo(
        code: code,
        message: userMessage,
        category: category,
        timestamp: timestamp,
        context: context,
        originalMessage: backendMessage,
      );
    } catch (e) {
      debugPrint('❌ 解析错误响应失败: $e');
      return ErrorInfo(
        code: ErrorCodes.common['INTERNAL_SERVER_ERROR']!.code,
        message: '解析错误信息失败',
        category: 'SYSTEM',
      );
    }
  }

  /// 从异常字符串中解析错误信息
  /// 支持格式: "ERROR_CODE:10001|详细错误消息"
  static ErrorInfo parseExceptionString(String exceptionString) {
    try {
      if (exceptionString.contains('ERROR_CODE:')) {
        final parts = exceptionString.split('ERROR_CODE:');
        if (parts.length > 1) {
          final codeParts = parts[1].split('|');
          final code = int.parse(codeParts[0]);
          final backendMessage = codeParts.length > 1 ? codeParts[1] : null;

          final userMessage = getErrorMessage(code, backendMessage: backendMessage);

          return ErrorInfo(
            code: code,
            message: userMessage,
            category: 'BUSINESS',
            originalMessage: backendMessage,
          );
        }
      }

      // 无法解析，返回默认错误
      return ErrorInfo(
        code: ErrorCodes.common['INTERNAL_SERVER_ERROR']!.code,
        message: '操作失败，请稍后重试',
        category: 'SYSTEM',
      );
    } catch (e) {
      debugPrint('❌ 解析异常字符串失败: $e');
      return ErrorInfo(
        code: ErrorCodes.common['INTERNAL_SERVER_ERROR']!.code,
        message: '操作失败，请稍后重试',
        category: 'SYSTEM',
      );
    }
  }
}

/// 错误信息对象
class ErrorInfo {
  /// 错误码
  final int code;

  /// 用户友好的错误消息（用于显示给用户）
  final String message;

  /// 错误类别 (BUSINESS, VALIDATION, SYSTEM, NETWORK, AUTH)
  final String category;

  /// 错误时间戳
  final String? timestamp;

  /// 错误上下文信息（用于调试）
  final Map<String, dynamic>? context;

  /// 后端原始错误消息（用于调试）
  final String? originalMessage;

  ErrorInfo({
    required this.code,
    required this.message,
    required this.category,
    this.timestamp,
    this.context,
    this.originalMessage,
  });

  /// 判断是否为业务错误（非系统错误）
  bool get isBusinessError => category == 'BUSINESS';

  /// 判断是否为系统错误
  bool get isSystemError => category == 'SYSTEM';

  /// 判断是否为认证错误
  bool get isAuthError => category == 'AUTH';

  /// 判断是否为验证错误
  bool get isValidationError => category == 'VALIDATION';

  @override
  String toString() {
    return 'ErrorInfo(code: $code, message: $message, category: $category)';
  }

  /// 获取完整的调试信息
  String toDebugString() {
    return '''
ErrorInfo {
  code: $code
  message: $message
  category: $category
  timestamp: $timestamp
  originalMessage: $originalMessage
  context: $context
}''';
  }
}
