import {
    Injectable,
    ExecutionContext,
    UnauthorizedException,
    Inject,
    forwardRef,
    SetMetadata,
} from '@nestjs/common';
import { AuthGuard } from '@nestjs/passport';
import { Reflector } from '@nestjs/core';
import { ConfigService } from '@nestjs/config';
import { logger } from '../logger/logger';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../../users/users.service';
import { UserEntity } from '../types/user.types';
import { GqlExecutionContext } from '@nestjs/graphql';

/**
 * IS_PUBLIC_KEY元数据的键名
 * 用于标记不需要JWT认证的路由
 */
export const IS_PUBLIC_KEY = 'isPublic';

/**
 * 公开路由装饰器
 * 用于标记不需要JWT认证的路由
 */
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);

/**
 * JWT认证守卫
 * 用于验证请求中的JWT令牌
 */
@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
    constructor(
        private reflector: Reflector,
        private configService: ConfigService,
        private readonly jwtService: JwtService,
        @Inject(forwardRef(() => UsersService))
        private readonly usersService: UsersService
    ) {
        super();
    }

    /**
     * 获取请求对象（支持REST和GraphQL）
     */
    getRequest(context: ExecutionContext) {
        // 支持 REST API 和 GraphQL
        const ctx = GqlExecutionContext.create(context);

        // 如果是 GraphQL context
        if (ctx.getType() === 'graphql') {
            return ctx.getContext().req;
        }

        // 如果是 REST API context
        return context.switchToHttp().getRequest();
    }

    /**
     * 守卫激活方法
     * 决定是否允许请求通过
     */
    async canActivate(context: ExecutionContext): Promise<boolean> {
        const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
            context.getHandler(),
            context.getClass(),
        ]);

        if (isPublic) {
            return true;
        }

        const request = this.getRequest(context);
        const authHeader = request.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            logger.warn('JwtAuthGuard: 未提供有效的认证令牌头部');
            throw new UnauthorizedException('未提供有效的认证令牌');
        }

        // 处理可能的重复 Bearer 前缀问题
        // 例如: "Bearer Bearer token" -> "token"
        let token = authHeader.split(' ')[1];

        // 如果 token 又是以 "Bearer" 开头，则再次分割
        if (token && token.startsWith('Bearer ')) {
            token = token.split(' ')[1];
            logger.warn('JwtAuthGuard: 检测到重复的 Bearer 前缀，已自动处理');
        }

        if (!token) {
            logger.warn('JwtAuthGuard: Token 解析失败');
            throw new UnauthorizedException('Token 格式错误');
        }

        // 本地 JWT 验证
        try {
            const payload = await this.jwtService.verifyAsync(token, {
                secret: this.configService.get('JWT_ACCESS_SECRET') || 'access_secret_key',
            });
            logger.info(`JwtAuthGuard: 本地 JWT 验证成功, user ID: ${payload.sub || payload.userId}`);

            // 兼容不同的payload格式
            const userId = payload.sub || payload.userId;
            const user = await this.usersService.findOne(userId);

            if (!user) {
                logger.error(`JwtAuthGuard: 本地 JWT 有效，但用户未找到, user ID: ${userId}`);
                throw new UnauthorizedException('认证失败，用户不存在');
            }
            request.user = user;
            return true;
        } catch (error) {
            logger.error(`JwtAuthGuard: JWT 验证失败: ${error.message}`);
            throw new UnauthorizedException('无效的认证令牌或令牌已过期');
        }
    }

    /**
     * 处理认证失败情况
     */
    handleRequest(err: any, user: any) {
        if (err || !user) {
            throw new UnauthorizedException('认证失败');
        }
        return user;
    }
}