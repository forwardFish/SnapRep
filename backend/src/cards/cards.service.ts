import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { CardsDao } from './cards.dao';
import { CardGeneratorService } from './services/card-generator.service';
import { RarityCalculatorService } from './services/rarity-calculator.service';
import {
  GenerateCardDto,
  UpdateCardDto,
  CardsQueryDto,
  CalculateRarityDto,
  BatchRarityDto,
  CollectionStatsDto,
  CardShareStatsDto
} from './dto/cards.dto';
import { logger } from '../common/logger/logger';

/**
 * Cards 业务逻辑服务类
 * 处理分享卡片的生成、管理和稀有度计算
 */
@Injectable()
export class CardsService {
  // private readonly logger = new Logger(CardsService.name);

  constructor(
    private readonly cardsDao: CardsDao,
    private readonly cardGeneratorService: CardGeneratorService,
    private readonly rarityCalculatorService: RarityCalculatorService
  ) {}

  /**
   * 生成分享卡片
   * @param generateDto 生成参数
   * @returns 生成的卡片
   */
  async generateCard(generateDto: GenerateCardDto) {
    try {
      logger.debug(`生成分享卡片: sessionId=${generateDto.sessionId}`);

      const card = await this.cardGeneratorService.generateCard(generateDto);

      logger.info(`分享卡片生成成功: cardId=${card.id}, rarity=${card.rarity}`);
      return card;

    } catch (error) {
      logger.error(`生成分享卡片失败: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * 根据ID获取卡片
   * @param id 卡片ID
   * @returns 分享卡片
   */
  async findCardById(id: string) {
    try {
      const card = await this.cardsDao.findCardById(id);
      if (!card) {
        throw new NotFoundException(`Share card not found: ${id}`);
      }

      // 增加查看计数
      await this.cardsDao.incrementViewCount(id);

      return card;
    } catch (error) {
      logger.error(`获取卡片详情失败: id=${id}, error=${error.message}`);
      throw error;
    }
  }

  /**
   * 根据会话ID获取卡片
   * @param sessionId 会话ID
   * @returns 分享卡片或null
   */
  async findCardBySessionId(sessionId: string) {
    try {
      const card = await this.cardsDao.findCardBySessionId(sessionId);
      return card;
    } catch (error) {
      logger.error(`根据会话ID获取卡片失败: sessionId=${sessionId}, error=${error.message}`);
      throw error;
    }
  }

  /**
   * 获取用户的卡片列表
   * @param userId 用户ID
   * @param query 查询参数
   * @returns 卡片列表
   */
  async findUserCards(userId: string, query: CardsQueryDto) {
    try {
      const filters = {
        rarity: query.rarity,
        equipmentSeries: query.equipmentSeries,
        themeWeek: query.themeWeek,
        fromDate: query.fromDate ? new Date(query.fromDate) : undefined,
        toDate: query.toDate ? new Date(query.toDate) : undefined,
        publicOnly: query.publicOnly,
        limit: query.limit || 20,
        offset: query.offset || 0
      };

      return await this.cardsDao.findUserCards(userId, filters);
    } catch (error) {
      logger.error(`获取用户卡片列表失败: userId=${userId}, error=${error.message}`);
      throw error;
    }
  }

  /**
   * 更新分享卡片
   * @param id 卡片ID
   * @param updateDto 更新数据
   * @returns 更新后的卡片
   */
  async updateCard(id: string, updateDto: UpdateCardDto) {
    try {
      // 验证卡片存在
      await this.findCardById(id);

      const updatedCard = await this.cardsDao.updateCard(id, updateDto);

      logger.info(`分享卡片更新成功: cardId=${id}`);
      return updatedCard;

    } catch (error) {
      logger.error(`更新分享卡片失败: id=${id}, error=${error.message}`);
      throw error;
    }
  }

  /**
   * 记录卡片分享
   * @param shareStatsDto 分享统计数据
   * @returns 更新后的卡片
   */
  async recordCardShare(shareStatsDto: CardShareStatsDto) {
    try {
      const card = await this.cardsDao.incrementShareCount(shareStatsDto.cardId, shareStatsDto.platform);

      logger.info(`记录卡片分享: cardId=${shareStatsDto.cardId}, platform=${shareStatsDto.platform}`);
      return card;

    } catch (error) {
      logger.error(`记录卡片分享失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取公开卡片（首页展示）
   * @param limit 数量限制
   * @param offset 偏移量
   * @returns 公开卡片列表
   */
  async findPublicCards(limit: number = 20, offset: number = 0) {
    try {
      return await this.cardsDao.findPublicCards(limit, offset);
    } catch (error) {
      logger.error(`获取公开卡片失败: error=${error.message}`);
      throw error;
    }
  }

  /**
   * 计算器材稀有度
   * @param calculateDto 计算参数
   * @returns 稀有度信息
   */
  async calculateRarity(calculateDto: CalculateRarityDto) {
    try {
      logger.debug(`计算稀有度: equipmentCode=${calculateDto.equipmentCode}`);

      const rarity = await this.rarityCalculatorService.calculateRarity(
        calculateDto.equipmentCode,
        calculateDto.region,
        calculateDto.forceRecalculate
      );

      return rarity;

    } catch (error) {
      logger.error(`计算稀有度失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 批量计算稀有度
   * @param batchDto 批量计算参数
   * @returns 稀有度信息列表
   */
  async calculateBatchRarity(batchDto: BatchRarityDto) {
    try {
      logger.debug(`批量计算稀有度: count=${batchDto.equipmentCodes.length}`);

      const rarities = await this.rarityCalculatorService.calculateBatchRarity(
        batchDto.equipmentCodes,
        batchDto.region
      );

      return rarities;

    } catch (error) {
      logger.error(`批量计算稀有度失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取稀有度排行榜
   * @param limit 返回数量
   * @returns 稀有度排行榜
   */
  async getRarityRanking(limit: number = 10) {
    try {
      return await this.rarityCalculatorService.getCurrentWeekRarityRanking(limit);
    } catch (error) {
      logger.error(`获取稀有度排行榜失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取器材稀有度历史趋势
   * @param equipmentCode 器材代码
   * @param weeks 历史周数
   * @returns 稀有度历史数据
   */
  async getRarityTrend(equipmentCode: string, weeks: number = 8) {
    try {
      return await this.rarityCalculatorService.getRarityTrend(equipmentCode, weeks);
    } catch (error) {
      logger.error(`获取稀有度趋势失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取用户卡片收藏统计
   * @param userId 用户ID
   * @param statsDto 统计参数
   * @returns 统计数据
   */
  async getUserCollectionStats(userId: string, statsDto: CollectionStatsDto) {
    try {
      const stats = await this.cardsDao.getUserCollectionStats(
        userId,
        statsDto.dimension || 'rarity',
        statsDto.days || 365
      );

      // 计算总数
      const totalCards = await this.cardsDao.findUserCards(userId, { limit: 1, offset: 0 });

      return {
        stats,
        totalCards: totalCards.length,
        dimension: statsDto.dimension,
        periodDays: statsDto.days
      };

    } catch (error) {
      logger.error(`获取用户收藏统计失败: userId=${userId}, error=${error.message}`);
      throw error;
    }
  }

  /**
   * 健康检查
   * @returns 服务状态
   */
  async healthCheck() {
    try {
      const publicCardsCount = await this.cardsDao.findPublicCards(1, 0);

      return {
        status: 'healthy',
        publicCardsAvailable: publicCardsCount.length > 0,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      logger.error(`健康检查失败: ${error.message}`);
      return {
        status: 'unhealthy',
        error: error.message,
        timestamp: new Date().toISOString()
      };
    }
  }
}