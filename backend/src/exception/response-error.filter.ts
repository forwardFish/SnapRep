import { HttpStatus } from '@nestjs/common';
import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  Logger,
} from '@nestjs/common';
import { Response, Request } from 'express';
import { ResponseError } from './response-error';
import { logger } from '../common/logger/logger';

/**
 * 全局 ResponseError 异常过滤器
 * 统一处理 ResponseError 异常并返回结构化响应
 * 确保正确的错误代码、类别和HTTP状态码返回
 */
@Catch(ResponseError)
export class ResponseErrorFilter implements ExceptionFilter {
  // private readonly logger = new Logger(ResponseErrorFilter.name);

  catch(exception: ResponseError, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    // 添加调试日志来确认过滤器被调用
    logger.debug('🔥 ResponseErrorFilter caught ResponseError:', {
      code: exception.code,
      message: exception.message,
      category: exception.category,
      httpStatus: exception.httpStatus,
    });

    // 根据错误类别映射HTTP状态码
    const httpStatus = this.mapToHttpStatus(exception);

    // 构建错误响应
    const errorResponse = {
      success: false,
      error: {
        code: exception.code,
        message: exception.message,
        category: exception.category || 'SYSTEM',
        timestamp: exception.timestamp,
      },
      path: request.url,
      method: request.method,
      statusCode: httpStatus,
    };

    // 如果有上下文信息且不包含敏感数据，添加到响应中
    if (exception.context) {
      const { userId, ...safeContext } = exception.context;
      if (Object.keys(safeContext).length > 0) {
        errorResponse.error['context'] = safeContext;
      }
    }

    // 记录错误日志
    logger.error(
      `ResponseError caught: ${exception.message}`,
      {
        code: exception.code,
        path: request.url,
        method: request.method,
        statusCode: httpStatus,
        category: exception.category,
        context: exception.context,
        stack: exception.stack,
      }
    );

    // 返回结构化错误响应
    response.status(httpStatus).json(errorResponse);
  }

  /**
   * 根据错误类别映射到HTTP状态码
   */
  private mapToHttpStatus(error: ResponseError): HttpStatus {
    // 优先使用 ResponseError 实例中的 httpStatus
    if (error.httpStatus) {
      return error.httpStatus;
    }

    // 如果没有，根据错误代码使用映射表
    const statusMap: Record<number, HttpStatus> = {
      // Equipment errors
      8000: HttpStatus.NOT_FOUND,     // EQUIPMENT_NOT_FOUND
      8001: HttpStatus.CONFLICT,      // EQUIPMENT_ALREADY_EXISTS
      8002: HttpStatus.CONFLICT,      // EQUIPMENT_CODE_EXISTS
      8003: HttpStatus.BAD_REQUEST,   // EQUIPMENT_CREATE_FAILED
      8004: HttpStatus.BAD_REQUEST,   // EQUIPMENT_UPDATE_FAILED
      8005: HttpStatus.BAD_REQUEST,   // EQUIPMENT_DELETE_FAILED
      8006: HttpStatus.INTERNAL_SERVER_ERROR, // EQUIPMENT_FETCH_FAILED
      8009: HttpStatus.BAD_REQUEST,   // EQUIPMENT_INVALID_CODE
      8010: HttpStatus.BAD_REQUEST,   // EQUIPMENT_INACTIVE_EQUIPMENT

      // Scenario errors
      7000: HttpStatus.NOT_FOUND,     // SCENARIO_NOT_FOUND
      7001: HttpStatus.CONFLICT,      // SCENARIO_ALREADY_EXISTS
      7002: HttpStatus.CONFLICT,      // SCENARIO_CODE_EXISTS

      // Exercise errors
      11000: HttpStatus.NOT_FOUND,    // EXERCISE_NOT_FOUND
      11001: HttpStatus.INTERNAL_SERVER_ERROR, // EXERCISE_FETCH_FAILED

      // Common errors
      1003: HttpStatus.NOT_FOUND,     // COMMON_NOT_FOUND
      1000: HttpStatus.BAD_REQUEST,   // COMMON_BAD_REQUEST
      1001: HttpStatus.UNAUTHORIZED,  // COMMON_UNAUTHORIZED
      1002: HttpStatus.FORBIDDEN,     // COMMON_FORBIDDEN
      1005: HttpStatus.BAD_REQUEST,   // COMMON_VALIDATION_ERROR
    };

    if (statusMap[error.code]) {
      return statusMap[error.code];
    }

    // 根据错误类别进行通用映射
    if (error.category) {
      if (error.category === 'VALIDATION') {
        return HttpStatus.BAD_REQUEST;
      }
      if (error.category === 'AUTH') {
        return HttpStatus.UNAUTHORIZED;
      }
      if (error.category === 'BUSINESS') {
        return HttpStatus.BAD_REQUEST;
      }
    }

    // 默认为服务器内部错误
    return HttpStatus.INTERNAL_SERVER_ERROR;
  }
}

/**
 * 全局异常过滤器 - 处理除 ResponseError 外的其他类型异常
 */
