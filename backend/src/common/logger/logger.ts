import { ConsoleLogger, Injectable, LogLevel, Scope, Optional } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import * as winston from 'winston';
import 'winston-daily-rotate-file';

// 确保日志目录存在
const logDir = path.join(process.cwd(), 'logs');
if (!fs.existsSync(logDir)) {
    fs.mkdirSync(logDir, { recursive: true });
}

// 配置 Winston 日志格式
const logFormat = winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.printf(({ level, message, timestamp, context, trace }) => {
        return `${timestamp} [${level.toUpperCase()}] [${context || 'Application'}] ${message}${
            trace ? `\n${trace}` : ''
        }`;
    })
);

const options = {
    format: logFormat,
    transports: [
        // 控制台输出
        new winston.transports.Console(),
        // 普通日志文件
        new (winston.transports as any).DailyRotateFile({
            filename: path.join(logDir, 'application-%DATE%.log'),
            datePattern: 'YYYY-MM-DD',
            maxSize: '20m',
            maxFiles: '14d',
            level: 'info',
        }),
        // 错误日志文件
        new (winston.transports as any).DailyRotateFile({
            filename: path.join(logDir, 'error-%DATE%.log'),
            datePattern: 'YYYY-MM-DD',
            maxSize: '20m',
            maxFiles: '14d',
            level: 'error',
        }),
    ],
};

export const logger = winston.createLogger(options);

/**
 * 自定义日志服务
 * 同时支持控制台输出和文件记录
 */
@Injectable({ scope: Scope.TRANSIENT })
export class LoggerService extends ConsoleLogger {
    private winstonLogger: winston.Logger;

    constructor(@Optional() context?: string) {
        super();
        this.winstonLogger = logger;
    }

    /**
     * 记录日志
     * @param message 日志消息
     * @param context 上下文
     */
    log(message: any, context?: string): void {
        super.log(message, context);
        this.winstonLogger.info(message, { context: context || this.context });
    }

    /**
     * 记录错误日志
     * @param message 错误消息
     * @param trace 错误堆栈
     * @param context 上下文
     */
    error(message: any, trace?: string, context?: string): void {
        super.error(message, trace, context);
        this.winstonLogger.error(message, { trace, context: context || this.context });
    }

    /**
     * 记录警告日志
     * @param message 警告消息
     * @param context 上下文
     */
    warn(message: any, context?: string): void {
        super.warn(message, context);
        this.winstonLogger.warn(message, { context: context || this.context });
    }

    /**
     * 记录调试日志
     * @param message 调试消息
     * @param context 上下文
     */
    debug(message: any, context?: string): void {
        super.debug(message, context);
        this.winstonLogger.debug(message, { context: context || this.context });
    }

    /**
     * 记录详细日志
     * @param message 详细消息
     * @param context 上下文
     */
    verbose(message: any, context?: string): void {
        super.verbose(message, context);
        this.winstonLogger.verbose(message, { context: context || this.context });
    }

    // 自定义方法，记录API请求日志
    logApiRequest(method: string, url: string, params?: any, body?: any): void {
        this.winstonLogger.info('API请求', {
            method,
            url,
            params,
            body,
            timestamp: new Date().toISOString(),
        });
    }

    // 自定义方法，记录API响应日志
    logApiResponse(
        method: string,
        url: string,
        statusCode: number,
        responseTime: number,
        data?: any
    ): void {
        this.winstonLogger.info('API响应', {
            method,
            url,
            statusCode,
            responseTime,
            data,
            timestamp: new Date().toISOString(),
        });
    }

    // 自定义方法，记录API错误日志
    logApiError(method: string, url: string, statusCode: number, error: any): void {
        this.winstonLogger.error('API错误', {
            method,
            url,
            statusCode,
            error: error.message,
            stack: error.stack,
            timestamp: new Date().toISOString(),
        });
    }

    // 记录业务操作日志
    logBusinessOperation(operation: string, details: any): void {
        this.winstonLogger.info('业务操作', {
            operation,
            details,
            timestamp: new Date().toISOString(),
        });
    }
}
