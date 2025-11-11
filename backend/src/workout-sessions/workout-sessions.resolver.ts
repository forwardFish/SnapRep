import { Resolver, Query, Mutation, Args, Int } from '@nestjs/graphql';
import { UseGuards, Logger } from '@nestjs/common';
import { WorkoutSessionsService } from './workout-sessions.service';
import { GqlAuthGuard } from '../auth/gql-auth.guard';
import {
  CreateWorkoutSessionDto,
  UpdateWorkoutSessionDto,
  SessionQueryDto,
  UserStatsQueryDto
} from './dto/workout-session.dto';
import { logger } from '../common/logger/logger';

/**
 * WorkoutSessions GraphQL 解析器
 * 提供训练会话管理的 GraphQL 接口
 */
@Resolver('WorkoutSession')
@UseGuards(GqlAuthGuard)
export class WorkoutSessionsResolver {
  // private readonly logger = new Logger(WorkoutSessionsResolver.name);

  constructor(private readonly workoutSessionsService: WorkoutSessionsService) {}

  /**
   * 创建训练会话
   */
  @Mutation('createWorkoutSession')
  async createWorkoutSession(
    @Args('input') createDto: CreateWorkoutSessionDto
  ) {
    logger.debug(`GraphQL创建训练会话: userId=${createDto.userId}`);

    try {
      const session = await this.workoutSessionsService.createSession(createDto);
      return session;
    } catch (error) {
      logger.error(`GraphQL创建训练会话失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 从推荐结果创建训练会话
   */
  @Mutation('createSessionFromRecommendation')
  async createSessionFromRecommendation(
    @Args('userId') userId: string,
    @Args('recommendation') recommendationDto: any
  ) {
    logger.debug(`GraphQL从推荐创建会话: userId=${userId}`);

    try {
      const session = await this.workoutSessionsService.createSessionFromRecommendation(
        userId,
        recommendationDto
      );
      return session;
    } catch (error) {
      logger.error(`GraphQL从推荐创建会话失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取训练会话详情
   */
  @Query('workoutSession')
  async getWorkoutSession(
    @Args('id') id: string,
    @Args('includeExercises', { type: () => Boolean, defaultValue: true }) includeExercises: boolean
  ) {
    logger.debug(`GraphQL获取训练会话: sessionId=${id}`);

    try {
      return await this.workoutSessionsService.findById(id, includeExercises);
    } catch (error) {
      logger.error(`GraphQL获取训练会话失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取用户的训练会话列表
   */
  @Query('workoutSessions')
  async getWorkoutSessions(
    @Args('userId') userId: string,
    @Args('status', { nullable: true }) status?: string,
    @Args('fromDate', { nullable: true }) fromDate?: string,
    @Args('toDate', { nullable: true }) toDate?: string,
    @Args('limit', { type: () => Int, defaultValue: 20 }) limit: number = 20,
    @Args('offset', { type: () => Int, defaultValue: 0 }) offset: number = 0
  ) {
    logger.debug(`GraphQL获取用户会话列表: userId=${userId}`);

    try {
      const query: SessionQueryDto = {
        status,
        fromDate,
        toDate,
        limit,
        offset
      };

      return await this.workoutSessionsService.findUserSessions(userId, query);
    } catch (error) {
      logger.error(`GraphQL获取用户会话列表失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 更新训练会话
   */
  @Mutation('updateWorkoutSession')
  async updateWorkoutSession(
    @Args('id') id: string,
    @Args('input') updateDto: UpdateWorkoutSessionDto
  ) {
    logger.debug(`GraphQL更新训练会话: sessionId=${id}`);

    try {
      const session = await this.workoutSessionsService.updateSession(id, updateDto);
      return session;
    } catch (error) {
      logger.error(`GraphQL更新训练会话失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 完成训练会话
   */
  @Mutation('completeWorkoutSession')
  async completeWorkoutSession(
    @Args('id') id: string,
    @Args('actualDuration', { type: () => Int, nullable: true }) actualDuration?: number,
    @Args('rating', { type: () => Int, nullable: true }) rating?: number,
    @Args('feedback', { nullable: true }) feedback?: string
  ) {
    logger.debug(`GraphQL完成训练会话: sessionId=${id}`);

    try {
      const session = await this.workoutSessionsService.completeSession(
        id,
        actualDuration,
        rating,
        feedback
      );
      return session;
    } catch (error) {
      logger.error(`GraphQL完成训练会话失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 放弃训练会话
   */
  @Mutation('abandonWorkoutSession')
  async abandonWorkoutSession(
    @Args('id') id: string,
    @Args('reason', { nullable: true }) reason?: string
  ) {
    logger.debug(`GraphQL放弃训练会话: sessionId=${id}`);

    try {
      const session = await this.workoutSessionsService.abandonSession(id, reason);
      return session;
    } catch (error) {
      logger.error(`GraphQL放弃训练会话失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 更新会话中的动作
   */
  @Mutation('updateSessionExercise')
  async updateSessionExercise(
    @Args('sessionId') sessionId: string,
    @Args('exerciseId') exerciseId: string,
    @Args('input') updateDto: any
  ) {
    logger.debug(`GraphQL更新会话动作: sessionId=${sessionId}, exerciseId=${exerciseId}`);

    try {
      const updatedExercise = await this.workoutSessionsService.updateSessionExercise(
        sessionId,
        exerciseId,
        updateDto
      );
      return updatedExercise;
    } catch (error) {
      logger.error(`GraphQL更新会话动作失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取用户训练统计
   */
  @Query('userWorkoutStats')
  async getUserWorkoutStats(
    @Args('userId') userId: string,
    @Args('days', { type: () => Int, defaultValue: 30 }) days: number = 30
  ) {
    logger.debug(`GraphQL获取用户训练统计: userId=${userId}, days=${days}`);

    try {
      const query: UserStatsQueryDto = { days };
      return await this.workoutSessionsService.getUserStats(userId, query);
    } catch (error) {
      logger.error(`GraphQL获取用户训练统计失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取今日全局完成会话数
   */
  @Query('todayCompletedSessions')
  async getTodayCompletedSessions() {
    logger.debug('GraphQL获取今日完成会话数');

    try {
      const health = await this.workoutSessionsService.healthCheck();
      return {
        count: health.todayCompletedCount,
        timestamp: health.timestamp
      };
    } catch (error) {
      logger.error(`GraphQL获取今日完成会话数失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取当前活跃会话数
   */
  @Query('activeSessionsCount')
  async getActiveSessionsCount() {
    logger.debug('GraphQL获取活跃会话数');

    try {
      const health = await this.workoutSessionsService.healthCheck();
      return {
        count: health.activeSessionsCount,
        timestamp: health.timestamp
      };
    } catch (error) {
      logger.error(`GraphQL获取活跃会话数失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 服务健康检查
   */
  @Query('workoutSessionsHealth')
  async healthCheck() {
    logger.debug('GraphQL训练会话服务健康检查');

    try {
      return await this.workoutSessionsService.healthCheck();
    } catch (error) {
      logger.error(`GraphQL健康检查失败: ${error.message}`);
      throw error;
    }
  }
}