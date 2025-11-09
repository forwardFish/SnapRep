import { Module } from '@nestjs/common';
import { ScenariosController } from './scenarios.controller';
import { ScenariosService } from './scenarios.service';
import { ScenariosDao } from './scenarios.dao';
import { CommonModule } from '../common/common.module';

@Module({
  imports: [CommonModule], // 添加CommonModule来注入SupabaseApiService
  controllers: [ScenariosController],
  providers: [
    ScenariosService,
    ScenariosDao,
  ],
  exports: [
    ScenariosService,
    ScenariosDao
  ], // 导出服务和DAO供其他模块使用
})
export class ScenariosModule {}