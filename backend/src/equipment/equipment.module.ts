import { Module } from '@nestjs/common';
import { EquipmentController } from './equipment.controller';
import { EquipmentService } from './equipment.service';
import { EquipmentDao } from './equipment.dao';
import { CommonModule } from '../common/common.module';

/**
 * Equipment Module
 * 器材管理模块
 */
@Module({
  imports: [CommonModule],
  controllers: [EquipmentController],
  providers: [
    EquipmentService,
    EquipmentDao,
  ],
  exports: [
    EquipmentService,
    EquipmentDao
  ],
})
export class EquipmentModule {}