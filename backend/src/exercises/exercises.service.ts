import { Injectable, Logger } from '@nestjs/common';
import { ExercisesDao } from './exercises.dao';
import { WorkoutRecommendationService } from './services/workout-recommendation.service';
import { ExerciseMatchingService } from './services/exercise-matching.service';

/**
 * Exercises 服务类
 * 提供练习动作相关的业务逻辑
 */
@Injectable()
export class ExercisesService {
  private readonly logger = new Logger(ExercisesService.name);

  constructor(
    private readonly exercisesDao: ExercisesDao,
    private readonly workoutRecommendationService: WorkoutRecommendationService,
    private readonly exerciseMatchingService: ExerciseMatchingService,
  ) {}

  /**
   * 根据ID获取练习动作
   * @param id 动作ID
   * @returns 动作详情
   */
  async findById(id: string) {
    this.logger.debug(`查找动作: id=${id}`);
    return await this.exercisesDao.findById(id);
  }

  /**
   * 根据代码获取练习动作
   * @param code 动作代码
   * @returns 动作详情
   */
  async findByCode(code: string) {
    this.logger.debug(`查找动作: code=${code}`);
    return await this.exercisesDao.findByCode(code);
  }

  /**
   * 智能筛选练习动作
   * @param criteria 筛选条件
   * @returns 匹配的动作列表
   */
  async findBySmartCriteria(criteria: any) {
    this.logger.debug(`智能筛选动作: ${JSON.stringify(criteria)}`);
    return await this.exercisesDao.findBySmartCriteria(criteria);
  }

  /**
   * 获取动作统计信息
   * @returns 统计数据
   */
  async getStats() {
    this.logger.debug('获取动作统计信息');
    return await this.exercisesDao.getExerciseStats();
  }

  /**
   * 分页获取练习动作
   * @param page 页码
   * @param pageSize 每页大小
   * @param filters 筛选条件
   * @returns 分页动作列表
   */
  async findWithPagination(
    page: number = 1,
    pageSize: number = 10,
    filters?: {
      intent?: string;
      difficulty?: string;
      primaryMuscle?: string;
      isActive?: boolean;
    }
  ) {
    this.logger.debug(`分页获取动作: page=${page}, pageSize=${pageSize}, filters=${JSON.stringify(filters)}`);

    const where: any = {};

    if (filters) {
      if (filters.intent) {
        where.intentType = filters.intent;
      }
      if (filters.difficulty) {
        where.difficulty = filters.difficulty;
      }
      if (filters.primaryMuscle) {
        where.primaryMuscle = filters.primaryMuscle;
      }
      if (typeof filters.isActive === 'boolean') {
        where.isActive = filters.isActive;
      }
    }

    return await this.exercisesDao.findByPage(
      page,
      pageSize,
      where,
      {
        exerciseEquipment: {
          include: { equipment: true }
        },
        exerciseScenarios: {
          include: { scenario: true }
        }
      },
      undefined,
      { updatedAt: 'desc' }
    );
  }

  /**
   * 获取推荐动作（快速入口）
   * @param dto 推荐参数
   * @returns 推荐结果
   */
  async getQuickRecommendation(dto: any) {
    this.logger.debug(`获取快速推荐: ${JSON.stringify(dto)}`);
    return await this.workoutRecommendationService.generateQuickRecommendation(dto);
  }

  /**
   * 替换动作
   * @param dto 替换参数
   * @returns 替换结果
   */
  async replaceExercise(dto: any) {
    this.logger.debug(`替换动作: ${JSON.stringify(dto)}`);
    return await this.exerciseMatchingService.replaceExercise(dto);
  }

  /**
   * 获取替换候选
   * @param dto 查询参数
   * @returns 候选列表
   */
  async getAlternatives(dto: any) {
    this.logger.debug(`获取替换候选: ${JSON.stringify(dto)}`);
    return await this.exerciseMatchingService.getAlternatives(dto);
  }

  /**
   * 健康检查
   * @returns 服务状态
   */
  async healthCheck() {
    try {
      const stats = await this.exercisesDao.getExerciseStats();
      return {
        status: 'healthy',
        exerciseCount: stats.active,
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
}