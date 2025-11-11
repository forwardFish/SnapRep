import { Resolver, Query, Args, Int } from '@nestjs/graphql';
import { ExercisesService } from './exercises.service';
import { Logger } from '@nestjs/common';
import { logger } from '../common/logger/logger';

@Resolver('Exercise')
export class ExercisesResolver {
  // private readonly logger = new Logger(ExercisesResolver.name);

  constructor(private readonly exercisesService: ExercisesService) {}

  @Query('exercises')
  async getExercises(
    @Args('page', { type: () => Int, defaultValue: 1 }) page: number,
    @Args('pageSize', { type: () => Int, defaultValue: 10 }) pageSize: number,
    @Args('intent', { nullable: true }) intent?: string,
    @Args('difficulty', { nullable: true }) difficulty?: string,
    @Args('primaryMuscle', { nullable: true }) primaryMuscle?: string,
  ) {
    logger.debug(`GraphQL查询练习: page=${page}, pageSize=${pageSize}`);

    const filters = {
      intent,
      difficulty,
      primaryMuscle,
      isActive: true
    };

    return await this.exercisesService.findWithPagination(page, pageSize, filters);
  }

  @Query('exercise')
  async getExercise(@Args('id') id: string) {
    logger.debug(`GraphQL查询单个练习: id=${id}`);
    return await this.exercisesService.findById(id);
  }

  @Query('exerciseByCode')
  async getExerciseByCode(@Args('code') code: string) {
    logger.debug(`GraphQL根据代码查询练习: code=${code}`);
    return await this.exercisesService.findByCode(code);
  }

  @Query('exerciseStats')
  async getExerciseStats() {
    logger.debug('GraphQL查询练习统计');
    return await this.exercisesService.getStats();
  }
}