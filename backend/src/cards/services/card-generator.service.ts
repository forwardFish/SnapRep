import { Injectable, Logger } from '@nestjs/common';
import { CardsDao } from '../cards.dao';
import { RarityCalculatorService } from './rarity-calculator.service';
import { WorkoutSessionsService } from '../../workout-sessions/workout-sessions.service';
import { GenerateCardDto } from '../dto/cards.dto';
import { RarityLevel } from '../../common/types/prisma-enums';
import { logger } from '../../common/logger/logger';

/**
 * 卡片生成服务
 * 处理分享卡片的生成逻辑和模板渲染
 */
@Injectable()
export class CardGeneratorService {
  // private readonly logger = new Logger(CardGeneratorService.name);

  constructor(
    private readonly cardsDao: CardsDao,
    private readonly rarityCalculatorService: RarityCalculatorService,
    private readonly workoutSessionsService: WorkoutSessionsService
  ) {}

  /**
   * 生成分享卡片
   * @param generateDto 生成参数
   * @returns 生成的卡片
   */
  async generateCard(generateDto: GenerateCardDto) {
    try {
      logger.debug(`开始生成分享卡片: sessionId=${generateDto.sessionId}`);

      // 检查是否已存在卡片
      if (!generateDto.forceRegenerate) {
        const existingCard = await this.cardsDao.findCardBySessionId(generateDto.sessionId);
        if (existingCard) {
          logger.debug(`使用现有卡片: cardId=${existingCard.id}`);
          return existingCard;
        }
      }

      // 获取训练会话信息
      const session = await this.workoutSessionsService.findById(generateDto.sessionId, true);
      if (!session || session.status !== 'COMPLETED') {
        throw new Error('Session not found or not completed');
      }

      // 分析会话使用的器材
      const equipmentAnalysis = await this.analyzeSessionEquipment(session);

      // 计算稀有度
      const rarityInfo = await this.calculateCardRarity(equipmentAnalysis);

      // 生成卡片数据
      const cardData = await this.buildCardData(session, generateDto, rarityInfo, equipmentAnalysis);

      // 生成卡片图片
      const cardImageUrl = await this.generateCardImage(cardData, generateDto.cardTemplate || 'classic');

      // 保存卡片记录
      const cardRecord = {
        userId: session.userId,
        sessionId: generateDto.sessionId,
        cardImageUrl,
        cardTemplate: generateDto.cardTemplate || 'classic',
        cardData,
        rarity: rarityInfo.level,
        equipmentSeries: equipmentAnalysis.primaryEquipment,
        rarityScore: rarityInfo.score,
        dataSource: rarityInfo.dataSource || 'WEEKLY_TABLE',
        specialTags: generateDto.specialTags || [],
        cityEdition: generateDto.cityEdition,
        themeWeek: generateDto.themeWeek,
        shareText: generateDto.shareText,
        isPublic: generateDto.isPublic !== false
      };

      const card = await this.cardsDao.createCard(cardRecord);

      logger.info(`分享卡片生成成功: cardId=${card.id}, rarity=${rarityInfo.level}, score=${rarityInfo.score}`);
      return card;

    } catch (error) {
      logger.error(`生成分享卡片失败: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * 分析会话使用的器材
   * @param session 训练会话
   * @returns 器材分析结果
   */
  private async analyzeSessionEquipment(session: any) {
    try {
      const equipmentCounts = new Map<string, { count: number; name: string; category: string }>();

      // 统计每种器材的使用次数
      for (const sessionExercise of session.sessionExercises) {
        const exercise = sessionExercise.exercise;
        if (exercise.exerciseEquipment && exercise.exerciseEquipment.length > 0) {
          for (const equipment of exercise.exerciseEquipment) {
            const code = equipment.equipment.code;
            const current = equipmentCounts.get(code) || { count: 0, name: equipment.equipment.name, category: equipment.equipment.category };
            current.count += 1;
            equipmentCounts.set(code, current);
          }
        }
      }

      // 找出主要使用的器材
      let primaryEquipment = 'none';
      let maxCount = 0;
      const equipmentList: string[] = [];

      for (const [code, info] of equipmentCounts) {
        equipmentList.push(code);
        if (info.count > maxCount) {
          maxCount = info.count;
          primaryEquipment = code;
        }
      }

      // 如果没有器材，使用徒手
      if (equipmentList.length === 0) {
        equipmentList.push('none');
        primaryEquipment = 'none';
      }

      logger.debug(`器材分析完成: primary=${primaryEquipment}, all=[${equipmentList.join(', ')}]`);

      return {
        primaryEquipment,
        equipmentList,
        equipmentCounts: Object.fromEntries(equipmentCounts),
        equipmentDiversity: equipmentList.length
      };

    } catch (error) {
      logger.error(`器材分析失败: ${error.message}`);
      return {
        primaryEquipment: 'none',
        equipmentList: ['none'],
        equipmentCounts: {},
        equipmentDiversity: 1
      };
    }
  }

  /**
   * 计算卡片稀有度
   * @param equipmentAnalysis 器材分析结果
   * @returns 稀有度信息
   */
  private async calculateCardRarity(equipmentAnalysis: any) {
    try {
      // 计算主要器材的稀有度
      const primaryRarity = await this.rarityCalculatorService.calculateRarity(
        equipmentAnalysis.primaryEquipment
      );

      // 如果使用了多种器材，适当提升稀有度
      let adjustedScore = primaryRarity.rarityScore;
      if (equipmentAnalysis.equipmentDiversity > 1) {
        // 多器材组合提升稀有度
        const diversityBonus = Math.min(0.1, (equipmentAnalysis.equipmentDiversity - 1) * 0.02);
        adjustedScore = Math.min(1.0, adjustedScore + diversityBonus);
      }

      // 重新确定稀有度等级
      const adjustedLevel = this.determineRarityLevel(adjustedScore);

      logger.debug(`稀有度计算: ${equipmentAnalysis.primaryEquipment}, original=${primaryRarity.rarityScore}, adjusted=${adjustedScore}, level=${adjustedLevel}`);

      return {
        level: adjustedLevel,
        score: adjustedScore,
        originalLevel: primaryRarity.rarityLevel,
        originalScore: primaryRarity.rarityScore,
        dataSource: primaryRarity.dataSource,
        diversityBonus: equipmentAnalysis.equipmentDiversity > 1
      };

    } catch (error) {
      logger.error(`稀有度计算失败: ${error.message}`);
      // 返回默认稀有度
      return {
        level: 'COMMON' as RarityLevel,
        score: 0.3,
        originalLevel: 'COMMON' as RarityLevel,
        originalScore: 0.3,
        dataSource: 'ON_THE_FLY_ESTIMATE',
        diversityBonus: false
      };
    }
  }

  /**
   * 构建卡片数据
   * @param session 训练会话
   * @param generateDto 生成参数
   * @param rarityInfo 稀有度信息
   * @param equipmentAnalysis 器材分析
   * @returns 卡片数据
   */
  private async buildCardData(session: any, generateDto: GenerateCardDto, rarityInfo: any, equipmentAnalysis: any) {
    try {
      // 计算训练强度
      const intensity = this.calculateIntensity(session);

      // 获取肌群分布
      const muscleDistribution = this.analyzeMuscleDistribution(session);

      // 构建卡片数据
      const cardData = {
        // 基本训练信息
        workoutDate: session.completedAt,
        duration: session.actualDuration || session.totalDuration,
        exerciseCount: session.sessionExercises.length,
        intentType: session.intentType,
        difficulty: session.difficulty,

        // 器材信息
        primaryEquipment: equipmentAnalysis.primaryEquipment,
        equipmentList: equipmentAnalysis.equipmentList,
        equipmentDiversity: equipmentAnalysis.equipmentDiversity,

        // 稀有度信息
        rarity: rarityInfo.level,
        rarityScore: rarityInfo.score,
        diversityBonus: rarityInfo.diversityBonus,

        // 训练分析
        intensity,
        muscleDistribution,

        // 特殊标记
        achievements: this.generateAchievements(session, rarityInfo, equipmentAnalysis),

        // 场景信息
        scenario: session.scenario ? {
          name: session.scenario.name,
          code: session.scenario.code,
          iconUrl: session.scenario.iconUrl
        } : null,

        // 主题周信息
        themeWeek: generateDto.themeWeek,
        cityEdition: generateDto.cityEdition,

        // 生成时间戳
        generatedAt: new Date().toISOString(),
        template: generateDto.cardTemplate || 'classic'
      };

      return cardData;

    } catch (error) {
      logger.error(`构建卡片数据失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 生成卡片图片
   * @param cardData 卡片数据
   * @param template 模板名称
   * @returns 卡片图片URL
   */
  private async generateCardImage(cardData: any, template: string): Promise<string> {
    try {
      // TODO: 实现实际的图片生成逻辑
      // 这里可以集成图片生成服务，如Canvas API、Puppeteer、或第三方服务

      // 目前返回模拟的图片URL
      const timestamp = Date.now();
      const filename = `card_${cardData.generatedAt.replace(/[^0-9]/g, '')}_${timestamp}.jpg`;
      const cardImageUrl = `/generated/cards/${template}/${filename}`;

      logger.debug(`卡片图片生成: ${cardImageUrl}`);

      // TODO: 实际的图片生成逻辑
      // await this.renderCardTemplate(cardData, template, cardImageUrl);

      return cardImageUrl;

    } catch (error) {
      logger.error(`卡片图片生成失败: ${error.message}`);
      // 返回默认卡片图片
      return `/generated/cards/default/placeholder.jpg`;
    }
  }

  /**
   * 计算训练强度
   * @param session 训练会话
   * @returns 强度分析
   */
  private calculateIntensity(session: any) {
    try {
      const exercises = session.sessionExercises;
      let totalIntensity = 0;
      let difficultyPoints = 0;

      for (const exercise of exercises) {
        // 根据难度计算强度点数
        switch (exercise.exercise.difficulty) {
          case 'GREEN': difficultyPoints += 1; break;
          case 'BLUE': difficultyPoints += 2; break;
          case 'RED': difficultyPoints += 3; break;
        }

        // 根据时长计算强度
        const duration = exercise.actualDuration || exercise.duration;
        totalIntensity += duration * difficultyPoints;
      }

      const averageIntensity = totalIntensity / exercises.length;

      // 确定强度等级
      let intensityLevel = 'LOW';
      if (averageIntensity > 200) intensityLevel = 'HIGH';
      else if (averageIntensity > 100) intensityLevel = 'MEDIUM';

      return {
        level: intensityLevel,
        score: Math.round(averageIntensity),
        totalPoints: difficultyPoints,
        avgDuration: Math.round(session.actualDuration / exercises.length)
      };

    } catch (error) {
      logger.error(`强度计算失败: ${error.message}`);
      return { level: 'MEDIUM', score: 100, totalPoints: 2, avgDuration: 60 };
    }
  }

  /**
   * 分析肌群分布
   * @param session 训练会话
   * @returns 肌群分布
   */
  private analyzeMuscleDistribution(session: any) {
    try {
      const muscleCount = new Map<string, number>();

      for (const exercise of session.sessionExercises) {
        const primaryMuscle = exercise.exercise.primaryMuscle;
        muscleCount.set(primaryMuscle, (muscleCount.get(primaryMuscle) || 0) + 1);
      }

      const distribution = Object.fromEntries(muscleCount);
      const primaryMuscle = [...muscleCount.entries()].reduce((a, b) => muscleCount.get(a[0]) > muscleCount.get(b[0]) ? a : b)[0];

      return {
        primary: primaryMuscle,
        distribution,
        diversity: muscleCount.size,
        isBalanced: muscleCount.size >= 2
      };

    } catch (error) {
      logger.error(`肌群分析失败: ${error.message}`);
      return { primary: 'FULL_BODY', distribution: {}, diversity: 1, isBalanced: false };
    }
  }

  /**
   * 生成成就标记
   * @param session 训练会话
   * @param rarityInfo 稀有度信息
   * @param equipmentAnalysis 器材分析
   * @returns 成就列表
   */
  private generateAchievements(session: any, rarityInfo: any, equipmentAnalysis: any): string[] {
    const achievements: string[] = [];

    // 稀有度成就
    if (rarityInfo.level === 'LEGENDARY') achievements.push('legendary_equipment');
    else if (rarityInfo.level === 'EPIC') achievements.push('epic_equipment');
    else if (rarityInfo.level === 'RARE') achievements.push('rare_equipment');

    // 多器材成就
    if (equipmentAnalysis.equipmentDiversity >= 3) achievements.push('equipment_master');
    else if (equipmentAnalysis.equipmentDiversity >= 2) achievements.push('multi_equipment');

    // 时长成就
    const duration = session.actualDuration || session.totalDuration;
    if (duration >= 600) achievements.push('endurance_warrior');
    else if (duration >= 300) achievements.push('steady_trainer');

    // 动作数量成就
    if (session.sessionExercises.length >= 5) achievements.push('exercise_explorer');

    // 完美完成成就
    const completedCount = session.sessionExercises.filter(ex => ex.isCompleted).length;
    if (completedCount === session.sessionExercises.length) achievements.push('perfect_completion');

    return achievements;
  }

  /**
   * 根据分数确定稀有度等级
   * @param score 稀有度分数
   * @returns 稀有度等级
   */
  private determineRarityLevel(score: number): RarityLevel {
    if (score >= 0.95) return RarityLevel.LEGENDARY;
    if (score >= 0.80) return RarityLevel.EPIC;
    if (score >= 0.50) return RarityLevel.RARE;
    if (score >= 0.20) return RarityLevel.UNCOMMON;
    return RarityLevel.COMMON;
  }
}