import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { WorkoutSessionsDao } from './workout-sessions.dao';
import { ExercisesService } from '../exercises/exercises.service';
import { WorkoutRecommendationService } from '../exercises/services/workout-recommendation.service';
import {
  CreateWorkoutSessionDto,
  UpdateWorkoutSessionDto,
  UpdateSessionExerciseDto,
  SessionQueryDto,
  UserStatsQueryDto
} from './dto/workout-session.dto';
import { QuickRecommendationDto } from '../exercises/dto/exercise-recommendation.dto';
import { SessionStatus, IntentType, Difficulty } from '@prisma/client';

/**
 * WorkoutSessions 业务逻辑服务类
 * 处理训练会话的创建、管理、状态更新和统计功能
 */
@Injectable()
export class WorkoutSessionsService {
  private readonly logger = new Logger(WorkoutSessionsService.name);

  constructor(
    private readonly workoutSessionsDao: WorkoutSessionsDao,
    private readonly exercisesService: ExercisesService,
    private readonly workoutRecommendationService: WorkoutRecommendationService,
  ) {}

  /**
   * 创建训练会话
   * @param createDto 创建会话DTO
   * @returns 创建的会话
   */
  async createSession(createDto: CreateWorkoutSessionDto) {
    try {
      this.logger.debug(`创建训练会话: userId=${createDto.userId}, intent=${createDto.intentType}`);

      // 验证用户是否有未完成的会话
      const activeSessionsCount = await this.workoutSessionsDao.getActiveSessionsCount();
      if (activeSessionsCount >= 5) {
        throw new BadRequestException('Too many active sessions. Please complete existing sessions first.');
      }

      // 验证动作是否存在
      for (const exercise of createDto.exercises) {
        const exerciseExists = await this.exercisesService.findById(exercise.exerciseId);
        if (!exerciseExists) {
          throw new NotFoundException(`Exercise not found: ${exercise.exerciseId}`);
        }
      }

      // 创建会话
      const session = await this.workoutSessionsDao.createSessionWithExercises(createDto);

      this.logger.log(`训练会话创建成功: sessionId=${session.id}, exerciseCount=${createDto.exercises.length}`);
      return session;

    } catch (error) {
      this.logger.error(`创建训练会话失败: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * 从推荐结果创建训练会话
   * @param userId 用户ID
   * @param recommendationDto 推荐请求参数
   * @returns 创建的会话
   */
  async createSessionFromRecommendation(userId: string, recommendationDto: QuickRecommendationDto) {
    try {
      this.logger.debug(`从推荐创建会话: userId=${userId}`);

      // 获取推荐
      const recommendation = await this.workoutRecommendationService.generateQuickRecommendation({
        ...recommendationDto,
        userId
      });

      if (!recommendation.exercises || recommendation.exercises.length === 0) {
        throw new BadRequestException('No suitable exercises found for the given criteria');
      }

      // 构建会话创建参数
      const createSessionDto: CreateWorkoutSessionDto = {
        userId,
        intentType: recommendationDto.intent || IntentType.MODERATE,
        scenarioId: recommendationDto.scenario,
        targetMuscles: recommendationDto.targetMuscles || [],
        totalDuration: recommendationDto.duration || 60,
        difficulty: recommendationDto.difficulty || Difficulty.GREEN,
        isSilent: recommendationDto.scenario === 'office',
        themeWeekId: recommendationDto.themeWeekId,
        exercises: recommendation.exercises.map((exercise, index) => ({
          exerciseId: exercise.id,
          sequenceOrder: index + 1,
          duration: exercise.duration,
          sets: exercise.sets || 1
        }))
      };

      const session = await this.createSession(createSessionDto);

      // 添加推荐相关的元数据
      const sessionWithRecommendation = {
        ...session,
        alternatives: recommendation.alternatives
      };

      return sessionWithRecommendation;

    } catch (error) {
      this.logger.error(`从推荐创建会话失败: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * 根据ID获取训练会话
   * @param id 会话ID
   * @param includeExercises 是否包含动作详情
   * @returns 训练会话
   */
  async findById(id: string, includeExercises: boolean = true) {
    try {
      const session = await this.workoutSessionsDao.findSessionById(id, includeExercises);
      if (!session) {
        throw new NotFoundException(`Workout session not found: ${id}`);
      }
      return session;
    } catch (error) {
      this.logger.error(`获取训练会话失败: id=${id}, error=${error.message}`);
      throw error;
    }
  }

  /**
   * 获取用户的训练会话列表
   * @param userId 用户ID
   * @param query 查询参数
   * @returns 会话列表
   */
  async findUserSessions(userId: string, query: SessionQueryDto) {
    try {
      const filters = {
        status: query.status,
        fromDate: query.fromDate ? new Date(query.fromDate) : undefined,
        toDate: query.toDate ? new Date(query.toDate) : undefined,
        limit: query.limit || 20,
        offset: query.offset || 0
      };

      return await this.workoutSessionsDao.findUserSessions(userId, filters);
    } catch (error) {
      this.logger.error(`获取用户会话列表失败: userId=${userId}, error=${error.message}`);
      throw error;
    }
  }

  /**
   * 更新训练会话
   * @param id 会话ID
   * @param updateDto 更新数据
   * @returns 更新后的会话
   */
  async updateSession(id: string, updateDto: UpdateWorkoutSessionDto) {
    try {
      // 验证会话存在
      await this.findById(id, false);

      // 处理状态变更逻辑
      if (updateDto.status) {
        await this.validateStatusTransition(id, updateDto.status);
      }

      // 自动设置时间戳
      if (updateDto.status === 'IN_PROGRESS' && !updateDto.startedAt) {
        updateDto.startedAt = new Date();
      }

      if (updateDto.status === 'COMPLETED' && !updateDto.completedAt) {
        updateDto.completedAt = new Date();
      }

      const updatedSession = await this.workoutSessionsDao.updateSession(id, updateDto);

      this.logger.log(`训练会话更新成功: sessionId=${id}, status=${updateDto.status}`);
      return updatedSession;

    } catch (error) {
      this.logger.error(`更新训练会话失败: id=${id}, error=${error.message}`);
      throw error;
    }
  }

  /**
   * 完成训练会话
   * @param id 会话ID
   * @param actualDuration 实际时长（秒）
   * @param rating 用户评分（1-5）
   * @param feedback 用户反馈
   * @returns 完成的会话
   */
  async completeSession(id: string, actualDuration?: number, rating?: number, feedback?: string) {
    try {
      const session = await this.findById(id, false);

      if (session.status === SessionStatus.COMPLETED) {
        throw new BadRequestException('Session is already completed');
      }

      const updateData: UpdateWorkoutSessionDto = {
        status: SessionStatus.COMPLETED,
        completedAt: new Date(),
        actualDuration,
        rating,
        feedback
      };

      const completedSession = await this.updateSession(id, updateData);

      // 记录完成事件（用于分析和统计）
      this.logger.log(`训练会话完成: sessionId=${id}, actualDuration=${actualDuration}, rating=${rating}`);

      return completedSession;

    } catch (error) {
      this.logger.error(`完成训练会话失败: id=${id}, error=${error.message}`);
      throw error;
    }
  }

  /**
   * 更新会话中的动作
   * @param sessionId 会话ID
   * @param exerciseId 动作ID
   * @param updateDto 更新数据
   * @returns 更新后的会话动作
   */
  async updateSessionExercise(sessionId: string, exerciseId: string, updateDto: UpdateSessionExerciseDto) {
    try {
      // 验证会话存在
      await this.findById(sessionId, false);

      // 自动设置时间戳
      if (updateDto.isCompleted && !updateDto.endedAt) {
        updateDto.endedAt = new Date();
      }

      const updatedExercise = await this.workoutSessionsDao.updateSessionExercise(
        sessionId,
        exerciseId,
        updateDto
      );

      this.logger.debug(`会话动作更新成功: sessionId=${sessionId}, exerciseId=${exerciseId}`);
      return updatedExercise;

    } catch (error) {
      this.logger.error(`更新会话动作失败: sessionId=${sessionId}, exerciseId=${exerciseId}, error=${error.message}`);
      throw error;
    }
  }

  /**
   * 获取用户训练统计
   * @param userId 用户ID
   * @param query 统计查询参数
   * @returns 统计数据
   */
  async getUserStats(userId: string, query: UserStatsQueryDto = {}) {
    try {
      const days = query.days || 30;
      const stats = await this.workoutSessionsDao.getUserStats(userId, days);

      // 添加额外统计信息
      const todayCompleted = await this.workoutSessionsDao.getTodayCompletedCount();
      const activeCount = await this.workoutSessionsDao.getActiveSessionsCount();

      return {
        ...stats,
        todayCompletedGlobal: todayCompleted,
        activeSessionsGlobal: activeCount,
        periodDays: days
      };

    } catch (error) {
      this.logger.error(`获取用户统计失败: userId=${userId}, error=${error.message}`);
      throw error;
    }
  }

  /**
   * 放弃训练会话
   * @param id 会话ID
   * @param reason 放弃原因
   * @returns 更新后的会话
   */
  async abandonSession(id: string, reason?: string) {
    try {
      const session = await this.findById(id, false);

      if (session.status === SessionStatus.COMPLETED) {
        throw new BadRequestException('Cannot abandon a completed session');
      }

      const updateData: UpdateWorkoutSessionDto = {
        status: SessionStatus.ABANDONED,
        feedback: reason
      };

      const abandonedSession = await this.updateSession(id, updateData);

      this.logger.log(`训练会话已放弃: sessionId=${id}, reason=${reason}`);
      return abandonedSession;

    } catch (error) {
      this.logger.error(`放弃训练会话失败: id=${id}, error=${error.message}`);
      throw error;
    }
  }

  /**
   * 健康检查
   * @returns 服务状态
   */
  async healthCheck() {
    try {
      const activeCount = await this.workoutSessionsDao.getActiveSessionsCount();
      const todayCount = await this.workoutSessionsDao.getTodayCompletedCount();

      return {
        status: 'healthy',
        activeSessionsCount: activeCount,
        todayCompletedCount: todayCount,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      this.logger.error(`健康检查失败: ${error.message}`);
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }

  /**
   * 验证状态转换是否合法
   * @param sessionId 会话ID
   * @param newStatus 新状态
   */
  private async validateStatusTransition(sessionId: string, newStatus: SessionStatus) {
    const session = await this.workoutSessionsDao.findSessionById(sessionId, false);
    const currentStatus = session.status;

    const validTransitions = {
      'PENDING': ['IN_PROGRESS', 'ABANDONED'],
      'IN_PROGRESS': ['COMPLETED', 'ABANDONED'],
      'COMPLETED': [], // 完成状态不可更改
      'ABANDONED': ['PENDING'] // 可以重新激活
    };

    if (!validTransitions[currentStatus]?.includes(newStatus)) {
      throw new BadRequestException(
        `Invalid status transition from ${currentStatus} to ${newStatus}`
      );
    }
  }
}