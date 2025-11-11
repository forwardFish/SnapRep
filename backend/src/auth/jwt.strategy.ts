import { Strategy, ExtractJwt } from 'passport-jwt';
import { PassportStrategy } from '@nestjs/passport';
import { Injectable, UnauthorizedException, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
// import { User } from '@prisma/client';
import { AuthService } from './auth.service';
import { JwtDto } from './dto/jwt.dto';
import { logger } from '../common/logger/logger';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  // private readonly logger = new Logger(JwtStrategy.name);

  constructor(
    private readonly authService: AuthService,
    readonly configService: ConfigService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      secretOrKey: configService.get('JWT_ACCESS_SECRET'),
    });
    logger.info('JwtStrategy initialized');
  }


  async validate(payload: JwtDto): Promise<any> {
    logger.debug('🔍 JWT Validation Started');
    logger.debug(`📋 Token Payload: ${JSON.stringify(payload)}`);

    // 检查payload的基本结构
    if (!payload) {
      logger.error('❌ Payload is null or undefined');
      throw new UnauthorizedException('Invalid token payload');
    }

    if (!payload.userId) {
      logger.error('❌ userId is missing from payload');
      logger.error(`🔍 Payload keys: ${Object.keys(payload)}`);
      throw new UnauthorizedException('Invalid token: missing userId');
    }

    logger.debug(`🔑 Extracted userId: ${payload.userId}`);

    try {
      logger.debug('🔍 Calling authService.validateUser...');
      const user = await this.authService.validateUser(payload.userId);

      if (!user) {
        logger.error(`❌ User not found for userId: ${payload.userId}`);
        throw new UnauthorizedException('User not found');
      }

      logger.info(`✅ User validation successful for: ${payload.userId}`);
      logger.debug(`👤 User data: ${JSON.stringify(user, null, 2)}`);

      return user;
    } catch (error) {
      logger.error(`💥 Error during user validation: ${error.message}`);
      logger.error(`📊 Error stack: ${error.stack}`);

      if (error instanceof UnauthorizedException) {
        throw error;
      }

      throw new UnauthorizedException(`Authentication failed: ${error.message}`);
    }
  }
}
