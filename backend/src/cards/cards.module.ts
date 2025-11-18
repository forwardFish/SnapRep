import { Module } from '@nestjs/common';
import { CardsService } from './cards.service';
import { CardsController } from './cards.controller';
// import { CardsResolver } from './cards.resolver';  // Commented out - using REST API instead of GraphQL
import { CardsDao } from './cards.dao';
import { CardGeneratorService } from './services/card-generator.service';
import { RarityCalculatorService } from './services/rarity-calculator.service';
import { WorkoutSessionsModule } from '../workout-sessions/workout-sessions.module';
import { AuthModule } from '../auth/auth.module';
import { UsersModule } from '../users/users.module';
import { CommonModule } from '../common/common.module';

/**
 * Cards 模块
 * 处理分享卡片的生成、管理和稀有度计算
 */
@Module({
  imports: [
    CommonModule, // 为SupabaseApiService提供支持
    WorkoutSessionsModule,
    AuthModule, // 为JwtAuthGuard提供支持
    UsersModule, // 为JwtAuthGuard提供UsersService
  ],
  providers: [
    CardsService,
    // CardsResolver,  // Commented out - using REST API instead of GraphQL
    CardsDao,
    CardGeneratorService,
    RarityCalculatorService,
  ],
  controllers: [CardsController],
  exports: [CardsService, RarityCalculatorService],
})
export class CardsModule {}