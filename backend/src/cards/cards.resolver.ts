import { Resolver, Query, Mutation, Args, Int } from '@nestjs/graphql';
import { UseGuards, Logger } from '@nestjs/common';
import { CardsService } from './cards.service';
import { GqlAuthGuard } from '../auth/gql-auth.guard';
import {
  GenerateCardDto,
  UpdateCardDto,
  CardsQueryDto,
  CollectionStatsDto
} from './dto/cards.dto';

/**
 * Cards GraphQL 解析器
 * 提供分享卡片管理和稀有度查询的 GraphQL 接口
 */
@Resolver('ShareCard')
@UseGuards(GqlAuthGuard)
export class CardsResolver {
  private readonly logger = new Logger(CardsResolver.name);

  constructor(private readonly cardsService: CardsService) {}

  /**
   * 生成分享卡片
   */
  @Mutation('generateShareCard')
  async generateShareCard(@Args('input') generateDto: GenerateCardDto) {
    this.logger.debug(`GraphQL生成分享卡片: sessionId=${generateDto.sessionId}`);

    try {
      const card = await this.cardsService.generateCard(generateDto);
      return card;
    } catch (error) {
      this.logger.error(`GraphQL生成分享卡片失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取卡片详情
   */
  @Query('shareCard')
  async getShareCard(@Args('id') id: string) {
    this.logger.debug(`GraphQL获取卡片详情: cardId=${id}`);

    try {
      return await this.cardsService.findCardById(id);
    } catch (error) {
      this.logger.error(`GraphQL获取卡片详情失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 根据会话ID获取卡片
   */
  @Query('shareCardBySession')
  async getShareCardBySession(@Args('sessionId') sessionId: string) {
    this.logger.debug(`GraphQL根据会话ID获取卡片: sessionId=${sessionId}`);

    try {
      return await this.cardsService.findCardBySessionId(sessionId);
    } catch (error) {
      this.logger.error(`GraphQL根据会话ID获取卡片失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取用户的卡片列表
   */
  @Query('userShareCards')
  async getUserShareCards(
    @Args('userId') userId: string,
    @Args('rarity', { nullable: true }) rarity?: string,
    @Args('equipmentSeries', { nullable: true }) equipmentSeries?: string,
    @Args('themeWeek', { nullable: true }) themeWeek?: string,
    @Args('fromDate', { nullable: true }) fromDate?: string,
    @Args('toDate', { nullable: true }) toDate?: string,
    @Args('publicOnly', { nullable: true }) publicOnly?: boolean,
    @Args('limit', { type: () => Int, defaultValue: 20 }) limit: number = 20,
    @Args('offset', { type: () => Int, defaultValue: 0 }) offset: number = 0
  ) {
    this.logger.debug(`GraphQL获取用户卡片列表: userId=${userId}`);

    try {
      const query: CardsQueryDto = {
        rarity: rarity as any,
        equipmentSeries,
        themeWeek,
        fromDate,
        toDate,
        publicOnly,
        limit,
        offset
      };

      return await this.cardsService.findUserCards(userId, query);
    } catch (error) {
      this.logger.error(`GraphQL获取用户卡片列表失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取公开卡片
   */
  @Query('publicShareCards')
  async getPublicShareCards(
    @Args('limit', { type: () => Int, defaultValue: 20 }) limit: number = 20,
    @Args('offset', { type: () => Int, defaultValue: 0 }) offset: number = 0
  ) {
    this.logger.debug(`GraphQL获取公开卡片: limit=${limit}, offset=${offset}`);

    try {
      return await this.cardsService.findPublicCards(limit, offset);
    } catch (error) {
      this.logger.error(`GraphQL获取公开卡片失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 更新卡片
   */
  @Mutation('updateShareCard')
  async updateShareCard(
    @Args('id') id: string,
    @Args('input') updateDto: UpdateCardDto
  ) {
    this.logger.debug(`GraphQL更新卡片: cardId=${id}`);

    try {
      const card = await this.cardsService.updateCard(id, updateDto);
      return card;
    } catch (error) {
      this.logger.error(`GraphQL更新卡片失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 记录卡片分享
   */
  @Mutation('recordCardShare')
  async recordCardShare(
    @Args('id') id: string,
    @Args('platform', { nullable: true }) platform?: string,
    @Args('source', { nullable: true }) source?: string
  ) {
    this.logger.debug(`GraphQL记录卡片分享: cardId=${id}, platform=${platform}`);

    try {
      const shareStatsDto = {
        cardId: id,
        platform,
        source
      };

      const card = await this.cardsService.recordCardShare(shareStatsDto);
      return card;
    } catch (error) {
      this.logger.error(`GraphQL记录卡片分享失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 计算器材稀有度
   */
  @Query('equipmentRarity')
  async getEquipmentRarity(
    @Args('code') code: string,
    @Args('region', { nullable: true }) region?: string,
    @Args('forceRecalculate', { nullable: true }) forceRecalculate?: boolean
  ) {
    this.logger.debug(`GraphQL计算稀有度: equipmentCode=${code}`);

    try {
      const calculateDto = {
        equipmentCode: code,
        region,
        forceRecalculate: forceRecalculate === true
      };

      return await this.cardsService.calculateRarity(calculateDto);
    } catch (error) {
      this.logger.error(`GraphQL计算稀有度失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 批量计算稀有度
   */
  @Query('batchEquipmentRarity')
  async getBatchEquipmentRarity(
    @Args('codes', { type: () => [String] }) codes: string[],
    @Args('region', { nullable: true }) region?: string
  ) {
    this.logger.debug(`GraphQL批量计算稀有度: count=${codes.length}`);

    try {
      const batchDto = {
        equipmentCodes: codes,
        region
      };

      return await this.cardsService.calculateBatchRarity(batchDto);
    } catch (error) {
      this.logger.error(`GraphQL批量计算稀有度失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取稀有度排行榜
   */
  @Query('rarityRanking')
  async getRarityRanking(
    @Args('limit', { type: () => Int, defaultValue: 10 }) limit: number = 10
  ) {
    this.logger.debug(`GraphQL获取稀有度排行榜: limit=${limit}`);

    try {
      return await this.cardsService.getRarityRanking(limit);
    } catch (error) {
      this.logger.error(`GraphQL获取稀有度排行榜失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取稀有度历史趋势
   */
  @Query('rarityTrend')
  async getRarityTrend(
    @Args('code') code: string,
    @Args('weeks', { type: () => Int, defaultValue: 8 }) weeks: number = 8
  ) {
    this.logger.debug(`GraphQL获取稀有度趋势: equipmentCode=${code}, weeks=${weeks}`);

    try {
      return await this.cardsService.getRarityTrend(code, weeks);
    } catch (error) {
      this.logger.error(`GraphQL获取稀有度趋势失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取用户卡片收藏统计
   */
  @Query('userCardCollectionStats')
  async getUserCardCollectionStats(
    @Args('userId') userId: string,
    @Args('dimension', { defaultValue: 'rarity' }) dimension: string = 'rarity',
    @Args('days', { type: () => Int, defaultValue: 365 }) days: number = 365
  ) {
    this.logger.debug(`GraphQL获取用户收藏统计: userId=${userId}, dimension=${dimension}`);

    try {
      const statsDto: CollectionStatsDto = {
        dimension,
        days
      };

      return await this.cardsService.getUserCollectionStats(userId, statsDto);
    } catch (error) {
      this.logger.error(`GraphQL获取用户收藏统计失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 服务健康检查
   */
  @Query('cardsHealth')
  async healthCheck() {
    this.logger.debug('GraphQL卡片服务健康检查');

    try {
      return await this.cardsService.healthCheck();
    } catch (error) {
      this.logger.error(`GraphQL健康检查失败: ${error.message}`);
      throw error;
    }
  }
}