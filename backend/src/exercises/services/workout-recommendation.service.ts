import { Injectable, Logger } from '@nestjs/common';
import { ExercisesDao } from '../exercises.dao';
import { SupabaseApiService } from '../../common/services/supabase-api.service';
import { QuickRecommendationDto, Difficulty, IntentType, PrimaryMuscle } from '../dto/exercise-recommendation.dto';
import { logger } from '../../common/logger/logger';
import { ResponseError } from '../../exception/response-error';
import { ErrorCodes } from '../../exception/error-codes';


interface ExerciseWithScore {
  exercise: any;
  score: number;
}

interface SelectionConstraints {
  targetMuscles?: PrimaryMuscle[];
  difficulty?: Difficulty;
  duration: number;
  excludeIds?: string[];
}

interface UserPreferences {
  preferredIntents?: IntentType[];
  preferredDifficulty?: Difficulty;
  avoidEquipment?: string[];
  recentlyUsed?: string[];
}

/**
 * 智能动作推荐服务
 * 基于用户偏好、器材可用性、难度递进等因素进行动作选择
 */
@Injectable()
export class WorkoutRecommendationService {
  // private readonly logger = new Logger(WorkoutRecommendationService.name);

  constructor(
    private readonly exercisesDao: ExercisesDao,
    private readonly supabaseApi: SupabaseApiService,
  ) {}

  /**
   * 生成快速推荐
   * @param dto 推荐参数
   * @returns 推荐结果
   */
  async generateQuickRecommendation(dto: QuickRecommendationDto) {
    logger.debug(`生成快速推荐: ${JSON.stringify(dto)}`);

    try {
      // 1. 获取用户偏好
      const userPrefs = await this.getUserPreferences(dto.userId);

      // 处理前端发送的 intents 数组，取第一个作为主要意图
      const primaryIntent = dto.intents?.[0] || dto.intent;

      // 支持 equipmentCodes 和 equipment 两种字段名（向后兼容）
      const equipment = dto.equipmentCodes || dto.equipment || ['none'];

      // 支持 scenarioCode 和 scenario 两种字段名（向后兼容）
      const scenario = dto.scenarioCode || dto.scenario;

      // 2. 直接使用 supabaseApi 筛选可用动作
      const availableExercises = await this.findExercisesBySmartCriteria({
        intent: primaryIntent || undefined,
        equipment: equipment,
        scenario: scenario,
        targetMuscles: dto.targetMuscles,
        difficulty: dto.difficulty,
        excludeIds: dto.excludeExerciseIds,
        limit: 50
      });

      if (availableExercises.length === 0) {
        // 提供详细的错误信息,帮助用户理解为什么没有匹配结果
        const errorDetails = {
          intent: primaryIntent,
          equipment: equipment,
          scenario: scenario,
          targetMuscles: dto.targetMuscles,
          difficulty: dto.difficulty,
        };

        const suggestions = [];
        if (scenario) suggestions.push('尝试选择不同的场景');
        if (equipment && equipment.length > 0 && !equipment.includes('none')) {
          suggestions.push('尝试选择其他器材或选择"无器材"');
        }
        if (dto.targetMuscles && dto.targetMuscles.length > 0) {
          suggestions.push('尝试选择不同的目标部位');
        }
        if (dto.difficulty) {
          suggestions.push('尝试选择不同的难度等级');
        }

        logger.warn(`未找到匹配的训练动作: ${JSON.stringify(errorDetails)}`);

        // ✅ 使用 ResponseError 和 ErrorCodes
        // 注意：第二个参数传递字符串（而不是 new Error），这样详细错误信息会成为 ResponseError 的 message
        throw new ResponseError(
          ErrorCodes.RECOMMENDATION.NO_EXERCISES_FOUND,
          undefined,
          {
            operation: 'generateQuickRecommendation',
            resource: 'exercises',
            ...errorDetails,
            suggestions,
          }
        );
      }

      // 3. 智能选择算法
      const selectedExercises = await this.smartSelection({
        exercises: availableExercises,
        userPrefs,
        constraints: {
          targetMuscles: dto.targetMuscles,
          difficulty: dto.difficulty,
          duration: dto.duration || 60,
          excludeIds: dto.excludeExerciseIds
        }
      });

      // 4. 生成替换候选 (6-9个)
      const alternatives = await this.generateAlternatives({
        exercises: availableExercises,
        selected: selectedExercises,
        count: 9
      });

      // 5. 格式化返回
      return this.formatRecommendationResponse(selectedExercises, alternatives, dto);

    } catch (error) {
      // ✅ 如果是 ResponseError，直接重新抛出，不做任何包装
      if (error instanceof ResponseError) {
        throw error;
      }

      // ✅ 其他未知错误，包装成系统错误
      logger.error(`生成快速推荐失败（未知错误）: ${error.message}`, error.stack);
      throw new ResponseError(
        ErrorCodes.RECOMMENDATION.GENERATION_FAILED,
        error.message || '未知错误',
        {
          operation: 'generateQuickRecommendation',
          originalError: error.name,
          dto
        }
      );
    }
  }

