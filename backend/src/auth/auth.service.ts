import { PrismaService } from 'nestjs-prisma';
// import { Prisma, User } from '@prisma/client';
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ConflictException,
  UnauthorizedException,
  Logger,
  Inject,
  forwardRef,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { PasswordService } from './password.service';
import { SignupInput } from './dto/signup.input';
import { Token } from './models/token.model';
import { SecurityConfig } from '../common/configs/config.interface';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { UsersService } from '../users/users.service';
import { logger } from '../common/logger/logger';

@Injectable()
export class AuthService {

  constructor(
    private readonly jwtService: JwtService,
    private readonly prisma: PrismaService,
    private readonly passwordService: PasswordService,
    private readonly configService: ConfigService,
    private readonly supabaseApi: SupabaseApiService,
    @Inject(forwardRef(() => UsersService))
    private readonly usersService: UsersService,
  ) {
    logger.info('AuthService initialized');
  }

  async createUser(payload: SignupInput): Promise<Token> {
    // TODO: Fix user creation after Prisma client regeneration
    throw new BadRequestException('User registration temporarily disabled during migration');
  }

  async login(email: string, password: string): Promise<Token> {
    // TODO: Fix authentication after Prisma client regeneration
    throw new BadRequestException('Authentication temporarily disabled during migration');
  }

  async validateUser(userId: string): Promise<any> {
    logger.debug(`🔍 AuthService.validateUser called with userId: ${userId}`);

    // 验证输入参数
    if (!userId) {
      logger.error('❌ userId is null, undefined, or empty string');
      return null;
    }

    if (typeof userId !== 'string') {
      logger.error(`❌ userId is not a string, received type: ${typeof userId}, value: ${userId}`);
      return null;
    }

    logger.debug(`📝 UserId type and format validation passed: ${userId}`);

    try {
      logger.debug('🔍 Calling usersService.findOne...');
      const user = await this.usersService.findOne(userId);

      if (user) {
        logger.info(`✅ User found successfully for userId: ${userId}`);
        logger.debug(`👤 User data keys: ${Object.keys(user)}`);
        // 不要记录完整的用户数据以保护隐私，只记录关键字段
        logger.debug(`📧 User email: ${user.email || 'N/A'}`);
        logger.debug(`📛 User name: ${user.name || 'N/A'}`);
        return user;
      } else {
        logger.warn(`⚠️ No user found for userId: ${userId}`);
        return null;
      }

    } catch (error) {
      logger.error(`💥 Error in usersService.findOne for userId: ${userId}`);
      logger.error(`🔥 Error type: ${error.constructor.name}`);
      logger.error(`📝 Error message: ${error.message}`);
      logger.error(`📊 Error stack: ${error.stack}`);

      return null;
    }
  }

  async getUserFromToken(token: string): Promise<any> {
    try {
      const decoded = this.jwtService.decode(token) as any;
      const userId = decoded?.userId || decoded?.sub;
      return await this.usersService.findOne(userId);
    } catch (error) {
      logger.error(`Error getting user from token: ${error.message}`);
      return null;
    }
  }

  generateTokens(payload: { userId: string }): Token {
    return {
      accessToken: this.generateAccessToken(payload),
      refreshToken: this.generateRefreshToken(payload),
    };
  }

  private generateAccessToken(payload: { userId: string }): string {
    return this.jwtService.sign(payload);
  }

  private generateRefreshToken(payload: { userId: string }): string {
    const securityConfig = this.configService.get<SecurityConfig>('security');
    return this.jwtService.sign(payload, {
      secret: this.configService.get('JWT_REFRESH_SECRET'),
      expiresIn: securityConfig.refreshIn,
    });
  }

  refreshToken(token: string) {
    try {
      const { userId } = this.jwtService.verify(token, {
        secret: this.configService.get('JWT_REFRESH_SECRET'),
      });

      return this.generateTokens({
        userId,
      });
    } catch (e) {
      throw new UnauthorizedException();
    }
  }
}
