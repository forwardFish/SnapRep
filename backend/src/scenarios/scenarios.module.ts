import { Module } from '@nestjs/common';
import { ScenariosController } from './scenarios.controller';
import { ScenariosService } from './scenarios.service';
import { ScenariosDao } from './scenarios.dao';

@Module({
  imports: [],
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