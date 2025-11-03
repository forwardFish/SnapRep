import { Module } from '@nestjs/common';
import { WorkoutSessionsService } from './workout-sessions.service';
// import { WorkoutSessionsResolver } from './workout-sessions.resolver';  // Commented out - using REST API instead of GraphQL
import { WorkoutSessionsController } from './workout-sessions.controller';
import { WorkoutSessionsDao } from './workout-sessions.dao';
import { ExercisesModule } from '../exercises/exercises.module';

@Module({
  imports: [ExercisesModule],
  providers: [
    WorkoutSessionsService,
    // WorkoutSessionsResolver,  // Commented out - using REST API instead of GraphQL
    WorkoutSessionsDao,
  ],
  controllers: [WorkoutSessionsController],
  exports: [WorkoutSessionsService],
})
export class WorkoutSessionsModule {}