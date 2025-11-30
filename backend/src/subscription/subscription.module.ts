import { Module, forwardRef } from '@nestjs/common';
import { SubscriptionService } from './subscription.service';
import { SubscriptionController } from './subscription.controller';
import { DailyUsageService } from './daily-usage.service';
import { GooglePlayService } from './google-play.service';
import { SubscriptionTasksService } from './subscription-tasks.service';
import { SubscriptionGuard } from './guards/subscription.guard';
import { UsageGuard } from './guards/usage.guard';
import { JwtModule } from '@nestjs/jwt';
import { UsersModule } from '../users/users.module';
import { CommonModule } from '../common/common.module';

/**
 * SubscriptionModule
 * 订阅管理模块
 * 使用 SupabaseApiService 直接操作数据库,绕过 Prisma 连接问题
 */
@Module({
  imports: [
    CommonModule, // 导入 CommonModule 以使用 SupabaseApiService
    JwtModule.register({}), // Import JwtModule to provide JwtService
    forwardRef(() => UsersModule), // Import UsersModule for UsersService, use forwardRef to avoid circular deps
  ],
  controllers: [SubscriptionController],
  providers: [
    SubscriptionService,
    DailyUsageService,
    GooglePlayService,
    // 注释掉 SubscriptionTasksService 以避免循环依赖
    // 后续可以将其移到单独的 TasksModule 中
    // SubscriptionTasksService,
    SubscriptionGuard,
    UsageGuard,
  ],
  exports: [
    SubscriptionService,
    DailyUsageService,
    SubscriptionGuard,
    UsageGuard,
  ],
})
export class SubscriptionModule {}
