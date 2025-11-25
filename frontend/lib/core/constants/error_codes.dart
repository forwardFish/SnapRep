/// 统一错误代码定义
/// 与后端 error-codes.ts 保持完全一致的结构和格式
/// 可以直接从后端复制粘贴更新
/// 错误代码格式: { code: 数字编码, message: 错误消息标识, httpStatus?: HTTP状态码, category?: 错误类别 }

/// 错误代码类型定义
class ErrorCodeType {
  final int code;
  final String message;
  final int? httpStatus;
  final String? category;

  const ErrorCodeType({
    required this.code,
    required this.message,
    this.httpStatus,
    this.category,
  });
}

/// 错误类别枚举
class ErrorCategory {
  static const String business = 'BUSINESS';     // 业务逻辑错误
  static const String validation = 'VALIDATION'; // 参数验证错误
  static const String system = 'SYSTEM';         // 系统错误
  static const String network = 'NETWORK';       // 网络错误
  static const String auth = 'AUTH';             // 认证授权错误
}

/// 统一错误代码定义
/// ✅ 与后端 error-codes.ts 保持完全一致的结构
class ErrorCodes {
  // 通用错误 (1000-1999)
  static const Map<String, ErrorCodeType> common = {
    'BAD_REQUEST': ErrorCodeType(code: 1000, message: 'COMMON_BAD_REQUEST'),
    'UNAUTHORIZED': ErrorCodeType(code: 1001, message: 'COMMON_UNAUTHORIZED'),
    'FORBIDDEN': ErrorCodeType(code: 1002, message: 'COMMON_FORBIDDEN'),
    'NOT_FOUND': ErrorCodeType(code: 1003, message: 'COMMON_NOT_FOUND'),
    'INTERNAL_SERVER_ERROR': ErrorCodeType(code: 1004, message: 'COMMON_INTERNAL_SERVER_ERROR'),
    'VALIDATION_ERROR': ErrorCodeType(code: 1005, message: 'COMMON_VALIDATION_ERROR'),
  };

  // 用户相关错误 (2000-2999)
  static const Map<String, ErrorCodeType> user = {
    'NOT_FOUND': ErrorCodeType(code: 2000, message: 'USER_NOT_FOUND'),
    'ALREADY_EXISTS': ErrorCodeType(code: 2001, message: 'USER_ALREADY_EXISTS'),
    'INVALID_CREDENTIALS': ErrorCodeType(code: 2002, message: 'USER_INVALID_CREDENTIALS'),
    'ACCOUNT_DISABLED': ErrorCodeType(code: 2003, message: 'USER_ACCOUNT_DISABLED'),
    'EMAIL_EXISTS': ErrorCodeType(code: 2004, message: 'USER_EMAIL_EXISTS'),
    'EMAIL_NOT_EXISTS': ErrorCodeType(code: 2005, message: 'EMAIL_NOT_EXISTS'),
    'PASSWORD_INVALID': ErrorCodeType(code: 2006, message: 'USER_PASSWORD_INVALID'),
    'VERIFICATION_CODE_INVALID': ErrorCodeType(code: 2007, message: 'USER_VERIFICATION_CODE_INVALID'),
    'EMAIL_SEND_FAIL': ErrorCodeType(code: 2008, message: 'EMAIL_SEND_FAIL'),
    'INVALID_USER_ID': ErrorCodeType(code: 2009, message: 'INVALID_USER_ID'),
  };

