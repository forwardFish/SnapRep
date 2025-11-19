import { Module } from '@nestjs/common';
import { ChallengesController } from './challenges.controller';
import { ChallengesService } from './challenges.service';
import { CommonModule } from '../common/common.module';

@Module({
  imports: [CommonModule], // Import CommonModule for SupabaseApiService
  controllers: [ChallengesController],
  providers: [ChallengesService],
  exports: [ChallengesService],
})
export class ChallengesModule {}
