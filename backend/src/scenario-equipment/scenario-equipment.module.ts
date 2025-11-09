import { Module } from '@nestjs/common';
import { ScenarioEquipmentController } from './scenario-equipment.controller';
import { ScenarioEquipmentService } from './scenario-equipment.service';
import { ScenarioEquipmentDao } from './scenario-equipment.dao';
import { CommonModule } from '../common/common.module';

/**
 * ScenarioEquipment Module
 * 器材管理模块
 */
@Module({
  imports: [CommonModule],
  controllers: [ScenarioEquipmentController],
  providers: [
    ScenarioEquipmentService,
    ScenarioEquipmentDao,
  ],
  exports: [
    ScenarioEquipmentService,
    ScenarioEquipmentDao
  ],
})
export class ScenarioEquipmentModule {}