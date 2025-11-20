import { Module, forwardRef } from '@nestjs/common';
import { SubscriptionService } from './subscription.service.temp'; // Use temp version until migration
import { SubscriptionController } from './subscription.controller';
import { DailyUsageService } from './daily-usage.service.temp'; // Use temp version until migration
import { GooglePlayService } from './google-play.service';
import { SubscriptionTasksService } from './subscription-tasks.service';
import { PrismaModule } from 'nestjs-prisma';
import { SubscriptionGuard } from './guards/subscription.guard';
import { UsageGuard } from './guards/usage.guard';
import { JwtModule } from '@nestjs/jwt';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    PrismaModule,
    JwtModule.register({}), // Import JwtModule to provide JwtService
    forwardRef(() => UsersModule), // Import UsersModule for UsersService, use forwardRef to avoid circular deps
  ],
  controllers: [SubscriptionController],
  providers: [
    SubscriptionService,
    DailyUsageService,
    GooglePlayService,
    SubscriptionTasksService,
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