  // 认证相关错误 (3000-3999)
  static const Map<String, ErrorCodeType> auth = {
    'INVALID_TOKEN': ErrorCodeType(code: 3000, message: 'AUTH_INVALID_TOKEN'),
    'TOKEN_EXPIRED': ErrorCodeType(code: 3001, message: 'AUTH_TOKEN_EXPIRED'),
    'REFRESH_TOKEN_INVALID': ErrorCodeType(code: 3002, message: 'AUTH_REFRESH_TOKEN_INVALID'),
    'UNAUTHORIZED_ACCESS': ErrorCodeType(code: 3003, message: 'AUTH_UNAUTHORIZED_ACCESS'),
    'REGISTRATION_FAILED': ErrorCodeType(code: 3004, message: 'AUTH_REGISTRATION_FAILED'),
    'USER_ACCOUNT_NOT_FOUND': ErrorCodeType(code: 3005, message: 'AUTH_USER_ACCOUNT_NOT_FOUND'),
    'PASSWORD_UPDATE_FAILED': ErrorCodeType(code: 3006, message: 'AUTH_PASSWORD_UPDATE_FAILED'),
    'USER_INFO_FETCH_FAILED': ErrorCodeType(code: 3007, message: 'AUTH_USER_INFO_FETCH_FAILED'),
    'EMAIL_SEND_FAILED': ErrorCodeType(code: 3008, message: 'AUTH_EMAIL_SEND_FAILED'),
    'PASSWORD_RESET_FAILED': ErrorCodeType(code: 3009, message: 'AUTH_PASSWORD_RESET_FAILED'),
    'INVALID_CREDENTIALS': ErrorCodeType(code: 3010, message: 'AUTH_INVALID_CREDENTIALS'),
    'OTP_VERIFICATION_FAILED': ErrorCodeType(code: 3011, message: 'AUTH_OTP_VERIFICATION_FAILED'),
    'USER_DATA_PROCESSING_FAILED': ErrorCodeType(code: 3012, message: 'AUTH_USER_DATA_PROCESSING_FAILED'),
    'SUPABASE_API_ERROR': ErrorCodeType(code: 3013, message: 'AUTH_SUPABASE_API_ERROR'),
    'SUPABASE_LOGIN_FAILED': ErrorCodeType(code: 3014, message: 'AUTH_LOGIN_FAILED'),
    'SUPABASE_SEND_OTP_FAILED': ErrorCodeType(code: 3015, message: 'SUPABASE_SEND_OTP_FAILED'),
    'GET_USER_INFO_FAILED': ErrorCodeType(code: 3016, message: 'GET_USER_INFO_FAILED'),
    'LOGOUT_FAILED': ErrorCodeType(code: 3017, message: 'LOGOUT_FAILED'),
  };

  // AI服务相关错误 (4000-4999)
  static const Map<String, ErrorCodeType> ai = {
    'UNSUPPORTED_MODEL': ErrorCodeType(code: 4000, message: 'AI_UNSUPPORTED_MODEL'),
    'CONTENT_GENERATION_FAILED': ErrorCodeType(code: 4001, message: 'AI_CONTENT_GENERATION_FAILED'),
    'UI_GENERATION_FAILED': ErrorCodeType(code: 4002, message: 'AI_UI_GENERATION_FAILED'),
    'JOB_NOT_FOUND': ErrorCodeType(code: 4003, message: 'AI_JOB_NOT_FOUND'),
    'JOB_CREATION_FAILED': ErrorCodeType(code: 4004, message: 'AI_JOB_CREATION_FAILED'),
    'JOB_UPDATE_FAILED': ErrorCodeType(code: 4005, message: 'AI_JOB_UPDATE_FAILED'),
  };

  // PayPal相关错误 (5000-5999)
  static const Map<String, ErrorCodeType> paypal = {
    'SUBSCRIPTION_FETCH_FAILED': ErrorCodeType(code: 5000, message: 'PAYPAL_SUBSCRIPTION_FETCH_FAILED'),
    'SUBSCRIPTION_CANCEL_FAILED': ErrorCodeType(code: 5001, message: 'PAYPAL_SUBSCRIPTION_CANCEL_FAILED'),
    'WEBHOOK_VERIFICATION_FAILED': ErrorCodeType(code: 5002, message: 'PAYPAL_WEBHOOK_VERIFICATION_FAILED'),
    'SUBSCRIPTION_CREATE_FAILED': ErrorCodeType(code: 5003, message: 'PAYPAL_SUBSCRIPTION_CREATE_FAILED'),
    'ORDER_CAPTURE_FAILED': ErrorCodeType(code: 5004, message: 'PAYPAL_ORDER_CAPTURE_FAILED'),
  };

  // 数据库相关错误 (6000-6999)
  static const Map<String, ErrorCodeType> database = {
    'CONNECTION_ERROR': ErrorCodeType(code: 6000, message: 'DATABASE_CONNECTION_ERROR'),
    'QUERY_ERROR': ErrorCodeType(code: 6001, message: 'DATABASE_QUERY_ERROR'),
    'TRANSACTION_ERROR': ErrorCodeType(code: 6002, message: 'DATABASE_TRANSACTION_ERROR'),
  };

