import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import { PrismaBaseDao } from '../common/dao/prisma-base.dao';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { logger } from '../common/logger/logger';

/**
 * Exercise DAO 类
 * 使用 Prisma ORM 进行数据库操作
 */
@Injectable()
export class ExercisesDao extends PrismaBaseDao<any> {
  // private readonly logger = new Logger(ExercisesDao.name);

  constructor(
    prisma: PrismaService,
    private readonly supabaseApi: SupabaseApiService, // 注入SupabaseApiService
  ) {
    super(prisma);
    logger.info('ExercisesDao initialized with Prisma and SupabaseApiService');
  }

  protected getDelegate() {
    return this.prisma.exercise;
  }

  /**
   * 根据ID查找练习动作
   * @param id 动作ID
   * @param includeInactive 是否包含非活跃动作
   * @returns 动作实体或null
   */
  async findById(id: string, includeInactive: boolean = false): Promise<any | null> {
    try {
      logger.info('Using SupabaseApiService for findById due to database connection issue');

      const exercise = await this.supabaseApi.getById('exercises', id);

      if (!exercise) {
        return null;
      }

      // 检查是否活跃
      if (!includeInactive && !exercise.is_active) {
        return null;
      }

      // 转换数据格式（将 snake_case 转换为 camelCase）
      return {
        id: exercise.id,
        code: exercise.code,
        name: exercise.name,
        description: exercise.description,
        primaryMuscle: exercise.primary_muscle,
        secondaryMuscles: exercise.secondary_muscles || [],
        intentType: exercise.intent_type,
        difficulty: exercise.difficulty,
        defaultDuration: exercise.default_duration || 60,
        defaultSets: exercise.default_sets || 1,
        durationType: exercise.duration_type || 'SECONDS',
        demoImageUrl: exercise.demo_image_url,
        demoVideoUrl: exercise.demo_video_url,
        tags: exercise.tags || [],
        isActive: exercise.is_active,
        createdAt: exercise.created_at,
        updatedAt: exercise.updated_at,
        // 为了兼容现有代码，添加空的关联数组
        exerciseEquipment: [],
        exerciseScenarios: [],
      };
    } catch (error) {
      logger.error(`根据ID查找动作失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EXERCISE.FETCH_FAILED, error, { exerciseId: id });
    }
  }

  /**
   * 根据代码查找练习动作
   * @param code 动作代码
   * @param includeInactive 是否包含非活跃动作
   * @returns 动作实体或null
   */
  async findByCode(code: string, includeInactive: boolean = false): Promise<any | null> {
    try {
      logger.info('Using SupabaseApiService for findByCode due to database connection issue');

      const exercise = await this.supabaseApi.getByField('exercises', 'code', code);

      if (!exercise) {
        return null;
      }

      // 检查是否活跃
      if (!includeInactive && !exercise.is_active) {
        return null;
      }

      // 转换数据格式（将 snake_case 转换为 camelCase）
      return {
        id: exercise.id,
        code: exercise.code,
        name: exercise.name,
        description: exercise.description,
        primaryMuscle: exercise.primary_muscle,
        secondaryMuscles: exercise.secondary_muscles || [],
        intentType: exercise.intent_type,
        difficulty: exercise.difficulty,
        defaultDuration: exercise.default_duration || 60,
        defaultSets: exercise.default_sets || 1,
        durationType: exercise.duration_type || 'SECONDS',
        demoImageUrl: exercise.demo_image_url,
        demoVideoUrl: exercise.demo_video_url,
        tags: exercise.tags || [],
        isActive: exercise.is_active,
        createdAt: exercise.created_at,
        updatedAt: exercise.updated_at,
        // 为了兼容现有代码，添加空的关联数组
        exerciseEquipment: [],
        exerciseScenarios: [],
      };
    } catch (error) {
      logger.error(`根据代码查找动作失败: code=${code}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EXERCISE.FETCH_FAILED, error, { exerciseCode: code });
    }
  }

