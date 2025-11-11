import {
  Controller,
  Post,
  Get,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
  HttpStatus,
  Logger,
  ValidationPipe,
  ParseUUIDPipe
} from '@nestjs/common';
import {
  ApiTags,
  ApiOperation,
  ApiResponse,
  ApiParam,
  ApiBearerAuth,
  ApiBody
} from '@nestjs/swagger';
import { CardsService } from './cards.service';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
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
 * Cards REST API 控制器
 * 提供分享卡片管理和稀有度计算的 REST 接口
 */
@ApiTags('Cards & Rarity')
@Controller('api/v1')
@UseGuards(JwtAuthGuard)
@ApiBearerAuth('JWT-auth')
export class CardsController {

  constructor(private readonly cardsService: CardsService) {}

  /**
   * 生成分享卡片
   * POST /api/v1/cards/generate
   */
  @Post('cards/generate')
  @ApiOperation({
    summary: '生成分享卡片',
    description: '根据训练会话生成精美的分享卡片，包含稀有度计算和成就标记'
  })
  @ApiBody({ type: GenerateCardDto })
  @ApiResponse({
    status: HttpStatus.CREATED,
    description: '分享卡片生成成功',
    schema: {
      type: 'object',
      properties: {
        id: { type: 'string', example: 'cuid_card_123' },
        cardImageUrl: { type: 'string', example: '/generated/cards/classic/card_20240101_123456.jpg' },
        rarity: { type: 'string', enum: ['COMMON', 'UNCOMMON', 'RARE', 'EPIC', 'LEGENDARY'] },
        rarityScore: { type: 'number', example: 0.85 },
        equipmentSeries: { type: 'string', example: 'chair' },
        cardData: { type: 'object' },
        createdAt: { type: 'string', format: 'date-time' }
      }
    }
  })
  @ApiResponse({
    status: HttpStatus.BAD_REQUEST,
    description: '训练会话未完成或不存在'
  })
  async generateCard(@Body(ValidationPipe) generateDto: GenerateCardDto) {
    logger.debug(`生成分享卡片请求: sessionId=${generateDto.sessionId}`);

    try {
      const card = await this.cardsService.generateCard(generateDto);

      return {
        success: true,
        data: card,
        message: 'Share card generated successfully'
      };
    } catch (error) {
      logger.error(`生成分享卡片失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取卡片详情
   * GET /api/v1/cards/:id
   */
  @Get('cards/:id')
  @ApiOperation({
    summary: '获取卡片详情',
    description: '根据卡片ID获取完整的分享卡片信息'
  })
  @ApiParam({
    name: 'id',
    description: '卡片ID',
    example: 'cuid_card_123'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '卡片详情获取成功'
  })
  @ApiResponse({
    status: HttpStatus.NOT_FOUND,
    description: '卡片不存在'
  })
  async getCard(@Param('id') id: string) {
    logger.debug(`获取卡片详情: cardId=${id}`);

    try {
      const card = await this.cardsService.findCardById(id);

      return {
        success: true,
        data: card
      };
    } catch (error) {
      logger.error(`获取卡片详情失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 根据会话ID获取卡片
   * GET /api/v1/cards/session/:sessionId
   */
  @Get('cards/session/:sessionId')
  @ApiOperation({
    summary: '根据会话ID获取卡片',
    description: '根据训练会话ID获取对应的分享卡片'
  })
  @ApiParam({
    name: 'sessionId',
    description: '训练会话ID',
    example: 'cuid_session_123'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '卡片获取成功'
  })
  async getCardBySession(@Param('sessionId') sessionId: string) {
    logger.debug(`根据会话ID获取卡片: sessionId=${sessionId}`);

    try {
      const card = await this.cardsService.findCardBySessionId(sessionId);

      return {
        success: true,
        data: card
      };
    } catch (error) {
      logger.error(`根据会话ID获取卡片失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取用户的卡片列表
   * GET /api/v1/users/:userId/cards
   */
  @Get('users/:userId/cards')
  @ApiOperation({
    summary: '获取用户卡片列表',
    description: '获取用户的分享卡片收藏，支持按稀有度、器材系列等筛选'
  })
  @ApiParam({
    name: 'userId',
    description: '用户ID',
    example: 'user-uuid-123'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '用户卡片列表获取成功'
  })
  async getUserCards(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query(ValidationPipe) query: CardsQueryDto
  ) {
    logger.debug(`获取用户卡片列表: userId=${userId}`);

    try {
      const cards = await this.cardsService.findUserCards(userId, query);

      return {
        success: true,
        data: cards,
        pagination: {
          limit: query.limit || 20,
          offset: query.offset || 0
        }
      };
    } catch (error) {
      logger.error(`获取用户卡片列表失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 更新卡片
   * PATCH /api/v1/cards/:id
   */
  @Patch('cards/:id')
  @ApiOperation({
    summary: '更新卡片',
    description: '更新分享卡片的文案、公开状态等信息'
  })
  @ApiParam({
    name: 'id',
    description: '卡片ID',
    example: 'cuid_card_123'
  })
  @ApiBody({ type: UpdateCardDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '卡片更新成功'
  })
  async updateCard(
    @Param('id') id: string,
    @Body(ValidationPipe) updateDto: UpdateCardDto
  ) {
    logger.debug(`更新卡片: cardId=${id}`);

    try {
      const card = await this.cardsService.updateCard(id, updateDto);

      return {
        success: true,
        data: card,
        message: 'Card updated successfully'
      };
    } catch (error) {
      logger.error(`更新卡片失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 记录卡片分享
   * POST /api/v1/cards/:id/share
   */
  @Post('cards/:id/share')
  @ApiOperation({
    summary: '记录卡片分享',
    description: '记录用户分享卡片的行为，增加分享计数'
  })
  @ApiParam({
    name: 'id',
    description: '卡片ID',
    example: 'cuid_card_123'
  })
  @ApiBody({
    schema: {
      type: 'object',
      properties: {
        platform: { type: 'string', description: '分享平台', example: 'wechat' },
        source: { type: 'string', description: '来源页面', example: 'workout_result' }
      }
    }
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '分享记录成功'
  })
  async recordShare(
    @Param('id') id: string,
    @Body() shareData: { platform?: string; source?: string }
  ) {
    logger.debug(`记录卡片分享: cardId=${id}, platform=${shareData.platform}`);

    try {
      const shareStatsDto: CardShareStatsDto = {
        cardId: id,
        platform: shareData.platform,
        source: shareData.source
      };

      const card = await this.cardsService.recordCardShare(shareStatsDto);

      return {
        success: true,
        data: card,
        message: 'Share recorded successfully'
      };
    } catch (error) {
      logger.error(`记录卡片分享失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取公开卡片（首页展示）
   * GET /api/v1/cards/public
   */
  @Get('cards/public')
  @ApiOperation({
    summary: '获取公开卡片',
    description: '获取所有公开分享的卡片，用于首页展示'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '公开卡片列表获取成功'
  })
  async getPublicCards(
    @Query('limit') limit: number = 20,
    @Query('offset') offset: number = 0
  ) {
    logger.debug(`获取公开卡片: limit=${limit}, offset=${offset}`);

    try {
      const cards = await this.cardsService.findPublicCards(limit, offset);

      return {
        success: true,
        data: cards,
        pagination: { limit, offset }
      };
    } catch (error) {
      logger.error(`获取公开卡片失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 计算器材稀有度
   * GET /api/v1/rarity/calculate/:code
   */
  @Get('rarity/calculate/:code')
  @ApiOperation({
    summary: '计算器材稀有度',
    description: '计算指定器材的当前稀有度，基于使用频率统计'
  })
  @ApiParam({
    name: 'code',
    description: '器材代码',
    example: 'chair'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '稀有度计算成功',
    schema: {
      type: 'object',
      properties: {
        equipmentCode: { type: 'string', example: 'chair' },
        rarityLevel: { type: 'string', example: 'RARE' },
        rarityScore: { type: 'number', example: 0.65 },
        weekStart: { type: 'string', format: 'date-time' },
        dataSource: { type: 'string', example: 'WEEKLY_TABLE' },
        equipment: { type: 'object' }
      }
    }
  })
  async calculateRarity(
    @Param('code') code: string,
    @Query('region') region?: string,
    @Query('forceRecalculate') forceRecalculate?: boolean
  ) {
    logger.debug(`计算稀有度: equipmentCode=${code}`);

    try {
      const calculateDto: CalculateRarityDto = {
        equipmentCode: code,
        region,
        forceRecalculate: forceRecalculate === true
      };

      const rarity = await this.cardsService.calculateRarity(calculateDto);

      return {
        success: true,
        data: rarity
      };
    } catch (error) {
      logger.error(`计算稀有度失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 批量计算稀有度
   * POST /api/v1/rarity/calculate-batch
   */
  @Post('rarity/calculate-batch')
  @ApiOperation({
    summary: '批量计算稀有度',
    description: '批量计算多个器材的稀有度'
  })
  @ApiBody({ type: BatchRarityDto })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '批量稀有度计算成功'
  })
  async calculateBatchRarity(@Body(ValidationPipe) batchDto: BatchRarityDto) {
    logger.debug(`批量计算稀有度: count=${batchDto.equipmentCodes.length}`);

    try {
      const rarities = await this.cardsService.calculateBatchRarity(batchDto);

      return {
        success: true,
        data: rarities,
        count: rarities.length
      };
    } catch (error) {
      logger.error(`批量计算稀有度失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取稀有度排行榜
   * GET /api/v1/rarity/ranking
   */
  @Get('rarity/ranking')
  @ApiOperation({
    summary: '获取稀有度排行榜',
    description: '获取当前周器材稀有度排行榜'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '稀有度排行榜获取成功'
  })
  async getRarityRanking(@Query('limit') limit: number = 10) {
    logger.debug(`获取稀有度排行榜: limit=${limit}`);

    try {
      const rankings = await this.cardsService.getRarityRanking(limit);

      return {
        success: true,
        data: rankings
      };
    } catch (error) {
      logger.error(`获取稀有度排行榜失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取稀有度历史趋势
   * GET /api/v1/rarity/:code/trend
   */
  @Get('rarity/:code/trend')
  @ApiOperation({
    summary: '获取稀有度历史趋势',
    description: '获取指定器材的稀有度历史变化趋势'
  })
  @ApiParam({
    name: 'code',
    description: '器材代码',
    example: 'chair'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '稀有度趋势获取成功'
  })
  async getRarityTrend(
    @Param('code') code: string,
    @Query('weeks') weeks: number = 8
  ) {
    logger.debug(`获取稀有度趋势: equipmentCode=${code}, weeks=${weeks}`);

    try {
      const trend = await this.cardsService.getRarityTrend(code, weeks);

      return {
        success: true,
        data: trend
      };
    } catch (error) {
      logger.error(`获取稀有度趋势失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取用户卡片收藏统计
   * GET /api/v1/users/:userId/cards/stats
   */
  @Get('users/:userId/cards/stats')
  @ApiOperation({
    summary: '获取用户卡片收藏统计',
    description: '获取用户卡片收藏的统计信息，支持按稀有度、器材系列等维度统计'
  })
  @ApiParam({
    name: 'userId',
    description: '用户ID',
    example: 'user-uuid-123'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '收藏统计获取成功'
  })
  async getCollectionStats(
    @Param('userId', ParseUUIDPipe) userId: string,
    @Query(ValidationPipe) statsDto: CollectionStatsDto
  ) {
    logger.debug(`获取用户收藏统计: userId=${userId}, dimension=${statsDto.dimension}`);

    try {
      const stats = await this.cardsService.getUserCollectionStats(userId, statsDto);

      return {
        success: true,
        data: stats
      };
    } catch (error) {
      logger.error(`获取用户收藏统计失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 健康检查
   * GET /api/v1/cards/health
   */
  @Get('cards/health')
  @ApiOperation({
    summary: '服务健康检查',
    description: '检查卡片服务的健康状态'
  })
  @ApiResponse({
    status: HttpStatus.OK,
    description: '服务状态正常'
  })
  async healthCheck() {
    try {
      const health = await this.cardsService.healthCheck();

      return {
        success: true,
        data: health
      };
    } catch (error) {
      logger.error(`健康检查失败: ${error.message}`);
      throw error;
    }
  }
}