  // 场景相关错误 (7000-7999)
  static const Map<String, ErrorCodeType> scenario = {
    'NOT_FOUND': ErrorCodeType(code: 7000, message: 'SCENARIO_NOT_FOUND'),
    'ALREADY_EXISTS': ErrorCodeType(code: 7001, message: 'SCENARIO_ALREADY_EXISTS'),
    'CODE_EXISTS': ErrorCodeType(code: 7002, message: 'SCENARIO_CODE_EXISTS'),
    'CREATE_FAILED': ErrorCodeType(code: 7003, message: 'SCENARIO_CREATE_FAILED'),
    'UPDATE_FAILED': ErrorCodeType(code: 7004, message: 'SCENARIO_UPDATE_FAILED'),
    'DELETE_FAILED': ErrorCodeType(code: 7005, message: 'SCENARIO_DELETE_FAILED'),
    'FETCH_FAILED': ErrorCodeType(code: 7006, message: 'SCENARIO_FETCH_FAILED'),
    'LIST_FAILED': ErrorCodeType(code: 7007, message: 'SCENARIO_LIST_FAILED'),
    'COUNT_FAILED': ErrorCodeType(code: 7008, message: 'SCENARIO_COUNT_FAILED'),
    'INVALID_CODE': ErrorCodeType(code: 7009, message: 'SCENARIO_INVALID_CODE'),
    'INACTIVE_SCENARIO': ErrorCodeType(code: 7010, message: 'SCENARIO_INACTIVE'),
  };

  // 器材相关错误 (8000-8999)
  static const Map<String, ErrorCodeType> equipment = {
    'NOT_FOUND': ErrorCodeType(code: 8000, message: 'EQUIPMENT_NOT_FOUND', httpStatus: 404, category: 'BUSINESS'),
    'ALREADY_EXISTS': ErrorCodeType(code: 8001, message: 'EQUIPMENT_ALREADY_EXISTS', httpStatus: 409, category: 'BUSINESS'),
    'CODE_EXISTS': ErrorCodeType(code: 8002, message: 'EQUIPMENT_CODE_EXISTS', httpStatus: 409, category: 'BUSINESS'),
    'CREATE_FAILED': ErrorCodeType(code: 8003, message: 'EQUIPMENT_CREATE_FAILED', httpStatus: 400, category: 'BUSINESS'),
    'UPDATE_FAILED': ErrorCodeType(code: 8004, message: 'EQUIPMENT_UPDATE_FAILED', httpStatus: 400, category: 'BUSINESS'),
    'DELETE_FAILED': ErrorCodeType(code: 8005, message: 'EQUIPMENT_DELETE_FAILED', httpStatus: 400, category: 'BUSINESS'),
    'FETCH_FAILED': ErrorCodeType(code: 8006, message: 'EQUIPMENT_FETCH_FAILED', httpStatus: 500, category: 'SYSTEM'),
    'LIST_FAILED': ErrorCodeType(code: 8007, message: 'EQUIPMENT_LIST_FAILED', httpStatus: 500, category: 'SYSTEM'),
    'COUNT_FAILED': ErrorCodeType(code: 8008, message: 'EQUIPMENT_COUNT_FAILED', httpStatus: 500, category: 'SYSTEM'),
    'INVALID_CODE': ErrorCodeType(code: 8009, message: 'EQUIPMENT_INVALID_CODE', httpStatus: 400, category: 'VALIDATION'),
    'INACTIVE_EQUIPMENT': ErrorCodeType(code: 8010, message: 'EQUIPMENT_INACTIVE', httpStatus: 400, category: 'BUSINESS'),
  };

  // 主题周相关错误 (9000-9999)
  static const Map<String, ErrorCodeType> themeWeek = {
    'NOT_FOUND': ErrorCodeType(code: 9000, message: 'THEME_WEEK_NOT_FOUND'),
    'ALREADY_JOINED': ErrorCodeType(code: 9001, message: 'THEME_WEEK_ALREADY_JOINED'),
    'ENDED': ErrorCodeType(code: 9002, message: 'THEME_WEEK_ENDED'),
    'NOT_STARTED': ErrorCodeType(code: 9003, message: 'THEME_WEEK_NOT_STARTED'),
    'PARTICIPATION_FAILED': ErrorCodeType(code: 9004, message: 'THEME_WEEK_PARTICIPATION_FAILED'),
    'UPDATE_FAILED': ErrorCodeType(code: 9005, message: 'THEME_WEEK_UPDATE_FAILED'),
    'CREATE_FAILED': ErrorCodeType(code: 9006, message: 'THEME_WEEK_CREATE_FAILED'),
    'FETCH_FAILED': ErrorCodeType(code: 9007, message: 'THEME_WEEK_FETCH_FAILED'),
  };

