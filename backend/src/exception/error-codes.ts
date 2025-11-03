/**
 * 统一错误代码定义
 * 错误代码格式: { code: 数字编码, message: 错误消息标识 }
 */
export const ErrorCodes = {
    // 通用错误 (1000-1999)
    COMMON: {
        BAD_REQUEST: { code: 1000, message: 'COMMON_BAD_REQUEST' },
        UNAUTHORIZED: { code: 1001, message: 'COMMON_UNAUTHORIZED' },
        FORBIDDEN: { code: 1002, message: 'COMMON_FORBIDDEN' },
        NOT_FOUND: { code: 1003, message: 'COMMON_NOT_FOUND' },
        INTERNAL_SERVER_ERROR: { code: 1004, message: 'COMMON_INTERNAL_SERVER_ERROR' },
        VALIDATION_ERROR: { code: 1005, message: 'COMMON_VALIDATION_ERROR' },
    },

    // 用户相关错误 (2000-2999)
    USER: {
        NOT_FOUND: { code: 2000, message: 'USER_NOT_FOUND' },
        ALREADY_EXISTS: { code: 2001, message: 'USER_ALREADY_EXISTS' },
        INVALID_CREDENTIALS: { code: 2002, message: 'USER_INVALID_CREDENTIALS' },
        ACCOUNT_DISABLED: { code: 2003, message: 'USER_ACCOUNT_DISABLED' },
        EMAIL_EXISTS: { code: 2004, message: 'USER_EMAIL_EXISTS' },
        EMAIL_NOT_EXISTS: { code: 2005, message: 'EMAIL_NOT_EXISTS' },
        PASSWORD_INVALID: { code: 2006, message: 'USER_PASSWORD_INVALID' },
        VERIFICATION_CODE_INVALID: { code: 2007, message: 'USER_VERIFICATION_CODE_INVALID' },
        EMAIL_SEND_FAIL: { code: 2008, message: 'EMAIL_SEND_FAIL' },
        INVALID_USER_ID: { code: 2009, message: 'INVALID_USER_ID' },
    },

    // 认证相关错误 (3000-3999)
    AUTH: {
        INVALID_TOKEN: { code: 3000, message: 'AUTH_INVALID_TOKEN' },
        TOKEN_EXPIRED: { code: 3001, message: 'AUTH_TOKEN_EXPIRED' },
        REFRESH_TOKEN_INVALID: { code: 3002, message: 'AUTH_REFRESH_TOKEN_INVALID' },
        UNAUTHORIZED_ACCESS: { code: 3003, message: 'AUTH_UNAUTHORIZED_ACCESS' },
        REGISTRATION_FAILED: { code: 3004, message: 'AUTH_REGISTRATION_FAILED' },
        USER_ACCOUNT_NOT_FOUND: { code: 3005, message: 'AUTH_USER_ACCOUNT_NOT_FOUND' },
        PASSWORD_UPDATE_FAILED: { code: 3006, message: 'AUTH_PASSWORD_UPDATE_FAILED' },
        USER_INFO_FETCH_FAILED: { code: 3007, message: 'AUTH_USER_INFO_FETCH_FAILED' },
        EMAIL_SEND_FAILED: { code: 3008, message: 'AUTH_EMAIL_SEND_FAILED' },
        PASSWORD_RESET_FAILED: { code: 3009, message: 'AUTH_PASSWORD_RESET_FAILED' },
    },

    // AI服务相关错误 (4000-4999)
    AI: {
        UNSUPPORTED_MODEL: { code: 4000, message: 'AI_UNSUPPORTED_MODEL' },
        CONTENT_GENERATION_FAILED: { code: 4001, message: 'AI_CONTENT_GENERATION_FAILED' },
        UI_GENERATION_FAILED: { code: 4002, message: 'AI_UI_GENERATION_FAILED' },
        JOB_NOT_FOUND: { code: 4003, message: 'AI_JOB_NOT_FOUND' },
        JOB_CREATION_FAILED: { code: 4004, message: 'AI_JOB_CREATION_FAILED' },
        JOB_UPDATE_FAILED: { code: 4005, message: 'AI_JOB_UPDATE_FAILED' },
    },

    // PayPal相关错误 (5000-5999)
    PAYPAL: {
        SUBSCRIPTION_FETCH_FAILED: { code: 5000, message: 'PAYPAL_SUBSCRIPTION_FETCH_FAILED' },
        SUBSCRIPTION_CANCEL_FAILED: { code: 5001, message: 'PAYPAL_SUBSCRIPTION_CANCEL_FAILED' },
        WEBHOOK_VERIFICATION_FAILED: { code: 5002, message: 'PAYPAL_WEBHOOK_VERIFICATION_FAILED' },
        SUBSCRIPTION_CREATE_FAILED: { code: 5003, message: 'PAYPAL_SUBSCRIPTION_CREATE_FAILED' },
        ORDER_CAPTURE_FAILED: { code: 5004, message: 'PAYPAL_ORDER_CAPTURE_FAILED' },
    },

    // 数据库相关错误 (6000-6999)
    DATABASE: {
        CONNECTION_ERROR: { code: 6000, message: 'DATABASE_CONNECTION_ERROR' },
        QUERY_ERROR: { code: 6001, message: 'DATABASE_QUERY_ERROR' },
        TRANSACTION_ERROR: { code: 6002, message: 'DATABASE_TRANSACTION_ERROR' },
    },

    // 场景相关错误 (7000-7999)
    SCENARIO: {
        NOT_FOUND: { code: 7000, message: 'SCENARIO_NOT_FOUND' },
        ALREADY_EXISTS: { code: 7001, message: 'SCENARIO_ALREADY_EXISTS' },
        CODE_EXISTS: { code: 7002, message: 'SCENARIO_CODE_EXISTS' },
        CREATE_FAILED: { code: 7003, message: 'SCENARIO_CREATE_FAILED' },
        UPDATE_FAILED: { code: 7004, message: 'SCENARIO_UPDATE_FAILED' },
        DELETE_FAILED: { code: 7005, message: 'SCENARIO_DELETE_FAILED' },
        FETCH_FAILED: { code: 7006, message: 'SCENARIO_FETCH_FAILED' },
        LIST_FAILED: { code: 7007, message: 'SCENARIO_LIST_FAILED' },
        COUNT_FAILED: { code: 7008, message: 'SCENARIO_COUNT_FAILED' },
        INVALID_CODE: { code: 7009, message: 'SCENARIO_INVALID_CODE' },
        INACTIVE_SCENARIO: { code: 7010, message: 'SCENARIO_INACTIVE' },
    },

    // 器材相关错误 (8000-8999)
    EQUIPMENT: {
        NOT_FOUND: { code: 8000, message: 'EQUIPMENT_NOT_FOUND' },
        ALREADY_EXISTS: { code: 8001, message: 'EQUIPMENT_ALREADY_EXISTS' },
        CODE_EXISTS: { code: 8002, message: 'EQUIPMENT_CODE_EXISTS' },
        CREATE_FAILED: { code: 8003, message: 'EQUIPMENT_CREATE_FAILED' },
        UPDATE_FAILED: { code: 8004, message: 'EQUIPMENT_UPDATE_FAILED' },
        DELETE_FAILED: { code: 8005, message: 'EQUIPMENT_DELETE_FAILED' },
        FETCH_FAILED: { code: 8006, message: 'EQUIPMENT_FETCH_FAILED' },
        LIST_FAILED: { code: 8007, message: 'EQUIPMENT_LIST_FAILED' },
        COUNT_FAILED: { code: 8008, message: 'EQUIPMENT_COUNT_FAILED' },
        INVALID_CODE: { code: 8009, message: 'EQUIPMENT_INVALID_CODE' },
        INACTIVE_EQUIPMENT: { code: 8010, message: 'EQUIPMENT_INACTIVE' },
    },

    // 主题周相关错误 (9000-9999)
    THEME_WEEK: {
        NOT_FOUND: { code: 9000, message: 'THEME_WEEK_NOT_FOUND' },
        ALREADY_JOINED: { code: 9001, message: 'THEME_WEEK_ALREADY_JOINED' },
        ENDED: { code: 9002, message: 'THEME_WEEK_ENDED' },
        NOT_STARTED: { code: 9003, message: 'THEME_WEEK_NOT_STARTED' },
        PARTICIPATION_FAILED: { code: 9004, message: 'THEME_WEEK_PARTICIPATION_FAILED' },
        UPDATE_FAILED: { code: 9005, message: 'THEME_WEEK_UPDATE_FAILED' },
        CREATE_FAILED: { code: 9006, message: 'THEME_WEEK_CREATE_FAILED' },
        FETCH_FAILED: { code: 9007, message: 'THEME_WEEK_FETCH_FAILED' },
    },

    // 推荐相关错误 (10000-10999)
    RECOMMENDATION: {
        GENERATION_FAILED: { code: 10000, message: 'RECOMMENDATION_GENERATION_FAILED' },
        NO_EXERCISES_FOUND: { code: 10001, message: 'RECOMMENDATION_NO_EXERCISES_FOUND' },
        INVALID_PARAMETERS: { code: 10002, message: 'RECOMMENDATION_INVALID_PARAMETERS' },
        REPLACE_FAILED: { code: 10003, message: 'RECOMMENDATION_REPLACE_FAILED' },
        SESSION_NOT_FOUND: { code: 10004, message: 'RECOMMENDATION_SESSION_NOT_FOUND' },
        ALGORITHM_ERROR: { code: 10005, message: 'RECOMMENDATION_ALGORITHM_ERROR' },
    },

    // 动作相关错误 (11000-11999)
    EXERCISE: {
        NOT_FOUND: { code: 11000, message: 'EXERCISE_NOT_FOUND' },
        FETCH_FAILED: { code: 11001, message: 'EXERCISE_FETCH_FAILED' },
        CREATE_FAILED: { code: 11002, message: 'EXERCISE_CREATE_FAILED' },
        UPDATE_FAILED: { code: 11003, message: 'EXERCISE_UPDATE_FAILED' },
        DELETE_FAILED: { code: 11004, message: 'EXERCISE_DELETE_FAILED' },
        INVALID_CODE: { code: 11005, message: 'EXERCISE_INVALID_CODE' },
    },

    // 训练会话相关错误 (11500-11599)
    WORKOUT_SESSION: {
        NOT_FOUND: { code: 11500, message: 'WORKOUT_SESSION_NOT_FOUND' },
        CREATE_FAILED: { code: 11501, message: 'WORKOUT_SESSION_CREATE_FAILED' },
        FETCH_FAILED: { code: 11502, message: 'WORKOUT_SESSION_FETCH_FAILED' },
        UPDATE_FAILED: { code: 11503, message: 'WORKOUT_SESSION_UPDATE_FAILED' },
        INVALID_STATUS: { code: 11504, message: 'WORKOUT_SESSION_INVALID_STATUS' },
    },

    // 分享卡片相关错误 (12000-12999)
    SHARE_CARD: {
        CREATE_FAILED: { code: 12000, message: 'SHARE_CARD_CREATE_FAILED' },
        FETCH_FAILED: { code: 12001, message: 'SHARE_CARD_FETCH_FAILED' },
        UPDATE_FAILED: { code: 12002, message: 'SHARE_CARD_UPDATE_FAILED' },
        NOT_FOUND: { code: 12003, message: 'SHARE_CARD_NOT_FOUND' },
        GENERATION_FAILED: { code: 12004, message: 'SHARE_CARD_GENERATION_FAILED' },
    },

    // 稀有度相关错误 (13000-13999)
    RARITY: {
        FETCH_FAILED: { code: 13000, message: 'RARITY_FETCH_FAILED' },
        UPSERT_FAILED: { code: 13001, message: 'RARITY_UPSERT_FAILED' },
        CALCULATION_FAILED: { code: 13002, message: 'RARITY_CALCULATION_FAILED' },
    },

    // 卡片相关错误 (14000-14999)
    CARD: {
        GENERATION_FAILED: { code: 14000, message: 'CARD_GENERATION_FAILED' },
        NOT_FOUND: { code: 14001, message: 'CARD_NOT_FOUND' },
        UPLOAD_FAILED: { code: 14002, message: 'CARD_UPLOAD_FAILED' },
        RARITY_CALCULATION_FAILED: { code: 14003, message: 'CARD_RARITY_CALCULATION_FAILED' },
        TEMPLATE_NOT_FOUND: { code: 14004, message: 'CARD_TEMPLATE_NOT_FOUND' },
        IMAGE_PROCESSING_FAILED: { code: 14005, message: 'CARD_IMAGE_PROCESSING_FAILED' },
    },

    // AI识别相关错误 (15000-15999)
    AI_RECOGNITION: {
        MODEL_LOAD_FAILED: { code: 15000, message: 'AI_RECOGNITION_MODEL_LOAD_FAILED' },
        IMAGE_PROCESSING_FAILED: { code: 15001, message: 'AI_RECOGNITION_IMAGE_PROCESSING_FAILED' },
        INFERENCE_FAILED: { code: 15002, message: 'AI_RECOGNITION_INFERENCE_FAILED' },
        NO_OBJECTS_DETECTED: { code: 15003, message: 'AI_RECOGNITION_NO_OBJECTS_DETECTED' },
        INVALID_IMAGE_FORMAT: { code: 15004, message: 'AI_RECOGNITION_INVALID_IMAGE_FORMAT' },
        IMAGE_TOO_LARGE: { code: 15005, message: 'AI_RECOGNITION_IMAGE_TOO_LARGE' },
    },


};
