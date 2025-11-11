import { HttpStatus } from '@nestjs/common';

/**
 * 错误代码接口定义
 */
export interface ErrorCodeType {
  readonly code: number;
  readonly message: string;
  readonly httpStatus?: HttpStatus;
  readonly category?: ErrorCategory;
}

/**
 * 错误类别枚举
 */
export enum ErrorCategory {
  BUSINESS = 'BUSINESS',     // 业务逻辑错误
  VALIDATION = 'VALIDATION', // 参数验证错误
  SYSTEM = 'SYSTEM',        // 系统错误
  NETWORK = 'NETWORK',      // 网络错误
  AUTH = 'AUTH',            // 认证授权错误
}

/**
 * 错误上下文接口
 */
export interface ErrorContext {
  userId?: string;
  requestId?: string;
  operation?: string;
  resource?: string;
  [key: string]: unknown;
}

/**
 * 自定义响应错误类
 * 提供完整的错误处理和链式错误支持
 */
export class ResponseError extends Error {
  public readonly code: number;
  public readonly category: ErrorCategory;
  public readonly httpStatus: HttpStatus;
  public readonly context?: ErrorContext;
  public readonly timestamp: string;
  public readonly requestId?: string;

  // 错误链支持
  public readonly cause?: Error;



  constructor(
    errorCode: ErrorCodeType,
    cause?: Error | string,
    context?: ErrorContext
  ) {
    // 处理错误消息
    const message = typeof cause === 'string' ? cause : errorCode.message;
    super(message);

    // 设置错误基本属性
    this.name = 'ResponseError';
    this.code = errorCode.code;
    this.category = errorCode.category || ErrorCategory.SYSTEM;
    this.httpStatus = errorCode.httpStatus || HttpStatus.INTERNAL_SERVER_ERROR;
    this.timestamp = new Date().toISOString();
    this.context = context;
    this.requestId = context?.requestId;

    // 处理错误链
    if (cause && typeof cause !== 'string') {
      this.cause = cause;
      // 如果原始错误有堆栈信息，保留它
      if (cause.stack) {
        this.stack = `${this.stack}\nCaused by: ${cause.stack}`;
      }
    }

    // 确保正确的原型链和堆栈跟踪
    Object.setPrototypeOf(this, ResponseError.prototype);
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, ResponseError);
    }

    // 验证错误代码
    this.validateErrorCode(errorCode);
  }

  /**
   * 验证错误代码有效性
   */
  private validateErrorCode(errorCode: ErrorCodeType): void {
    if (!errorCode.code || errorCode.code <= 0) {
      throw new Error('Error code must be a positive number');
    }
    if (!errorCode.message || errorCode.message.trim() === '') {
      throw new Error('Error message cannot be empty');
    }
  }

  /**
   * 获取完整的错误信息（用于日志记录）
   */
  getFullDetails(): Record<string, unknown> {
    return {
      name: this.name,
      message: this.message,
      code: this.code,
      category: this.category,
      httpStatus: this.httpStatus,
      timestamp: this.timestamp,
      requestId: this.requestId,
      context: this.context,
      cause: this.cause ? {
        name: this.cause.name,
        message: this.cause.message,
        stack: this.cause.stack,
      } : undefined,
      stack: this.stack,
    };
  }

  /**
   * 获取客户端响应格式（隐藏敏感信息）
   */
  getClientResponse(): Record<string, unknown> {
    return {
      error: true,
      code: this.code,
      message: this.message,
      category: this.category,
      timestamp: this.timestamp,
      requestId: this.requestId,
      // 只返回非敏感的上下文信息
      context: this.sanitizeContext(),
    };
  }

  /**
   * 清理敏感的上下文信息
   */
  private sanitizeContext(): Record<string, unknown> | undefined {
    if (!this.context) return undefined;

    const { userId, ...safeContext } = this.context;
    return Object.keys(safeContext).length > 0 ? safeContext : undefined;
  }

  /**
   * JSON序列化
   */
  toJSON(): Record<string, unknown> {
    return this.getClientResponse();
  }

  /**
   * 检查错误是否属于特定类别
   */
  isCategory(category: ErrorCategory): boolean {
    return this.category === category;
  }

  /**
   * 检查是否为业务逻辑错误
   */
  isBusinessError(): boolean {
    return this.isCategory(ErrorCategory.BUSINESS);
  }

  /**
   * 检查是否为系统错误
   */
  isSystemError(): boolean {
    return this.isCategory(ErrorCategory.SYSTEM);
  }

  /**
   * 静态工厂方法 - 创建业务错误
   */
  static business(
    errorCode: ErrorCodeType,
    context?: ErrorContext,
    cause?: Error
  ): ResponseError {
    return new ResponseError(
      { ...errorCode, category: ErrorCategory.BUSINESS },
      cause,
      context
    );
  }

  /**
   * 静态工厂方法 - 创建验证错误
   */
  static validation(
    errorCode: ErrorCodeType,
    context?: ErrorContext,
    cause?: Error
  ): ResponseError {
    return new ResponseError(
      {
        ...errorCode,
        category: ErrorCategory.VALIDATION,
        httpStatus: HttpStatus.BAD_REQUEST
      },
      cause,
      context
    );
  }

  /**
   * 静态工厂方法 - 创建系统错误
   */
  static system(
    errorCode: ErrorCodeType,
    context?: ErrorContext,
    cause?: Error
  ): ResponseError {
    return new ResponseError(
      {
        ...errorCode,
        category: ErrorCategory.SYSTEM,
        httpStatus: HttpStatus.INTERNAL_SERVER_ERROR
      },
      cause,
      context
    );
  }

  /**
   * 静态工厂方法 - 创建认证错误
   */
  static auth(
    errorCode: ErrorCodeType,
    context?: ErrorContext,
    cause?: Error
  ): ResponseError {
    return new ResponseError(
      {
        ...errorCode,
        category: ErrorCategory.AUTH,
        httpStatus: HttpStatus.UNAUTHORIZED
      },
      cause,
      context
    );
  }

  /**
   * 从标准 Error 转换
   */
  static fromError(
    error: Error,
    errorCode: ErrorCodeType,
    context?: ErrorContext
  ): ResponseError {
    return new ResponseError(errorCode, error, context);
  }
}