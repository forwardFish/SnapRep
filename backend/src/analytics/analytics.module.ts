import { Module } from '@nestjs/common';
import { AnalyticsController } from './analytics.controller';
import { CommonModule } from '../common/common.module';
import { AuthModule } from '../auth/auth.module';
import { UsersModule } from '../users/users.module';

/**
 * Analytics Module
 * 用户分析和数据统计模块
 */
@Module({
  imports: [
    CommonModule, // CommonModule 提供 SupabaseApiService
    AuthModule,   // AuthModule 提供 JwtAuthGuard 和 JwtService
    UsersModule,  // UsersModule 提供 UsersService
  ],
  controllers: [AnalyticsController],
  providers: [],
  exports: [],
})
export class AnalyticsModule {}