  // 推荐相关错误 (10000-10999)
  static const Map<String, ErrorCodeType> recommendation = {
    'GENERATION_FAILED': ErrorCodeType(code: 10000, message: 'RECOMMENDATION_GENERATION_FAILED'),
    'NO_EXERCISES_FOUND': ErrorCodeType(code: 10001, message: 'RECOMMENDATION_NO_EXERCISES_FOUND'),
    'INVALID_PARAMETERS': ErrorCodeType(code: 10002, message: 'RECOMMENDATION_INVALID_PARAMETERS'),
    'REPLACE_FAILED': ErrorCodeType(code: 10003, message: 'RECOMMENDATION_REPLACE_FAILED'),
    'SESSION_NOT_FOUND': ErrorCodeType(code: 10004, message: 'RECOMMENDATION_SESSION_NOT_FOUND'),
    'ALGORITHM_ERROR': ErrorCodeType(code: 10005, message: 'RECOMMENDATION_ALGORITHM_ERROR'),
  };

  // 动作相关错误 (11000-11999)
  static const Map<String, ErrorCodeType> exercise = {
    'NOT_FOUND': ErrorCodeType(code: 11000, message: 'EXERCISE_NOT_FOUND'),
    'FETCH_FAILED': ErrorCodeType(code: 11001, message: 'EXERCISE_FETCH_FAILED'),
    'CREATE_FAILED': ErrorCodeType(code: 11002, message: 'EXERCISE_CREATE_FAILED'),
    'UPDATE_FAILED': ErrorCodeType(code: 11003, message: 'EXERCISE_UPDATE_FAILED'),
    'DELETE_FAILED': ErrorCodeType(code: 11004, message: 'EXERCISE_DELETE_FAILED'),
    'INVALID_CODE': ErrorCodeType(code: 11005, message: 'EXERCISE_INVALID_CODE'),
  };

  // 训练会话相关错误 (11500-11599)
  static const Map<String, ErrorCodeType> workoutSession = {
    'NOT_FOUND': ErrorCodeType(code: 11500, message: 'WORKOUT_SESSION_NOT_FOUND'),
    'CREATE_FAILED': ErrorCodeType(code: 11501, message: 'WORKOUT_SESSION_CREATE_FAILED'),
    'FETCH_FAILED': ErrorCodeType(code: 11502, message: 'WORKOUT_SESSION_FETCH_FAILED'),
    'UPDATE_FAILED': ErrorCodeType(code: 11503, message: 'WORKOUT_SESSION_UPDATE_FAILED'),
    'INVALID_STATUS': ErrorCodeType(code: 11504, message: 'WORKOUT_SESSION_INVALID_STATUS'),
  };

  // 分享卡片相关错误 (12000-12999)
  static const Map<String, ErrorCodeType> shareCard = {
    'CREATE_FAILED': ErrorCodeType(code: 12000, message: 'SHARE_CARD_CREATE_FAILED'),
    'FETCH_FAILED': ErrorCodeType(code: 12001, message: 'SHARE_CARD_FETCH_FAILED'),
    'UPDATE_FAILED': ErrorCodeType(code: 12002, message: 'SHARE_CARD_UPDATE_FAILED'),
    'NOT_FOUND': ErrorCodeType(code: 12003, message: 'SHARE_CARD_NOT_FOUND'),
    'GENERATION_FAILED': ErrorCodeType(code: 12004, message: 'SHARE_CARD_GENERATION_FAILED'),
  };

  // 稀有度相关错误 (13000-13999)
  static const Map<String, ErrorCodeType> rarity = {
    'FETCH_FAILED': ErrorCodeType(code: 13000, message: 'RARITY_FETCH_FAILED'),
    'UPSERT_FAILED': ErrorCodeType(code: 13001, message: 'RARITY_UPSERT_FAILED'),
    'CALCULATION_FAILED': ErrorCodeType(code: 13002, message: 'RARITY_CALCULATION_FAILED'),
  };

