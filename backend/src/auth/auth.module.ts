import { forwardRef, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigService } from '@nestjs/config';
import { PasswordService } from './password.service';
import { GqlAuthGuard } from './gql-auth.guard';
import { AuthService } from './auth.service';
import { AuthResolver } from './auth.resolver';
import { AuthController } from './auth.controller';
import { SupabaseAuthService } from './supabase-auth.service';
import { JwtStrategy } from './jwt.strategy';
import { SecurityConfig } from '../common/configs/config.interface';
import { CommonModule } from '../common/common.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    forwardRef(() => UsersModule),
    CommonModule, // 提供 SupabaseApiService
    PassportModule.register({ defaultStrategy: 'jwt' }),
    JwtModule.registerAsync({
      useFactory: async (configService: ConfigService) => {
        const securityConfig = configService.get<SecurityConfig>('security');
        return {
          secret: configService.get<string>('JWT_ACCESS_SECRET'),
          signOptions: {
            expiresIn: securityConfig.expiresIn,
          },
        };
      },
      inject: [ConfigService],
    }),
  ],
  controllers: [AuthController], // 新增 REST API 控制器
  providers: [
    AuthService,         // 原有的 GraphQL 认证服务
    AuthResolver,        // 原有的 GraphQL 解析器
    SupabaseAuthService, // 新增的 Supabase 认证服务
    JwtStrategy,
    GqlAuthGuard,
    PasswordService,
  ],
  exports: [
    GqlAuthGuard,
    SupabaseAuthService, // 导出新的认证服务
  ],
})
export class AuthModule {}