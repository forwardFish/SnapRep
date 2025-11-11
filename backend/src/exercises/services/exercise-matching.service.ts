import { Injectable, Logger } from '@nestjs/common';
import { ExercisesDao } from '../exercises.dao';
import { ReplaceExerciseDto, AlternativesQueryDto } from '../dto/exercise-recommendation.dto';
import { logger } from '../../common/logger/logger';

/**
 * 动作匹配服务
 * 负责动作替换和候选推荐
 */
@Injectable()
export class ExerciseMatchingService {
  // private readonly logger = new Logger(ExerciseMatchingService.name);

  constructor(private readonly exercisesDao: ExercisesDao) {}

  /**
   * 替换单个动作
   * @param dto 替换参数
   * @returns 替换结果
   */
  async replaceExercise(dto: ReplaceExerciseDto) {
    logger.debug(`替换动作: ${JSON.stringify(dto)}`);

    try {
      // 1. 获取当前动作信息
      const currentExercise = await this.exercisesDao.findById(dto.currentExerciseId);
      if (!currentExercise) {
        throw new Error(`Exercise not found: ${dto.currentExerciseId}`);
      }

      // 2. 构建筛选条件
      const searchCriteria = this.buildReplacementCriteria(currentExercise, dto.filters);

      // 3. 查找替换候选
      const candidates = await this.exercisesDao.findBySmartCriteria(searchCriteria);

      if (candidates.length === 0) {
        throw new Error('No replacement exercises found');
      }

      // 4. 选择最佳替换
      const bestReplacement = this.selectBestReplacement(currentExercise, candidates, dto.filters);

      return {
        success: true,
        newExercise: this.formatExerciseResponse(bestReplacement),
        message: 'Exercise replaced successfully'
      };

    } catch (error) {
      logger.error(`替换动作失败: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * 获取替换候选列表
   * @param dto 查询参数
   * @returns 候选列表
   */
  async getAlternatives(dto: AlternativesQueryDto) {
    logger.debug(`获取替换候选: ${JSON.stringify(dto)}`);

    try {
      // 构建筛选条件
      const searchCriteria = {
        equipment: dto.equipment,
        targetMuscles: dto.targetMuscle ? [dto.targetMuscle] : undefined,
        limit: dto.limit || 10
      };

      // 查找候选
      const alternatives = await this.exercisesDao.findBySmartCriteria(searchCriteria);

      return {
        alternatives: alternatives.map(alt => this.formatAlternativeResponse(alt)),
        filterSummary: {
          equipment: dto.equipment,
          targetMuscle: dto.targetMuscle,
          intensity: dto.intensity
        }
      };

    } catch (error) {
      logger.error(`获取替换候选失败: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * 构建替换筛选条件
   * @param currentExercise 当前动作
   * @param filters 筛选器
   * @returns 筛选条件
   */
  private buildReplacementCriteria(currentExercise: any, filters?: any) {
    const criteria: any = {
      excludeIds: [currentExercise.id],
      limit: 20
    };

    // 保持相同意图类型
    criteria.intent = currentExercise.intentType;

    // 保持相同目标肌群（如果没有指定其他）
    if (!filters?.targetMuscle) {
      criteria.targetMuscles = [currentExercise.primaryMuscle];
    } else {
      criteria.targetMuscles = [filters.targetMuscle];
    }

    // 器材筛选
    if (filters?.equipment) {
      criteria.equipment = filters.equipment;
    } else {
      // 保持相同器材
      const currentEquipment = currentExercise.exerciseEquipment?.map((ee: any) => ee.equipment.code) || [];
      criteria.equipment = currentEquipment;
    }

    // 难度调整
    if (filters?.intensity) {
      criteria.difficulty = this.adjustDifficulty(currentExercise.difficulty, filters.intensity);
    }

    return criteria;
  }

  /**
   * 调整难度等级
   * @param currentDifficulty 当前难度
   * @param intensity 强度调整
   * @returns 新难度
   */
  private adjustDifficulty(currentDifficulty: string, intensity: string): string {
    const difficultyOrder = ['GREEN', 'BLUE', 'RED'];
    const currentIndex = difficultyOrder.indexOf(currentDifficulty);

    switch (intensity) {
      case 'lighter':
        return currentIndex > 0 ? difficultyOrder[currentIndex - 1] : currentDifficulty;
      case 'harder':
        return currentIndex < 2 ? difficultyOrder[currentIndex + 1] : currentDifficulty;
      default:
        return currentDifficulty;
    }
  }

  /**
   * 选择最佳替换动作
   * @param currentExercise 当前动作
   * @param candidates 候选动作
   * @param filters 筛选器
   * @returns 最佳替换
   */
  private selectBestReplacement(currentExercise: any, candidates: any[], filters?: any): any {
    // 按相似度打分
    const scoredCandidates = candidates.map(candidate => ({
      exercise: candidate,
      score: this.calculateSimilarityScore(currentExercise, candidate, filters)
    }));

    // 选择得分最高的
    scoredCandidates.sort((a, b) => b.score - a.score);

    return scoredCandidates[0]?.exercise || candidates[0];
  }

  /**
   * 计算相似度得分
   * @param current 当前动作
   * @param candidate 候选动作
   * @param filters 筛选器
   * @returns 相似度得分
   */
  private calculateSimilarityScore(current: any, candidate: any, filters?: any): number {
    let score = 0;

    // 相同主要肌群 (+30分)
    if (current.primaryMuscle === candidate.primaryMuscle) {
      score += 30;
    }

    // 相同意图类型 (+25分)
    if (current.intentType === candidate.intentType) {
      score += 25;
    }

    // 相似时长 (+20分)
    const durationDiff = Math.abs((current.defaultDuration || 20) - (candidate.defaultDuration || 20));
    if (durationDiff <= 10) {
      score += 20;
    }

    // 标签匹配 (+15分)
    const currentTags = new Set(current.tags || []);
    const candidateTags = new Set(candidate.tags || []);
    const commonTags = [...currentTags].filter(tag => candidateTags.has(tag));
    score += Math.min(15, commonTags.length * 5);

    // 难度匹配（考虑强度调整）
    if (filters?.intensity) {
      const targetDifficulty = this.adjustDifficulty(current.difficulty, filters.intensity);
      if (candidate.difficulty === targetDifficulty) {
        score += 20;
      }
    } else {
      if (current.difficulty === candidate.difficulty) {
        score += 10;
      }
    }

    return score;
  }

  /**
   * 格式化动作响应
   * @param exercise 动作数据
   * @returns 格式化响应
   */
  private formatExerciseResponse(exercise: any) {
    return {
      id: exercise.id,
      code: exercise.code,
      name: exercise.name,
      duration: exercise.defaultDuration,
      sets: exercise.defaultSets,
      difficulty: exercise.difficulty,
      primaryMuscle: exercise.primaryMuscle,
      secondaryMuscles: exercise.secondaryMuscles,
      intentType: exercise.intentType,
      keyPoints: exercise.description?.keyPoints || [],
      safetyWarnings: exercise.description?.warnings || [],
      demoImageUrl: exercise.demoImageUrl,
      tags: exercise.tags || [],
      equipment: exercise.exerciseEquipment?.map((ee: any) => ee.equipment.code) || [],
      benefits: this.generateBenefitsText(exercise),
      instructions: {
        setup: exercise.description?.steps?.[0] || '',
        execution: exercise.description?.steps?.slice(1)?.join(', ') || '',
        breathing: 'Breathe naturally throughout the movement',
        commonMistakes: exercise.description?.warnings || []
      }
    };
  }

  /**
   * 格式化候选动作响应
   * @param exercise 动作数据
   * @returns 格式化候选响应
   */
  private formatAlternativeResponse(exercise: any) {
    return {
      id: exercise.id,
      code: exercise.code,
      name: exercise.name,
      thumbnailUrl: exercise.demoImageUrl,
      difficulty: exercise.difficulty,
      primaryMuscle: exercise.primaryMuscle,
      equipment: exercise.exerciseEquipment?.map((ee: any) => ee.equipment.code) || [],
      tags: exercise.tags || [],
      benefits: this.generateBenefitsText(exercise),
      duration: exercise.defaultDuration,
      sets: exercise.defaultSets
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