  /**
   * 使用 supabaseApi 智能筛选练习动作
   * 类似于 getPopularExercisesFromDB 的查询方式
   */
  private async findExercisesBySmartCriteria(criteria: {
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
        'NECK_SHOULDER': ['NECK_SHOULDER'],
        'ARMS': ['ARMS'],
        'LEGS': ['LEGS'],
        'CORE': ['CORE'],
        'GLUTES': ['GLUTES'],
        'FULL_BODY': ['FULL_BODY'],
      };

      // 1. 展开复合肌群
      let expandedMuscles: string[] = [];
      if (criteria.targetMuscles && criteria.targetMuscles.length > 0) {
        expandedMuscles = criteria.targetMuscles.flatMap(muscle =>
          compositeMuscleMap[muscle] || [muscle]
        );
        logger.info(`Expanded target muscles: ${criteria.targetMuscles} -> ${expandedMuscles}`);
      }

      // 2. 获取 scenario 关联的 exercise_ids
      let exerciseIdsFromScenario: string[] | null = null;
      if (criteria.scenario) {
        const scenarioRecords = await this.supabaseApi.get('scenarios', {
          code: `eq.${criteria.scenario}`,
          is_active: true,
        });

        if (scenarioRecords.length > 0) {
          const scenarioId = scenarioRecords[0].id;
          const exerciseScenarios = await this.supabaseApi.get('exercise_scenarios', {
            scenario_id: `eq.${scenarioId}`,
          });
          exerciseIdsFromScenario = exerciseScenarios.map((es: any) => es.exercise_id);
          logger.info(`Found ${exerciseIdsFromScenario.length} exercises for scenario: ${criteria.scenario}`);
        } else{
          exerciseIdsFromScenario = [];
        }
      }

      // 3. 获取 equipment 关联的 exercise_ids
      let exerciseIdsFromEquipment: string[] | null = null;
      if (criteria.equipment && criteria.equipment.length > 0) {
        const equipmentRecords = await this.supabaseApi.get('equipment', {
          code: `in.(${criteria.equipment.join(',')})`,
          is_active: true,
        });

        if (equipmentRecords.length > 0) {
          const equipmentIds = equipmentRecords.map((eq: any) => eq.id);
          const exerciseEquipment = await this.supabaseApi.get('exercise_equipment', {
            equipment_id: `in.(${equipmentIds.join(',')})`,
          });
          exerciseIdsFromEquipment = exerciseEquipment.map((ee: any) => ee.exercise_id);
          logger.info(`Found ${exerciseIdsFromEquipment.length} exercises for equipment: ${criteria.equipment.join(',')}`);
        }
      }

      // 4. 合并 scenario 和 equipment 的 exercise_ids (取交集或并集)
      let finalExerciseIds: string[] | null = null;
      if (exerciseIdsFromScenario && exerciseIdsFromEquipment) {
        finalExerciseIds = exerciseIdsFromScenario.filter(id =>
          exerciseIdsFromEquipment!.includes(id)
        );
        logger.info(`Intersection: ${finalExerciseIds.length} exercises`);

        // 如果交集为空,放宽为并集
        if (finalExerciseIds.length === 0 && exerciseIdsFromEquipment) {
          logger.warn('No intersection, using equipment only');
          finalExerciseIds = exerciseIdsFromEquipment;
        }
      } else if (exerciseIdsFromScenario) {
        finalExerciseIds = exerciseIdsFromScenario;
      } else if (exerciseIdsFromEquipment) {
        finalExerciseIds = exerciseIdsFromEquipment;
      }

      // 5. 构建 supabaseApi 查询 filters
      const filters: Record<string, any> = {
        is_active: 'eq.true',
      };

      if (finalExerciseIds && finalExerciseIds.length > 0) {
        filters.id = `in.(${finalExerciseIds.join(',')})`;
      } else if (finalExerciseIds && finalExerciseIds.length === 0) {
        logger.warn('No exercises match scenario+equipment');
        return [];
      }

      if (criteria.intent) {
        filters.intent_type = `eq.${criteria.intent}`;
      }

      if (criteria.difficulty) {
        filters.difficulty = `eq.${criteria.difficulty}`;
      }

      if (expandedMuscles.length > 0) {
        filters.primary_muscle = `in.(${expandedMuscles.join(',')})`;
      }

      // 6. 使用 supabaseApi.get() 查询 exercises 表
      let exercises = await this.supabaseApi.get(
        'exercises',
        filters,
        {
          orderBy: 'created_at.desc',
          limit: criteria.limit || 50,
        }
      );

      logger.info(`Found ${exercises.length} exercises from supabaseApi`);

      // 7. 后处理: secondary_muscles 过滤
      if (expandedMuscles.length > 0 && exercises.length > 0) {
        exercises = exercises.filter((ex: any) => {
          const primaryMatch = expandedMuscles.includes(ex.primary_muscle);
          const secondaryMatch = ex.secondary_muscles && Array.isArray(ex.secondary_muscles) &&
            ex.secondary_muscles.some((sm: string) => expandedMuscles.includes(sm));
          return primaryMatch || secondaryMatch;
        });
        logger.info(`After secondary_muscles filtering: ${exercises.length} exercises`);
      }

      // 8. 如果仍然没有结果,放宽条件(去掉intent和difficulty)
      if (exercises.length === 0 && (criteria.intent || criteria.difficulty)) {
        logger.warn('Relaxing constraints (removing intent/difficulty)');

        const relaxedFilters: Record<string, any> = {
          is_active: 'eq.true',
        };

        if (finalExerciseIds && finalExerciseIds.length > 0) {
          relaxedFilters.id = `in.(${finalExerciseIds.join(',')})`;
        }

        if (expandedMuscles.length > 0) {
          relaxedFilters.primary_muscle = `in.(${expandedMuscles.join(',')})`;
        }

        exercises = await this.supabaseApi.get(
          'exercises',
          relaxedFilters,
          {
            orderBy: 'created_at.desc',
            limit: criteria.limit || 50,
          }
        );

        logger.info(`After relaxed query: ${exercises.length} exercises`);
      }

      // 9. 转换数据格式 (统一 camelCase)
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
      }));

    } catch (error) {
      logger.error(`智能筛选失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 智能选择核心算法
   * @param params 选择参数
   * @returns 选中的动作列表
   */
  private async smartSelection(params: {
    exercises: any[];
    userPrefs: UserPreferences;
    constraints: SelectionConstraints;
  }): Promise<any[]> {
    const { exercises, userPrefs, constraints } = params;

    // 评分系统
    const scoredExercises = exercises.map(exercise => ({
      exercise,
      score: this.calculateScore(exercise, userPrefs, constraints)
    }));

    // 排序
    scoredExercises.sort((a, b) => b.score - a.score);

    // 贪心算法选择3个动作
    const selected: any[] = [];
    const targetCount = 3;

    for (const item of scoredExercises) {
      if (selected.length >= targetCount) break;

      // 检查是否满足约束
      if (this.meetsConstraints(item.exercise, selected, constraints)) {
        selected.push(item.exercise);
      }
    }

    // 如果选择不足3个，从剩余的动作中补充
    if (selected.length < targetCount) {
      for (const item of scoredExercises) {
        if (selected.length >= targetCount) break;

        const isAlreadySelected = selected.some(s => s.id === item.exercise.id);
        if (!isAlreadySelected) {
          selected.push(item.exercise);
        }
      }
    }

    return selected.slice(0, targetCount);
  }

  /**
   * 计算动作得分
   * @param exercise 动作
   * @param userPrefs 用户偏好
   * @param constraints 约束条件
   * @returns 得分 (0-100)
   */
  private calculateScore(exercise: any, userPrefs: UserPreferences, constraints: SelectionConstraints): number {
    let score = 50; // 基础分

    // 意图偏好匹配 (+20分)
    if (userPrefs.preferredIntents?.includes(exercise.intentType)) {
      score += 20;
    }

    // 难度偏好匹配 (+15分)
    if (userPrefs.preferredDifficulty === exercise.difficulty) {
      score += 15;
    }

    // 目标肌群匹配 (+25分)
    if (constraints.targetMuscles && constraints.targetMuscles.length > 0) {
      const muscleMatch = constraints.targetMuscles.includes(exercise.primaryMuscle) ||
        exercise.secondaryMuscles?.some((muscle: string) => constraints.targetMuscles!.includes(muscle as PrimaryMuscle));

      if (muscleMatch) {
        score += 25;
      }
    }

    // 避免最近使用的动作 (-30分)
    if (userPrefs.recentlyUsed?.includes(exercise.id)) {
      score -= 30;
    }

    // 避免用户不喜欢的器材 (-20分)
    const exerciseEquipment = exercise.exerciseEquipment?.map((ee: any) => ee.equipment.code) || [];
    const hasAvoidedEquipment = exerciseEquipment.some((code: string) =>
      userPrefs.avoidEquipment?.includes(code)
    );
    if (hasAvoidedEquipment) {
      score -= 20;
    }

    // 动作受欢迎程度 (基于标签) (+10分)
    const popularTags = ['silent', 'small_space', 'office_friendly'];
    const hasPopularTags = exercise.tags?.some((tag: string) => popularTags.includes(tag));
    if (hasPopularTags) {
      score += 10;
    }

    return Math.max(0, Math.min(100, score));
  }

  /**
   * 检查动作是否满足约束条件
   * @param exercise 动作
   * @param selected 已选动作
   * @param constraints 约束条件
   * @returns 是否满足约束
   */
  private meetsConstraints(exercise: any, selected: any[], constraints: SelectionConstraints): boolean {
    // 避免重复选择相同的动作
    if (selected.some(s => s.id === exercise.id)) {
      return false;
    }

    // 避免相同主要肌群的动作过多 (最多2个)
    const sameMuscleCount = selected.filter(s => s.primaryMuscle === exercise.primaryMuscle).length;
    if (sameMuscleCount >= 2) {
      return false;
    }

    // 难度递进检查 (避免全是高难度)
    if (exercise.difficulty === 'RED') {
      const hardCount = selected.filter(s => s.difficulty === 'RED').length;
      if (hardCount >= 1) {
        return false;
      }
    }

    // 时长平衡检查
    const totalDuration = selected.reduce((sum, s) => sum + (s.defaultDuration || 20), 0);
    const exerciseDuration = exercise.defaultDuration || 20;

    if (totalDuration + exerciseDuration > constraints.duration * 1.2) {
      return false;
    }

    return true;
  }

  /**
   * 生成替换候选
   * @param params 生成参数
   * @returns 候选动作列表
   */
  private async generateAlternatives(params: {
    exercises: any[];
    selected: any[];
    count: number;
  }): Promise<any[]> {
    const { exercises, selected, count } = params;

    const selectedIds = new Set(selected.map(s => s.id));
    const alternatives = exercises
      .filter(ex => !selectedIds.has(ex.id))
      .slice(0, count);

    return alternatives;
  }

  /**
   * 获取用户偏好
   * @param userId 用户ID
   * @returns 用户偏好
   */
  private async getUserPreferences(userId?: string): Promise<UserPreferences> {
    if (!userId) {
      return {}; // 返回默认偏好
    }

    try {
      // 获取用户最近使用的动作
      const recentlyUsed = await this.exercisesDao.findRecentlyUsedByUser(userId, 7);

      // TODO: 从数据库获取用户偏好设置
      // const userSettings = await this.prisma.user.findUnique({
      //   where: { id: userId },
      //   select: { preferredIntents: true, preferredDifficulty: true, avoidEquipment: true }
      // });

      return {
        recentlyUsed,
        // ...userSettings
      };
    } catch (error) {
      logger.warn(`获取用户偏好失败: userId=${userId}, error=${error.message}`);
      return {}; // 返回默认偏好
    }
  }

  /**
   * 格式化推荐响应
   * @param exercises 选中的动作
   * @param alternatives 替换候选
   * @param dto 原始请求
   * @returns 格式化的响应
   */
  private formatRecommendationResponse(exercises: any[], alternatives: any[], dto: QuickRecommendationDto) {
    // 处理前端发送的 intents 数组，取第一个作为主要意图
    const primaryIntent = dto.intents?.[0] || dto.intent;

    return {
      intent: primaryIntent || 'STRETCH',
      totalDuration: dto.duration || 60,
      difficulty: dto.difficulty || 'GREEN',
      exercises: exercises.map((exercise, index) => ({
        id: exercise.id,
        code: exercise.code,
        name: exercise.name,
        duration: exercise.defaultDuration,
        sets: exercise.defaultSets,
        restSeconds: 0,
        difficulty: exercise.difficulty,
        primaryMuscle: exercise.primaryMuscle,
        secondaryMuscles: exercise.secondaryMuscles,
        intentType: exercise.intentType,

        // 安全指导
        keyPoints: exercise.description?.keyPoints || [],
        safetyWarnings: exercise.description?.warnings || [],

        // 媒体资源
        demoImageUrl: exercise.demoImageUrl,
        demoVideoUrl: exercise.demoVideoUrl,
        thumbnailUrl: exercise.demoImageUrl, // 暂时使用相同图片

        // 标签和效果
        tags: exercise.tags || [],
        equipment: exercise.exerciseEquipment?.map((ee: any) => ee.equipment.code) || [],
        benefits: this.generateBenefitsText(exercise),

        // 详细指导
        instructions: {
          setup: exercise.description?.steps?.[0] || '',
          execution: exercise.description?.steps?.slice(1)?.join(', ') || '',
          breathing: 'Breathe naturally throughout the movement',
          commonMistakes: exercise.description?.warnings || []
        }
      })),

      // 替换候选
      alternatives: alternatives.map(alt => ({
        id: alt.id,
        code: alt.code,
        name: alt.name,
        thumbnailUrl: alt.demoImageUrl,
        difficulty: alt.difficulty,
        primaryMuscle: alt.primaryMuscle,
        tags: alt.tags || [],
        benefits: this.generateBenefitsText(alt)
      })),

      // 元数据
      metadata: {
        createdAt: new Date().toISOString(),
        recommendationVersion: 'v1.0',
        algorithm: 'smart_selection_v1'
      }
    };
  }

  /**
   * 生成效果描述文本
   * @param exercise 动作
   * @returns 效果描述
   */
  private generateBenefitsText(exercise: any): string {
    const muscleMap: Record<string, string> = {
      'CHEST': 'chest muscles',
      'BACK': 'back muscles',
      'LEGS': 'leg muscles',
      'GLUTES': 'glute muscles',
      'SHOULDERS': 'shoulders',
      'ARMS': 'arms',
      'CORE': 'core stability',
      'FULL_BODY': 'full body',
      'NECK_SHOULDER': 'neck and shoulders'
    };

    const intentMap: Record<string, string> = {
      'RELAX': 'Relieves tension in',
      'STRETCH': 'Improves flexibility of',
      'MODERATE': 'Strengthens',
      'STRENGTH': 'Builds strength in'
    };

    const prefix = intentMap[exercise.intentType] || 'Targets';
    const target = muscleMap[exercise.primaryMuscle] || 'target muscles';

    return `${prefix} ${target}`;
  }
}