  /**
   * 智能筛选练习动作
   * @param criteria 筛选条件
   * @returns 匹配的动作列表
   */
  async findBySmartCriteria(criteria: {
    intent?: string;
    equipment?: string[];
    scenario?: string;
    targetMuscles?: string[];
    difficulty?: string;
    excludeIds?: string[];
    limit?: number;
  }): Promise<any[]> {
    try {
      logger.info('Using SupabaseApiService due to database connection issue');

      // 1. 如果指定了equipment，先通过 exercise_equipment 表查找符合条件的 exercise_ids
      let exerciseIdsFromEquipment: string[] | null = null;
      if (criteria.equipment && criteria.equipment.length > 0) {
        // 查询 equipment 表获取 equipment_ids
        const equipmentRecords = await this.supabaseApi.get('equipment', {
          code: `in.(${criteria.equipment.join(',')})`,
          is_active: true,
        });

        if (equipmentRecords.length > 0) {
          const equipmentIds = equipmentRecords.map((eq: any) => eq.id);

          // 查询 exercise_equipment 表获取关联的 exercise_ids
          const exerciseEquipment = await this.supabaseApi.get('exercise_equipment', {
            equipment_id: `in.(${equipmentIds.join(',')})`,
          });

          exerciseIdsFromEquipment = exerciseEquipment.map((ee: any) => ee.exercise_id);
          logger.info(`Found ${exerciseIdsFromEquipment.length} exercises matching equipment: ${criteria.equipment.join(',')}`);

          // 如果没有找到匹配的exercises，直接返回空数组
          if (exerciseIdsFromEquipment.length === 0) {
            logger.warn(`No exercises found for equipment: ${criteria.equipment.join(',')}`);
            return [];
          }
        } else {
          logger.warn(`No equipment found with codes: ${criteria.equipment.join(',')}`);
          return [];
        }
      }

      const filters: Record<string, any> = {
        is_active: true,
      };

      // 2. 如果有equipment筛选结果，添加到filters
      if (exerciseIdsFromEquipment && exerciseIdsFromEquipment.length > 0) {
        filters.id = `in.(${exerciseIdsFromEquipment.join(',')})`;
      }

      // 3. 意图筛选
      if (criteria.intent) {
        filters.intent_type = criteria.intent;
      }

      // 4. 难度筛选
      if (criteria.difficulty) {
        filters.difficulty = criteria.difficulty;
      }

      // 5. 目标肌群筛选 - 简化版，只查primary muscle
      if (criteria.targetMuscles && criteria.targetMuscles.length > 0) {
        filters.primary_muscle = `in.(${criteria.targetMuscles.join(',')})`;
      }

      // 6. 排除特定IDs
      if (criteria.excludeIds && criteria.excludeIds.length > 0) {
        // Supabase使用 not.in 语法
        filters.id = filters.id
          ? `${filters.id},not.in.(${criteria.excludeIds.join(',')})`
          : `not.in.(${criteria.excludeIds.join(',')})`;
      }

      // 7. 获取基础练习数据
      const exercises = await this.supabaseApi.get('exercises', filters, {
        limit: criteria.limit || 50,
        orderBy: 'created_at.desc',
      });

      logger.info(`Found ${exercises.length} exercises from Supabase after all filters`);

      // 8. 转换数据格式（将 snake_case 转换为 camelCase）
      return exercises.map((exercise: any) => ({
        id: exercise.id,
        code: exercise.code,
        name: exercise.name,
        description: exercise.description,
        primaryMuscle: exercise.primary_muscle,
        secondaryMuscles: exercise.secondary_muscles || [],
        intentType: exercise.intent_type,
        difficulty: exercise.difficulty,
        defaultDuration: exercise.default_duration || 60,
        defaultSets: exercise.default_sets || 1,
        durationType: exercise.duration_type || 'SECONDS',
        demoImageUrl: exercise.demo_image_url,
        demoVideoUrl: exercise.demo_video_url,
        tags: exercise.tags || [],
        isActive: exercise.is_active,
        createdAt: exercise.created_at,
        updatedAt: exercise.updated_at,
        // 为了兼容现有代码，添加空的关联数组
        exerciseEquipment: [],
        exerciseScenarios: [],
      }));
    } catch (error) {
      logger.error(`智能筛选动作失败: criteria=${JSON.stringify(criteria)}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EXERCISE.FETCH_FAILED, error, { criteria });
    }
  }

  /**
   * 获取用户最近训练的动作ID
   * @param userId 用户ID
   * @param days 查看最近几天
   * @returns 最近训练的动作ID列表
   */
  async findRecentlyUsedByUser(userId: string, days: number = 7): Promise<string[]> {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - days);

      const recentSessions = await this.prisma.workoutSession.findMany({
        where: {
          userId,
          completedAt: { gte: cutoffDate },
          status: 'COMPLETED'
        },
        include: {
          sessionExercises: {
            select: { exerciseId: true }
          }
        }
      });

      const exerciseIds = new Set<string>();
      recentSessions.forEach(session => {
        session.sessionExercises.forEach(se => {
          exerciseIds.add(se.exerciseId);
        });
      });

      return Array.from(exerciseIds);
    } catch (error) {
      logger.error(`获取用户最近训练动作失败: userId=${userId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EXERCISE.FETCH_FAILED, error, { userId });
    }
  }

  /**
   * 获取动作统计信息
   * @returns 动作统计
   */
  async getExerciseStats(): Promise<any> {
    try {
      const [total, active, byDifficulty, byIntent] = await Promise.all([
        this.count(),
        this.count({ isActive: true }),
        this.getExercisesByDifficulty(),
        this.getExercisesByIntent()
      ]);

      return {
        total,
        active,
        inactive: total - active,
        byDifficulty,
        byIntent
      };
    } catch (error) {
      logger.error(`获取动作统计失败: error=${error.message}`);
      throw new ResponseError(ErrorCodes.EXERCISE.FETCH_FAILED, error);
    }
  }

  /**
   * 按难度分组获取动作
   */
  private async getExercisesByDifficulty(): Promise<Record<string, number>> {
    try {
      const result = await this.prisma.exercise.groupBy({
        by: ['difficulty'],
        where: { isActive: true },
        _count: { id: true }
      });

      return result.reduce((acc, item) => {
        acc[item.difficulty] = item._count.id;
        return acc;
      }, {} as Record<string, number>);
    } catch (error) {
      logger.error(`按难度分组获取动作失败: error=${error.message}`);
      throw error;
    }
  }

  /**
   * 按意图分组获取动作
   */
  private async getExercisesByIntent(): Promise<Record<string, number>> {
    try {
      const result = await this.prisma.exercise.groupBy({
        by: ['intentType'],
        where: { isActive: true },
        _count: { id: true }
      });

      return result.reduce((acc, item) => {
        acc[item.intentType] = item._count.id;
        return acc;
      }, {} as Record<string, number>);
    } catch (error) {
      logger.error(`按意图分组获取动作失败: error=${error.message}`);
      throw error;
    }
  }

  /**
   * 检查动作代码是否存在
   * @param code 动作代码
   * @param excludeId 排除的动作ID
   * @returns 是否存在
   */
  async isCodeExists(code: string, excludeId?: string): Promise<boolean> {
    try {
      const where: any = { code };
      if (excludeId) {
        where.NOT = { id: excludeId };
      }

      return await this.exists(where);
    } catch (error) {
      logger.error(`检查动作代码是否存在失败: code=${code}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EXERCISE.FETCH_FAILED, error, { exerciseCode: code });
    }
  }
}