  // 卡片相关错误 (14000-14999)
  static const Map<String, ErrorCodeType> card = {
    'GENERATION_FAILED': ErrorCodeType(code: 14000, message: 'CARD_GENERATION_FAILED'),
    'NOT_FOUND': ErrorCodeType(code: 14001, message: 'CARD_NOT_FOUND'),
    'UPLOAD_FAILED': ErrorCodeType(code: 14002, message: 'CARD_UPLOAD_FAILED'),
    'RARITY_CALCULATION_FAILED': ErrorCodeType(code: 14003, message: 'CARD_RARITY_CALCULATION_FAILED'),
    'TEMPLATE_NOT_FOUND': ErrorCodeType(code: 14004, message: 'CARD_TEMPLATE_NOT_FOUND'),
    'IMAGE_PROCESSING_FAILED': ErrorCodeType(code: 14005, message: 'CARD_IMAGE_PROCESSING_FAILED'),
  };

  // AI识别相关错误 (15000-15999)
  static const Map<String, ErrorCodeType> aiRecognition = {
    'MODEL_LOAD_FAILED': ErrorCodeType(code: 15000, message: 'AI_RECOGNITION_MODEL_LOAD_FAILED'),
    'IMAGE_PROCESSING_FAILED': ErrorCodeType(code: 15001, message: 'AI_RECOGNITION_IMAGE_PROCESSING_FAILED'),
    'INFERENCE_FAILED': ErrorCodeType(code: 15002, message: 'AI_RECOGNITION_INFERENCE_FAILED'),
    'NO_OBJECTS_DETECTED': ErrorCodeType(code: 15003, message: 'AI_RECOGNITION_NO_OBJECTS_DETECTED'),
    'INVALID_IMAGE_FORMAT': ErrorCodeType(code: 15004, message: 'AI_RECOGNITION_INVALID_IMAGE_FORMAT'),
    'IMAGE_TOO_LARGE': ErrorCodeType(code: 15005, message: 'AI_RECOGNITION_IMAGE_TOO_LARGE'),
  };

  // 场景器材相关错误 (16000-16999)
  static const Map<String, ErrorCodeType> scenarioEquipment = {
    'NOT_FOUND': ErrorCodeType(code: 16000, message: 'SCENARIO_EQUIPMENT_NOT_FOUND', httpStatus: 404, category: 'BUSINESS'),
    'ALREADY_EXISTS': ErrorCodeType(code: 16001, message: 'SCENARIO_EQUIPMENT_ALREADY_EXISTS', httpStatus: 409, category: 'BUSINESS'),
    'CODE_EXISTS': ErrorCodeType(code: 16002, message: 'SCENARIO_EQUIPMENT_CODE_EXISTS', httpStatus: 409, category: 'BUSINESS'),
    'CREATE_FAILED': ErrorCodeType(code: 16003, message: 'SCENARIO_EQUIPMENT_CREATE_FAILED', httpStatus: 400, category: 'BUSINESS'),
    'UPDATE_FAILED': ErrorCodeType(code: 16004, message: 'SCENARIO_EQUIPMENT_UPDATE_FAILED', httpStatus: 400, category: 'BUSINESS'),
    'DELETE_FAILED': ErrorCodeType(code: 16005, message: 'SCENARIO_EQUIPMENT_DELETE_FAILED', httpStatus: 400, category: 'BUSINESS'),
    'FETCH_FAILED': ErrorCodeType(code: 16006, message: 'SCENARIO_EQUIPMENT_FETCH_FAILED', httpStatus: 500, category: 'SYSTEM'),
    'LIST_FAILED': ErrorCodeType(code: 16007, message: 'SCENARIO_EQUIPMENT_LIST_FAILED', httpStatus: 500, category: 'SYSTEM'),
    'COUNT_FAILED': ErrorCodeType(code: 16008, message: 'SCENARIO_EQUIPMENT_COUNT_FAILED', httpStatus: 500, category: 'SYSTEM'),
    'INVALID_CODE': ErrorCodeType(code: 16009, message: 'SCENARIO_EQUIPMENT_INVALID_CODE', httpStatus: 400, category: 'VALIDATION'),
    'INACTIVE_SCENARIO_EQUIPMENT': ErrorCodeType(code: 16010, message: 'SCENARIO_EQUIPMENT_INACTIVE', httpStatus: 400, category: 'BUSINESS'),
  };
}