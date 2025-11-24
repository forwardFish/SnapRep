import { Injectable } from '@nestjs/common';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { RarityLevel, DataSource } from '../common/types/prisma-enums';
import { logger } from '../common/logger/logger';

/**
 * Cards DAO 类
 * 使用 Supabase API 进行数据库操作
 */
@Injectable()
export class CardsDao {
  constructor(private readonly supabaseApi: SupabaseApiService) {
    logger.info('CardsDao initialized with Supabase API');
  }

  /**
   * 创建分享卡片
   * @param cardData 卡片数据
   * @returns 创建的卡片
   */
  async createCard(cardData: any) {
    try {
      // 生成CUID ID
      const cardId = `card_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;

      const createData = {
        id: cardId,
        user_id: cardData.userId,
        session_id: cardData.sessionId,
        rarity: cardData.rarity,
        rarity_score: cardData.rarityScore || 0,
        equipment_series: cardData.equipmentSeries,
        theme_week: cardData.themeWeek || null,
        special_tags: cardData.specialTags || [],
        is_public: cardData.isPublic !== undefined ? cardData.isPublic : false,
        share_count: 0,
        view_count: 0,
        created_at: new Date().toISOString(),
        updated_at: new Date().toISOString(),
      };

      await this.supabaseApi.post('share_cards', createData);

      // 获取完整的卡片数据（包含关联）
      return await this.findCardById(cardId);
    } catch (error) {
      logger.error(`创建分享卡片失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.SHARE_CARD.CREATE_FAILED, error);
    }
  }

  /**
   * 根据会话ID查找卡片
   * @param sessionId 会话ID
   * @returns 分享卡片或null
   */
  async findCardBySessionId(sessionId: string) {
    try {
      const cards = await this.supabaseApi.get('share_cards', {
        session_id: sessionId,
      });

      if (!cards || cards.length === 0) {
        return null;
      }

      const card = cards[0];
      return await this.formatCardWithRelations(card);
    } catch (error) {
      logger.error(`根据会话ID查找卡片失败: sessionId=${sessionId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SHARE_CARD.FETCH_FAILED, error, { sessionId });
    }
  }

  /**
   * 根据ID获取卡片详情
   * @param id 卡片ID
   * @returns 分享卡片
   */
  async findCardById(id: string) {
    try {
      const card = await this.supabaseApi.getById('share_cards', id);

      if (!card) {
        return null;
      }

      return await this.formatCardWithRelations(card);
    } catch (error) {
      logger.error(`根据ID获取卡片详情失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SHARE_CARD.FETCH_FAILED, error, { cardId: id });
    }
  }

  /**
   * 获取用户的分享卡片列表
   * @param userId 用户ID
   * @param filters 筛选条件
   * @returns 卡片列表
   */
  async findUserCards(
    userId: string,
    filters?: {
      rarity?: RarityLevel;
      equipmentSeries?: string;
      themeWeek?: string;
      fromDate?: Date;
      toDate?: Date;
      publicOnly?: boolean;
      limit?: number;
      offset?: number;
    }
  ) {
    try {
      const whereFilters: Record<string, any> = {
        user_id: userId,
      };

      if (filters?.rarity) {
        whereFilters.rarity = filters.rarity;
      }

      if (filters?.equipmentSeries) {
        whereFilters.equipment_series = filters.equipmentSeries;
      }

      if (filters?.themeWeek) {
        whereFilters.theme_week = filters.themeWeek;
      }

      if (filters?.publicOnly) {
        whereFilters.is_public = true;
      }

      const limit = filters?.limit || 20;
      const offset = filters?.offset || 0;

      const cards = await this.supabaseApi.get('share_cards', whereFilters, {
        limit,
        offset,
        orderBy: 'created_at.desc',
      });

      // Filter by date range if specified
      let filteredCards = cards;
      if (filters?.fromDate || filters?.toDate) {
        filteredCards = cards.filter((card: any) => {
          if (!card.created_at) return false;
          const createdAt = new Date(card.created_at);
          if (filters.fromDate && createdAt < filters.fromDate) return false;
          if (filters.toDate && createdAt > filters.toDate) return false;
          return true;
        });
      }

      // Format cards with basic session info (not full relations)
      const formattedCards = [];
      for (const card of filteredCards) {
        const formattedCard = await this.formatCardWithBasicSession(card);
        formattedCards.push(formattedCard);
      }

      return formattedCards;
    } catch (error) {
      logger.error(`获取用户卡片列表失败: userId=${userId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SHARE_CARD.FETCH_FAILED, error, { userId, filters });
    }
  }

  /**
   * 更新分享卡片
   * @param id 卡片ID
   * @param updateData 更新数据
   * @returns 更新后的卡片
   */
  async updateCard(id: string, updateData: any) {
    try {
      const updatePayload: Record<string, any> = {
        updated_at: new Date().toISOString(),
      };

      if (updateData.isPublic !== undefined) updatePayload.is_public = updateData.isPublic;
      if (updateData.specialTags !== undefined) updatePayload.special_tags = updateData.specialTags;

      await this.supabaseApi.patch('share_cards', id, updatePayload);

      return await this.findCardById(id);
    } catch (error) {
      logger.error(`更新分享卡片失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SHARE_CARD.UPDATE_FAILED, error, { cardId: id, updateData });
    }
  }

  /**
   * 增加分享计数
   * @param id 卡片ID
   * @param platform 分享平台
   * @returns 更新后的卡片
   */
  async incrementShareCount(id: string, platform?: string) {
    try {
      const card = await this.supabaseApi.getById('share_cards', id);
      if (!card) {
        throw new Error(`Card not found: ${id}`);
      }

      const updatePayload = {
        share_count: (card.share_count || 0) + 1,
        updated_at: new Date().toISOString(),
      };

      await this.supabaseApi.patch('share_cards', id, updatePayload);

      return await this.findCardById(id);
    } catch (error) {
      logger.error(`增加分享计数失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SHARE_CARD.UPDATE_FAILED, error, { cardId: id });
    }
  }

  /**
   * 增加查看计数
   * @param id 卡片ID
   * @returns 更新后的卡片
   */
  async incrementViewCount(id: string) {
    try {
      const card = await this.supabaseApi.getById('share_cards', id);
      if (!card) {
        throw new Error(`Card not found: ${id}`);
      }

      const updatePayload = {
        view_count: (card.view_count || 0) + 1,
        updated_at: new Date().toISOString(),
      };

      await this.supabaseApi.patch('share_cards', id, updatePayload);

      return await this.findCardById(id);
    } catch (error) {
      logger.error(`增加查看计数失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SHARE_CARD.UPDATE_FAILED, error, { cardId: id });
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
      const cards = await this.supabaseApi.get('share_cards', {
        is_public: true,
      }, {
        limit,
        offset,
        orderBy: 'created_at.desc',
      });

      const formattedCards = [];
      for (const card of cards) {
        const formattedCard = await this.formatCardWithBasicSession(card);
        formattedCards.push(formattedCard);
      }

      return formattedCards;
    } catch (error) {
      logger.error(`获取公开卡片失败: error=${error.message}`);
      throw new ResponseError(ErrorCodes.SHARE_CARD.FETCH_FAILED, error);
    }
  }

  /**
   * 获取稀有度表记录
   * @param equipmentCode 器材代码
   * @param weekStart 周开始日期
   * @returns 稀有度记录
   */
  async findRarityRecord(equipmentCode: string, weekStart?: Date) {
    try {
      const currentWeekStart = weekStart || this.getCurrentWeekStart();
      const weekStartStr = currentWeekStart.toISOString().split('T')[0];

      const records = await this.supabaseApi.get('rarity_table', {
        equipment_code: equipmentCode,
        week_start: weekStartStr,
      });

      if (!records || records.length === 0) {
        return null;
      }

      const record = records[0];

      // Get equipment details
      let equipment = null;
      if (record.equipment_id) {
        try {
          const equipmentData = await this.supabaseApi.getById('equipment', record.equipment_id);
          if (equipmentData) {
            equipment = {
              id: equipmentData.id,
              name: equipmentData.name,
              code: equipmentData.code,
              category: equipmentData.category,
              iconUrl: equipmentData.icon_url,
            };
          }
        } catch (err) {
          logger.warn(`获取器材详情失败: ${err.message}`);
        }
      }

      return {
        id: record.id,
        equipmentId: record.equipment_id,
        equipmentCode: record.equipment_code,
        weekStart: record.week_start,
        rarityScore: record.rarity_score,
        rarityLevel: record.rarity_level,
        dataSource: record.data_source,
        region: record.region,
        createdAt: record.created_at,
        updatedAt: record.updated_at,
        equipment,
      };
    } catch (error) {
      logger.error(`获取稀有度记录失败: equipmentCode=${equipmentCode}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.RARITY.FETCH_FAILED, error, { equipmentCode });
    }
  }

  /**
   * 创建或更新稀有度记录
   * @param rarityData 稀有度数据
   * @returns 稀有度记录
   */
  async upsertRarityRecord(rarityData: {
    equipmentId: string;
    equipmentCode: string;
    weekStart: Date;
    rarityScore: number;
    rarityLevel: RarityLevel;
    dataSource: DataSource;
    region?: string;
  }) {
    try {
      const weekStartStr = rarityData.weekStart.toISOString().split('T')[0];

      // Check if record exists
      const existing = await this.supabaseApi.get('rarity_table', {
        equipment_code: rarityData.equipmentCode,
        week_start: weekStartStr,
      });

      if (existing && existing.length > 0) {
        // Update existing record
        const recordId = existing[0].id;
        const updateData = {
          rarity_score: rarityData.rarityScore,
          rarity_level: rarityData.rarityLevel,
          data_source: rarityData.dataSource,
          region: rarityData.region,
          updated_at: new Date().toISOString(),
        };

        await this.supabaseApi.patch('rarity_table', recordId, updateData);
        return await this.findRarityRecord(rarityData.equipmentCode, rarityData.weekStart);
      } else {
        // Create new record
        const recordId = `rarity_${Date.now()}_${Math.random().toString(36).substring(2, 11)}`;
        const createData = {
          id: recordId,
          equipment_id: rarityData.equipmentId,
          equipment_code: rarityData.equipmentCode,
          week_start: weekStartStr,
          rarity_score: rarityData.rarityScore,
          rarity_level: rarityData.rarityLevel,
          data_source: rarityData.dataSource,
          region: rarityData.region,
          created_at: new Date().toISOString(),
          updated_at: new Date().toISOString(),
        };

        await this.supabaseApi.post('rarity_table', createData);
        return await this.findRarityRecord(rarityData.equipmentCode, rarityData.weekStart);
      }
    } catch (error) {
      logger.error(`创建或更新稀有度记录失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.RARITY.UPSERT_FAILED, error, { rarityData });
    }
  }

  /**
   * 批量获取稀有度记录
   * @param equipmentCodes 器材代码列表
   * @param weekStart 周开始日期
   * @returns 稀有度记录列表
   */
  async findBatchRarityRecords(equipmentCodes: string[], weekStart?: Date) {
    try {
      const currentWeekStart = weekStart || this.getCurrentWeekStart();
      const weekStartStr = currentWeekStart.toISOString().split('T')[0];

      // Get all records for the week
      const allRecords = await this.supabaseApi.get('rarity_table', {
        week_start: weekStartStr,
      }, {
        orderBy: 'rarity_score.asc',
      });

      // Filter by equipment codes
      const filteredRecords = allRecords.filter((record: any) =>
        equipmentCodes.includes(record.equipment_code)
      );

      // Format records with equipment details
      const formattedRecords = [];
      for (const record of filteredRecords) {
        let equipment = null;
        if (record.equipment_id) {
          try {
            const equipmentData = await this.supabaseApi.getById('equipment', record.equipment_id);
            if (equipmentData) {
              equipment = {
                id: equipmentData.id,
                name: equipmentData.name,
                code: equipmentData.code,
                category: equipmentData.category,
                iconUrl: equipmentData.icon_url,
              };
            }
          } catch (err) {
            logger.warn(`获取器材详情失败: ${err.message}`);
          }
        }

        formattedRecords.push({
          id: record.id,
          equipmentId: record.equipment_id,
          equipmentCode: record.equipment_code,
          weekStart: record.week_start,
          rarityScore: record.rarity_score,
          rarityLevel: record.rarity_level,
          dataSource: record.data_source,
          region: record.region,
          equipment,
        });
      }

      return formattedRecords;
    } catch (error) {
      logger.error(`批量获取稀有度记录失败: ${error.message}`);
      throw new ResponseError(ErrorCodes.RARITY.FETCH_FAILED, error, { equipmentCodes });
    }
  }

  /**
   * 获取用户卡片收藏统计
   * @param userId 用户ID
   * @param dimension 统计维度
   * @param days 统计天数
   * @returns 统计数据
   */
  async getUserCollectionStats(userId: string, dimension: string = 'rarity', days: number = 365) {
    try {
      const fromDate = new Date();
      fromDate.setDate(fromDate.getDate() - days);

      // Get all user cards
      const allCards = await this.supabaseApi.get('share_cards', {
        user_id: userId,
      });

      // Filter by date
      const cards = allCards.filter((card: any) => {
        if (!card.created_at) return false;
        return new Date(card.created_at) >= fromDate;
      });

      if (dimension === 'rarity') {
        // Group by rarity
        const stats = new Map<string, number>();
        cards.forEach((card: any) => {
          const rarity = card.rarity || 'UNKNOWN';
          stats.set(rarity, (stats.get(rarity) || 0) + 1);
        });

        return Array.from(stats.entries())
          .map(([rarity, count]) => ({
            rarity,
            _count: { rarity: count },
          }))
          .sort((a, b) => b._count.rarity - a._count.rarity);
      } else if (dimension === 'equipment') {
        // Group by equipment series
        const stats = new Map<string, number>();
        cards.forEach((card: any) => {
          const series = card.equipment_series || 'UNKNOWN';
          stats.set(series, (stats.get(series) || 0) + 1);
        });

        return Array.from(stats.entries())
          .map(([equipmentSeries, count]) => ({
            equipmentSeries,
            _count: { equipmentSeries: count },
          }))
          .sort((a, b) => b._count.equipmentSeries - a._count.equipmentSeries);
      } else if (dimension === 'theme_week') {
        // Group by theme week
        const stats = new Map<string, number>();
        cards.forEach((card: any) => {
          if (card.theme_week) {
            stats.set(card.theme_week, (stats.get(card.theme_week) || 0) + 1);
          }
        });

        return Array.from(stats.entries())
          .map(([themeWeek, count]) => ({
            themeWeek,
            _count: { themeWeek: count },
          }))
          .sort((a, b) => b._count.themeWeek - a._count.themeWeek);
      } else {
        // Group by month
        const monthlyStats = new Map<string, any>();
        cards.forEach((card: any) => {
          const date = new Date(card.created_at);
          const month = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-01`;

          if (!monthlyStats.has(month)) {
            monthlyStats.set(month, {
              count: 0,
              uniqueEquipment: new Set<string>(),
              totalRarityScore: 0,
            });
          }

          const stats = monthlyStats.get(month);
          stats.count++;
          if (card.equipment_series) {
            stats.uniqueEquipment.add(card.equipment_series);
          }
          stats.totalRarityScore += card.rarity_score || 0;
        });

        return Array.from(monthlyStats.entries())
          .map(([month, stats]) => ({
            month,
            count: stats.count,
            unique_equipment: stats.uniqueEquipment.size,
            avg_rarity_score: stats.count > 0 ? stats.totalRarityScore / stats.count : 0,
          }))
          .sort((a, b) => b.month.localeCompare(a.month));
      }
    } catch (error) {
      logger.error(`获取用户收藏统计失败: userId=${userId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SHARE_CARD.FETCH_FAILED, error, { userId, dimension });
    }
  }

  /**
   * 格式化卡片数据（包含完整关联）
   * @param card 原始卡片数据
   * @returns 格式化后的卡片
   */
  private async formatCardWithRelations(card: any): Promise<any> {
    const formattedCard: any = {
      id: card.id,
      userId: card.user_id,
      sessionId: card.session_id,
      rarity: card.rarity,
      rarityScore: card.rarity_score,
      equipmentSeries: card.equipment_series,
      themeWeek: card.theme_week,
      specialTags: card.special_tags || [],
      isPublic: card.is_public || false,
      shareCount: card.share_count || 0,
      viewCount: card.view_count || 0,
      createdAt: card.created_at,
      updatedAt: card.updated_at,
    };

    // Get user details
    if (card.user_id) {
      try {
        const user = await this.supabaseApi.getById('users', card.user_id);
        if (user) {
          formattedCard.user = {
            id: user.id,
            name: user.name || user.email,
            avatarUrl: user.avatar_url,
          };
        }
      } catch (err) {
        logger.warn(`获取用户详情失败: ${err.message}`);
      }
    }

    // Get session details
    if (card.session_id) {
      try {
        const session = await this.supabaseApi.getById('workout_sessions', card.session_id);
        if (session) {
          formattedCard.session = {
            id: session.id,
            intentType: session.intent_type,
            totalDuration: session.total_duration,
            actualDuration: session.actual_duration,
            completedAt: session.completed_at,
          };

          // Get session exercises
          const sessionExercises = await this.supabaseApi.get('session_exercises', {
            workout_session_id: session.id,
          }, {
            orderBy: 'sequence_order.asc',
          });

          formattedCard.session.sessionExercises = [];
          for (const se of sessionExercises) {
            try {
              const exercise = await this.supabaseApi.getById('exercises', se.exercise_id);
              if (exercise) {
                formattedCard.session.sessionExercises.push({
                  exercise: {
                    name: exercise.name,
                    primaryMuscle: exercise.primary_muscle,
                  },
                });
              }
            } catch (err) {
              logger.warn(`获取动作详情失败: ${err.message}`);
            }
          }

          // Get scenario
          if (session.scenario_id) {
            try {
              const scenario = await this.supabaseApi.getById('scenarios', session.scenario_id);
              if (scenario) {
                formattedCard.session.scenario = {
                  id: scenario.id,
                  name: scenario.name,
                  code: scenario.code,
                  iconUrl: scenario.icon_url,
                };
              }
            } catch (err) {
              logger.warn(`获取场景详情失败: ${err.message}`);
            }
          }
        }
      } catch (err) {
        logger.warn(`获取会话详情失败: ${err.message}`);
      }
    }

    return formattedCard;
  }

  /**
   * 格式化卡片数据（仅基本会话信息）
   * @param card 原始卡片数据
   * @returns 格式化后的卡片
   */
  private async formatCardWithBasicSession(card: any): Promise<any> {
    const formattedCard: any = {
      id: card.id,
      userId: card.user_id,
      sessionId: card.session_id,
      rarity: card.rarity,
      rarityScore: card.rarity_score,
      equipmentSeries: card.equipment_series,
      themeWeek: card.theme_week,
      specialTags: card.special_tags || [],
      isPublic: card.is_public || false,
      shareCount: card.share_count || 0,
      viewCount: card.view_count || 0,
      createdAt: card.created_at,
      updatedAt: card.updated_at,
    };

    // Get basic session info
    if (card.session_id) {
      try {
        const session = await this.supabaseApi.getById('workout_sessions', card.session_id);
        if (session) {
          formattedCard.session = {
            id: session.id,
            intentType: session.intent_type,
            totalDuration: session.total_duration,
            actualDuration: session.actual_duration,
            completedAt: session.completed_at,
          };
        }
      } catch (err) {
        logger.warn(`获取会话详情失败: ${err.message}`);
      }
    }

    return formattedCard;
  }

  /**
   * 获取当前周的开始日期（周一）
   * @returns 当前周开始日期
   */
  private getCurrentWeekStart(): Date {
    const now = new Date();
    const dayOfWeek = now.getDay() || 7; // 周日为0，调整为7
    const weekStart = new Date(now);
    weekStart.setDate(now.getDate() - dayOfWeek + 1); // 周一
    weekStart.setHours(0, 0, 0, 0);
    return weekStart;
  }
}
