import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { SupabaseApiService } from './services/supabase-api.service';

@Module({
  imports: [ConfigModule],
  providers: [SupabaseApiService],
  exports: [SupabaseApiService],
})
export class CommonModule {}