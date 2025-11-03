import { Module } from '@nestjs/common';
import { ExercisesService } from './exercises.service';
// import { ExercisesResolver } from './exercises.resolver';  // Commented out - using REST API instead of GraphQL
import { ExercisesController } from './exercises.controller';
import { ExercisesDao } from './exercises.dao';
import { WorkoutRecommendationService } from './services/workout-recommendation.service';
import { ExerciseMatchingService } from './services/exercise-matching.service';

@Module({
  providers: [
    ExercisesService,
    // ExercisesResolver,  // Commented out - using REST API instead of GraphQL
    ExercisesDao,
    WorkoutRecommendationService,
    ExerciseMatchingService,
  ],
  controllers: [ExercisesController],
  exports: [ExercisesService, WorkoutRecommendationService],
})
export class ExercisesModule {}