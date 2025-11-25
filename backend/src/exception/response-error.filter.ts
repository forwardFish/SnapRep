import { HttpStatus, ExceptionFilter, Catch, ArgumentsHost, HttpException } from '@nestjs/common';
import { Response, Request } from 'express';
import { ResponseError } from './response-error';
import { logger } from '../common/logger/logger';

// Helper: map ResponseError to proper HTTP status
function mapToHttpStatus(error: ResponseError): HttpStatus {
  if (error.httpStatus) return error.httpStatus;

  const statusMap: Record<number, HttpStatus> = {
    // Recommendation (10000-10999)
    10000: HttpStatus.INTERNAL_SERVER_ERROR, // RECOMMENDATION_GENERATION_FAILED
    10001: HttpStatus.NOT_FOUND,             // RECOMMENDATION_NO_EXERCISES_FOUND
    10002: HttpStatus.BAD_REQUEST,           // RECOMMENDATION_INVALID_PARAMETERS
    10003: HttpStatus.INTERNAL_SERVER_ERROR, // RECOMMENDATION_REPLACE_FAILED
    10004: HttpStatus.NOT_FOUND,             // RECOMMENDATION_SESSION_NOT_FOUND
    10005: HttpStatus.INTERNAL_SERVER_ERROR, // RECOMMENDATION_ALGORITHM_ERROR

    // Equipment
    8000: HttpStatus.NOT_FOUND,
    8001: HttpStatus.CONFLICT,
    8002: HttpStatus.CONFLICT,
    8003: HttpStatus.BAD_REQUEST,
    8004: HttpStatus.BAD_REQUEST,
    8005: HttpStatus.BAD_REQUEST,
    8006: HttpStatus.INTERNAL_SERVER_ERROR,
    8009: HttpStatus.BAD_REQUEST,
    8010: HttpStatus.BAD_REQUEST,

    // Scenario
    7000: HttpStatus.NOT_FOUND,
    7001: HttpStatus.CONFLICT,
    7002: HttpStatus.CONFLICT,

    // Exercise
    11000: HttpStatus.NOT_FOUND,
    11001: HttpStatus.INTERNAL_SERVER_ERROR,

    // Common
    1003: HttpStatus.NOT_FOUND,
    1000: HttpStatus.BAD_REQUEST,
    1001: HttpStatus.UNAUTHORIZED,
    1002: HttpStatus.FORBIDDEN,
    1005: HttpStatus.BAD_REQUEST,
  };

  if (statusMap[error.code]) return statusMap[error.code];

  // Fallback by category string to avoid importing enums here
  if ((error as any).category === 'VALIDATION') return HttpStatus.BAD_REQUEST;
  if ((error as any).category === 'AUTH') return HttpStatus.UNAUTHORIZED;
  if ((error as any).category === 'BUSINESS') return HttpStatus.BAD_REQUEST;

  return HttpStatus.INTERNAL_SERVER_ERROR;
}

// Helper: drop sensitive fields from context
function safeContext(ctx: any): Record<string, unknown> | undefined {
  if (!ctx) return undefined;
  const { userId, ...rest } = ctx;
  return Object.keys(rest).length ? rest : undefined;
}

@Catch(ResponseError)
export class ResponseErrorFilter implements ExceptionFilter {
  catch(exception: ResponseError, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    const httpStatus = mapToHttpStatus(exception);

    const body: any = {
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

    const ctxOut = safeContext((exception as any).context);
    if (ctxOut) body.error.context = ctxOut;

    logger.error('ResponseError caught', {
      code: exception.code,
      path: request.url,
      method: request.method,
      statusCode: httpStatus,
      category: (exception as any).category,
      context: (exception as any).context,
      stack: exception.stack,
    });

    response.status(httpStatus).json(body);
  }
}

@Catch(HttpException, Error)
export class GlobalExceptionFilter implements ExceptionFilter {
  catch(exception: any, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    // Short-circuit: if it is (or looks like) a ResponseError, return as-is
    const isResponseErrorShape = exception instanceof ResponseError ||
      (exception?.name === 'ResponseError' && typeof exception?.code === 'number');

    if (isResponseErrorShape) {
      const err = exception as ResponseError;
      const httpStatus = mapToHttpStatus(err);

      const body: any = {
        success: false,
        error: {
          code: err.code,
          message: err.message,
          category: (err as any).category || 'BUSINESS',
          timestamp: err.timestamp,
        },
        path: request.url,
        method: request.method,
        statusCode: httpStatus,
      };

      const ctxOut = safeContext((err as any).context);
      if (ctxOut) body.error.context = ctxOut;

      logger.error('GlobalExceptionFilter handled ResponseError', {
        code: err.code,
        path: request.url,
        method: request.method,
        statusCode: httpStatus,
        category: (err as any).category,
        context: (err as any).context,
      });

      response.status(httpStatus).json(body);
      return;
    }

    // Non-ResponseError exceptions
    let httpStatus: HttpStatus;
    let message: string;
    let errorCode: number;

    if (exception instanceof HttpException) {
      httpStatus = exception.getStatus();
      const errorResponse = exception.getResponse();
      message = typeof errorResponse === 'string' ? errorResponse : (errorResponse as any)?.message || 'HTTP Exception';
      errorCode = httpStatus; // keep http status code as error code for plain HttpException
    } else if (exception instanceof Error) {
      httpStatus = HttpStatus.INTERNAL_SERVER_ERROR;
      message = exception.message || 'Internal Server Error';
      errorCode = 1004; // COMMON_INTERNAL_SERVER_ERROR
    } else {
      httpStatus = HttpStatus.INTERNAL_SERVER_ERROR;
      message = 'Unknown Error';
      errorCode = 1004;
    }

    const body = {
      success: false,
      error: {
        code: errorCode,
        message,
        category: 'SYSTEM',
        timestamp: new Date().toISOString(),
      },
      path: request.url,
      method: request.method,
      statusCode: httpStatus,
    };

    logger.error(`Global exception caught: ${message}`, {
      path: request.url,
      method: request.method,
      statusCode: httpStatus,
      exceptionType: exception?.constructor?.name,
      stack: exception instanceof Error ? exception.stack : undefined,
    });

    response.status(httpStatus).json(body);
  }
}
