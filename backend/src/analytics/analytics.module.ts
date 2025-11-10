import { Module } from '@nestjs/common';
import { AnalyticsController } from './analytics.controller';
import { CommonModule } from '../common/common.module';

/**
 * Analytics Module
 * 用户分析和数据统计模块
 */
@Module({
  imports: [CommonModule], // CommonModule 提供 SupabaseApiService
  controllers: [AnalyticsController],
  providers: [],
  exports: [],
})
export class AnalyticsModule {}