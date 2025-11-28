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
   * 智能筛选练习动作 - 增强版
   * 支持复合肌群匹配、场景关联查询、分级放宽策略
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
      logger.info(`智能筛选动作: ${JSON.stringify(criteria)}`);

      // 复合肌群映射表
      const compositeMuscleMap: Record<string, string[]> = {
        'CHEST_BACK': ['CHEST', 'BACK'],
        'NECK_SHOULDER': ['NECK_SHOULDER'], // 单一部位
        'ARMS': ['ARMS'],
        'LEGS': ['LEGS'],
        'CORE': ['CORE'],
        'GLUTES': ['GLUTES'],
        'FULL_BODY': ['FULL_BODY'],
      };

      // 1. 处理复合肌群 - 展开为单一肌群
      let expandedMuscles: string[] = [];
      if (criteria.targetMuscles && criteria.targetMuscles.length > 0) {
        expandedMuscles = criteria.targetMuscles.flatMap(muscle =>
          compositeMuscleMap[muscle] || [muscle]
        );
        logger.info(`Expanded target muscles: ${criteria.targetMuscles} -> ${expandedMuscles}`);
      }

      // 2. 如果指定了scenario，先通过 exercise_scenarios 表查找符合条件的 exercise_ids
      let exerciseIdsFromScenario: string[] | null = null;
      if (criteria.scenario) {
        // 查询 scenarios 表获取 scenario_id
        const scenarioRecords = await this.supabaseApi.get('scenarios', {
          code: `eq.${criteria.scenario}`,
          is_active: true,
        });

        if (scenarioRecords.length > 0) {
          const scenarioId = scenarioRecords[0].id;

          // 查询 exercise_scenarios 表获取关联的 exercise_ids
          const exerciseScenarios = await this.supabaseApi.get('exercise_scenarios', {
            scenario_id: `eq.${scenarioId}`,
          });

          exerciseIdsFromScenario = exerciseScenarios.map((es: any) => es.exercise_id);
          logger.info(`Found ${exerciseIdsFromScenario.length} exercises matching scenario: ${criteria.scenario}`);
        } else {
          logger.warn(`No scenario found with code: ${criteria.scenario}`);
        }
      }

      // 3. 如果指定了equipment，先通过 exercise_equipment 表查找符合条件的 exercise_ids
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
        } else {
          logger.warn(`No equipment found with codes: ${criteria.equipment.join(',')}`);
        }
      }

      // 4. 合并 scenario 和 equipment 的 exercise_ids (取交集)
      let finalExerciseIds: string[] | null = null;
      if (exerciseIdsFromScenario && exerciseIdsFromEquipment) {
        // 取交集
        finalExerciseIds = exerciseIdsFromScenario.filter(id =>
          exerciseIdsFromEquipment!.includes(id)
        );
        logger.info(`Intersection of scenario and equipment: ${finalExerciseIds.length} exercises`);
      } else if (exerciseIdsFromScenario) {
        finalExerciseIds = exerciseIdsFromScenario;
      } else if (exerciseIdsFromEquipment) {
        finalExerciseIds = exerciseIdsFromEquipment;
      }

      // 如果交集为空,尝试放宽条件 (先去掉scenario约束)
      if (finalExerciseIds && finalExerciseIds.length === 0 && exerciseIdsFromEquipment) {
        logger.warn('No intersection found, relaxing scenario constraint');
        finalExerciseIds = exerciseIdsFromEquipment;
      }

      const filters: Record<string, any> = {
        is_active: true,
      };

      // 5. 如果有exercise_ids筛选结果，添加到filters
      if (finalExerciseIds && finalExerciseIds.length > 0) {
        filters.id = `in.(${finalExerciseIds.join(',')})`;
      } else if (finalExerciseIds && finalExerciseIds.length === 0) {
        // 如果明确知道没有匹配的exercise_ids,直接返回空
        logger.warn('No exercises match scenario+equipment criteria');
        return [];
      }

      // 6. 意图筛选 - NOTE: 改为数组后，需要在后处理中过滤
      // 因为需要匹配: 数组包含该intent OR 数组为空[]
      // Supabase PostgREST 不支持直接的 OR 查询，所以我们在后处理中过滤
      const intentFilter = criteria.intent; // 保存用于后处理

      // 7. 难度筛选
      if (criteria.difficulty) {
        filters.difficulty = `eq.${criteria.difficulty}`;
      }

      // 8. 目标肌群筛选 - 支持复合肌群和secondary_muscles
      if (expandedMuscles.length > 0) {
        // 查询 primary_muscle 或 secondary_muscles 包含目标肌群
        filters.primary_muscle = `in.(${expandedMuscles.join(',')})`;
        // Note: Supabase PostgREST doesn't support OR queries directly
        // We'll filter secondary_muscles in post-processing
      }

      // 9. 排除特定IDs
      if (criteria.excludeIds && criteria.excludeIds.length > 0) {
        // Supabase使用 not.in 语法
        if (filters.id) {
          // 需要单独处理,不能直接追加
          const currentIds = filters.id.match(/in\.\((.*?)\)/)?.[1]?.split(',') || [];
          const filteredIds = currentIds.filter(id => !criteria.excludeIds!.includes(id));
          filters.id = `in.(${filteredIds.join(',')})`;
        } else {
          filters.id = `not.in.(${criteria.excludeIds.join(',')})`;
        }
      }

      // 10. 获取基础练习数据
      let exercises = await this.supabaseApi.get('exercises', filters, {
        limit: criteria.limit || 50,
        orderBy: 'created_at.desc',
      });

      logger.info(`Found ${exercises.length} exercises from Supabase after all filters`);

      // 11. 后处理: 意图筛选（intent_type 改为数组后）
      // 匹配规则: 数组包含该intent OR 数组为空[]（表示适用于所有意图）
      if (intentFilter && exercises.length > 0) {
        exercises = exercises.filter((ex: any) => {
          const intentTypes = ex.intent_type;
          // 如果是空数组，表示适用于所有意图
          if (!intentTypes || intentTypes.length === 0) {
            return true;
          }
          // 检查数组是否包含该意图
          return Array.isArray(intentTypes) && intentTypes.includes(intentFilter);
        });
        logger.info(`After intent_type filtering (${intentFilter}): ${exercises.length} exercises`);
      }

      // 12. 后处理: 如果有目标肌群要求,进一步筛选 secondary_muscles
      if (expandedMuscles.length > 0 && exercises.length > 0) {
        exercises = exercises.filter((ex: any) => {
          // 检查 primary_muscle 或 secondary_muscles 是否匹配
          const primaryMatch = expandedMuscles.includes(ex.primary_muscle);
          const secondaryMatch = ex.secondary_muscles && Array.isArray(ex.secondary_muscles) &&
            ex.secondary_muscles.some((sm: string) => expandedMuscles.includes(sm));
          return primaryMatch || secondaryMatch;
        });
        logger.info(`After secondary_muscles filtering: ${exercises.length} exercises`);
      }

      // 12. 如果仍然没有结果,尝试最后的放宽策略(去掉intent和difficulty约束)
      if (exercises.length === 0 && (criteria.intent || criteria.difficulty)) {
        logger.warn('No results with all constraints, trying without intent/difficulty filters');

        const relaxedFilters: Record<string, any> = {
          is_active: true,
        };

        if (finalExerciseIds && finalExerciseIds.length > 0) {
          relaxedFilters.id = `in.(${finalExerciseIds.join(',')})`;
        }

        if (expandedMuscles.length > 0) {
          relaxedFilters.primary_muscle = `in.(${expandedMuscles.join(',')})`;
        }

        if (criteria.excludeIds && criteria.excludeIds.length > 0) {
          if (relaxedFilters.id) {
            const currentIds = relaxedFilters.id.match(/in\.\((.*?)\)/)?.[1]?.split(',') || [];
            const filteredIds = currentIds.filter(id => !criteria.excludeIds!.includes(id));
            relaxedFilters.id = `in.(${filteredIds.join(',')})`;
          } else {
            relaxedFilters.id = `not.in.(${criteria.excludeIds.join(',')})`;
          }
        }

        exercises = await this.supabaseApi.get('exercises', relaxedFilters, {
          limit: criteria.limit || 50,
          orderBy: 'created_at.desc',
        });

        logger.info(`After relaxed query: ${exercises.length} exercises found`);
      }

      // 13. 转换数据格式（将 snake_case 转换为 camelCase）
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
   * 按意图分组获取动作（intent_type改为数组后，需要特殊处理）
   * 注意：一个动作可能属于多个意图，所以会重复计数
   */
  private async getExercisesByIntent(): Promise<Record<string, number>> {
    try {
      // 改为数组后不能直接使用 groupBy，需要手动统计
      const exercises = await this.prisma.exercise.findMany({
        where: { isActive: true },
        select: { intentType: true }
      });

      const intentCounts: Record<string, number> = {};

      exercises.forEach((exercise) => {
        const intentTypes = exercise.intentType as unknown as any[];
        if (intentTypes && Array.isArray(intentTypes) && intentTypes.length > 0) {
          // 每个意图都计数一次（一个动作可能属于多个意图）
          intentTypes.forEach((intent: string) => {
            intentCounts[intent] = (intentCounts[intent] || 0) + 1;
          });
        } else {
          // 空数组表示适用于所有意图，在每个意图下都计数
          ['RELAX', 'STRETCH', 'MODERATE', 'STRENGTH'].forEach((intent) => {
            intentCounts[intent] = (intentCounts[intent] || 0) + 1;
          });
        }
      });

      return intentCounts;
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