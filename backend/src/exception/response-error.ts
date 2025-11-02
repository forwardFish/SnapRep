/**
 * 响应错误类
 * 用于统一错误处理和响应格式
 */
export class ResponseError extends Error {
  public readonly code: number;
  public readonly i18nKey: string;
  public readonly context?: Record<string, any>;
  public readonly timestamp: string;
  public readonly originalCause?: Error;

  constructor(
    errorCode: { code: number; message: string },
    cause?: Error,
    context?: Record<string, any>
  ) {
    super(errorCode.message);
    this.name = 'ResponseError';
    this.code = errorCode.code;
    this.i18nKey = errorCode.message;
    this.context = context;
    this.timestamp = new Date().toISOString();

    if (cause) {
      this.originalCause = cause;
    }

    // 确保错误堆栈正确
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, ResponseError);
    }
  }

  /**
   * 转换为JSON格式
   */
  toJSON() {
    return {
      name: this.name,
      message: this.message,
      code: this.code,
      i18nKey: this.i18nKey,
      context: this.context,
      timestamp: this.timestamp,
      stack: this.stack,
    };
  }

  /**
   * 获取用户友好的错误消息
   */
  getUserMessage(): string {
    return this.i18nKey;
  }

  /**
   * 获取开发者详细信息
   */
  getDevDetails() {
    return {
      code: this.code,
      message: this.message,
      context: this.context,
      cause: this.originalCause,
      stack: this.stack,
    };
  }
}