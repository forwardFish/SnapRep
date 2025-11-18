import { Module } from '@nestjs/common';
import { WorkoutSessionsService } from './workout-sessions.service';
// import { WorkoutSessionsResolver } from './workout-sessions.resolver';  // Commented out - using REST API instead of GraphQL
import { WorkoutSessionsController } from './workout-sessions.controller';
import { WorkoutSessionsDao } from './workout-sessions.dao';
import { ExercisesModule } from '../exercises/exercises.module';
import { AuthModule } from '../auth/auth.module';
import { UsersModule } from '../users/users.module';
import { CommonModule } from '../common/common.module';

@Module({
  imports: [
    CommonModule, // 为SupabaseApiService提供支持
    ExercisesModule,
    AuthModule,  // 为JwtAuthGuard提供支持
    UsersModule, // 为JwtAuthGuard提供UsersService
  ],
  providers: [
    WorkoutSessionsService,
    // WorkoutSessionsResolver,  // Commented out - using REST API instead of GraphQL
    WorkoutSessionsDao,
  ],
  controllers: [WorkoutSessionsController],
  exports: [WorkoutSessionsService],
})
export class WorkoutSessionsModule {}