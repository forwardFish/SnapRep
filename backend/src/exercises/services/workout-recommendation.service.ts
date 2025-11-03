import { Injectable, Logger } from '@nestjs/common';
import { ExercisesDao } from '../exercises.dao';
import { QuickRecommendationDto, Difficulty, IntentType, PrimaryMuscle } from '../dto/exercise-recommendation.dto';

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
  private readonly logger = new Logger(WorkoutRecommendationService.name);

  constructor(private readonly exercisesDao: ExercisesDao) {}

  /**
   * 生成快速推荐
   * @param dto 推荐参数
   * @returns 推荐结果
   */
  async generateQuickRecommendation(dto: QuickRecommendationDto) {
    this.logger.debug(`生成快速推荐: ${JSON.stringify(dto)}`);

    try {
      // 1. 获取用户偏好
      const userPrefs = await this.getUserPreferences(dto.userId);

      // 2. 筛选可用动作
      const availableExercises = await this.exercisesDao.findBySmartCriteria({
        intent: dto.intent || undefined,
        equipment: dto.equipment || ['none'],
        scenario: dto.scenario,
        targetMuscles: dto.targetMuscles,
        difficulty: dto.difficulty,
        excludeIds: dto.excludeExerciseIds,
        limit: 50 // 获取更多候选以便智能选择
      });

      if (availableExercises.length === 0) {
        throw new Error('No exercises found matching the criteria');
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
      this.logger.error(`生成快速推荐失败: ${error.message}`, error.stack);
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
      this.logger.warn(`获取用户偏好失败: userId=${userId}, error=${error.message}`);
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
    return {
      intent: dto.intent || 'STRETCH',
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