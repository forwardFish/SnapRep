import { Module } from '@nestjs/common';
import { ScenarioEquipmentController } from './scenario-equipment.controller';
import { CommonModule } from '../common/common.module';

/**
 * ScenarioEquipment Module
 * 场景-器材关联管理模块
 * 使用 SupabaseApiService 直接操作数据库，绕过 Prisma 连接问题
 */
@Module({
  imports: [CommonModule], // CommonModule 提供 SupabaseApiService
  controllers: [ScenarioEquipmentController],
  providers: [], // 不再需要 Service 和 DAO
  exports: [], // 不再导出 Service 和 DAO
})
export class ScenarioEquipmentModule {}