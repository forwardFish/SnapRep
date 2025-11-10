import { Module } from '@nestjs/common';
import { ThemeWeeksController } from './theme-weeks.controller';
import { ThemeWeeksService } from './theme-weeks.service';
import { ThemeWeeksDao } from './theme-weeks.dao';
import { CommonModule } from '../common/common.module';

@Module({
  imports: [CommonModule], // 添加CommonModule来注入通用服务
  controllers: [ThemeWeeksController],
  providers: [
    ThemeWeeksService,
    ThemeWeeksDao,
  ],
  exports: [
    ThemeWeeksService,
    ThemeWeeksDao,
  ], // 导出服务和DAO供其他模块使用
})
export class ThemeWeeksModule {}