@Catch(HttpException, Error)
export class GlobalExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(GlobalExceptionFilter.name);

  catch(exception: any, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    // 🔥 关键修复：如果是 ResponseError，直接在这里处理，不要交给 GlobalExceptionFilter
    if (exception instanceof ResponseError) {
      logger.debug('🔥 GlobalExceptionFilter 拦截到 ResponseError，直接处理，避免重复处理');

      // 直接按照 ResponseErrorFilter 的逻辑处理
      const httpStatus = this.mapToHttpStatus(exception);

      const errorResponse = {
        success: false,
        error: {
          code: exception.code,
          message: exception.message,
          category: exception.category || 'BUSINESS',
          timestamp: exception.timestamp,
        },
        path: request.url,
        method: request.method,
        statusCode: httpStatus,
      };

      // 如果有上下文信息且不包含敏感数据，添加到响应中
      if (exception.context) {
        const { userId, ...safeContext } = exception.context;
        if (Object.keys(safeContext).length > 0) {
          errorResponse.error['context'] = safeContext;
        }
      }

      // 记录错误日志
      logger.error(
        `GlobalExceptionFilter 处理 ResponseError: ${exception.message}`,
        {
          code: exception.code,
          path: request.url,
          method: request.method,
          statusCode: httpStatus,
          category: exception.category,
          context: exception.context,
        }
      );

      response.status(httpStatus).json(errorResponse);
      return;
    }

    // 添加调试日志
    logger.debug('🌍 GlobalExceptionFilter caught exception:', {
      type: exception.constructor?.name || typeof exception,
      message: exception.message,
    });

    // 处理非 ResponseError 类型的异常

    let httpStatus: HttpStatus;
    let message: string;
    let errorCode: number;

    if (exception instanceof HttpException) {
      httpStatus = exception.getStatus();
      const errorResponse = exception.getResponse();
      message = typeof errorResponse === 'string'
        ? errorResponse
        : (errorResponse as any)?.message || 'HTTP Exception';
      errorCode = httpStatus;
    } else if (exception instanceof Error) {
      httpStatus = HttpStatus.INTERNAL_SERVER_ERROR;
      message = exception.message || 'Internal Server Error';
      errorCode = 1004; // COMMON_INTERNAL_SERVER_ERROR
    } else {
      httpStatus = HttpStatus.INTERNAL_SERVER_ERROR;
      message = 'Unknown Error';
      errorCode = 1004;
    }

    const errorResponse = {
      success: false,
      error: {
        code: errorCode,
        message: message,
        category: 'SYSTEM',
        timestamp: new Date().toISOString(),
      },
      path: request.url,
      method: request.method,
      statusCode: httpStatus,
    };

    // 记录错误日志
    logger.error(
      `Global exception caught: ${message}`,
      {
        path: request.url,
        method: request.method,
        statusCode: httpStatus,
        exceptionType: exception.constructor.name,
        stack: exception instanceof Error ? exception.stack : undefined,
      }
    );

    response.status(httpStatus).json(errorResponse);
  }

  /**
   * 根据错误类别映射到HTTP状态码 - 复制自 ResponseErrorFilter
   */
  private mapToHttpStatus(error: ResponseError): HttpStatus {
    // 优先使用 ResponseError 实例中的 httpStatus
    if (error.httpStatus) {
      return error.httpStatus;
    }

    // 如果没有，根据错误代码使用映射表
    const statusMap: Record<number, HttpStatus> = {
      // Equipment errors
      8000: HttpStatus.NOT_FOUND,     // EQUIPMENT_NOT_FOUND
      8001: HttpStatus.CONFLICT,      // EQUIPMENT_ALREADY_EXISTS
      8002: HttpStatus.CONFLICT,      // EQUIPMENT_CODE_EXISTS
      8003: HttpStatus.BAD_REQUEST,   // EQUIPMENT_CREATE_FAILED
      8004: HttpStatus.BAD_REQUEST,   // EQUIPMENT_UPDATE_FAILED
      8005: HttpStatus.BAD_REQUEST,   // EQUIPMENT_DELETE_FAILED
      8006: HttpStatus.INTERNAL_SERVER_ERROR, // EQUIPMENT_FETCH_FAILED
      8009: HttpStatus.BAD_REQUEST,   // EQUIPMENT_INVALID_CODE
      8010: HttpStatus.BAD_REQUEST,   // EQUIPMENT_INACTIVE_EQUIPMENT

      // Scenario errors
      7000: HttpStatus.NOT_FOUND,     // SCENARIO_NOT_FOUND
      7001: HttpStatus.CONFLICT,      // SCENARIO_ALREADY_EXISTS
      7002: HttpStatus.CONFLICT,      // SCENARIO_CODE_EXISTS

      // Exercise errors
      11000: HttpStatus.NOT_FOUND,    // EXERCISE_NOT_FOUND
      11001: HttpStatus.INTERNAL_SERVER_ERROR, // EXERCISE_FETCH_FAILED

      // Common errors
      1003: HttpStatus.NOT_FOUND,     // COMMON_NOT_FOUND
      1000: HttpStatus.BAD_REQUEST,   // COMMON_BAD_REQUEST
      1001: HttpStatus.UNAUTHORIZED,  // COMMON_UNAUTHORIZED
      1002: HttpStatus.FORBIDDEN,     // COMMON_FORBIDDEN
      1005: HttpStatus.BAD_REQUEST,   // COMMON_VALIDATION_ERROR
    };

    if (statusMap[error.code]) {
      return statusMap[error.code];
    }

    // 根据错误类别进行通用映射
    if (error.category) {
      if (error.category === 'VALIDATION') {
        return HttpStatus.BAD_REQUEST;
      }
      if (error.category === 'AUTH') {
        return HttpStatus.UNAUTHORIZED;
      }
      if (error.category === 'BUSINESS') {
        return HttpStatus.BAD_REQUEST;
      }
    }

    // 默认为服务器内部错误
    return HttpStatus.INTERNAL_SERVER_ERROR;
  }
}