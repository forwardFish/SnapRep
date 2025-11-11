import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import { PrismaBaseDao } from '../common/dao/prisma-base.dao';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { RarityLevel, DataSource } from '../common/types/prisma-enums';
import { logger } from '../common/logger/logger';

/**
 * Cards DAO 类
 * 处理分享卡片和稀有度表的数据库操作
 */
@Injectable()
export class CardsDao extends PrismaBaseDao<any> {
  // private readonly logger = new Logger(CardsDao.name);

  constructor(prisma: PrismaService) {
    super(prisma);
    logger.info('CardsDao initialized with Prisma');
  }

  protected getDelegate() {
    return this.prisma.shareCard;
  }

  /**
   * 创建分享卡片
   * @param cardData 卡片数据
   * @returns 创建的卡片
   */
  async createCard(cardData: any) {
    try {
      const card = await this.prisma.shareCard.create({
        data: cardData,
        include: {
          user: {
            select: {
              id: true,
              name: true,
              avatarUrl: true
            }
          },
          session: {
            include: {
              sessionExercises: {
                include: {
                  exercise: {
                    select: {
                      id: true,
                      name: true,
                      primaryMuscle: true,
                      defaultDuration: true,
                      demoImageUrl: true
                    }
                  }
                },
                orderBy: { sequenceOrder: 'asc' }
              },
              scenario: {
                select: {
                  id: true,
                  name: true,
                  code: true,
                  iconUrl: true
                }
              }
            }
          }
        }
      });

      return card;
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
      return await this.prisma.shareCard.findUnique({
        where: { sessionId },
        include: {
          user: {
            select: {
              id: true,
              name: true,
              avatarUrl: true
            }
          },
          session: {
            include: {
              sessionExercises: {
                include: {
                  exercise: {
                    select: {
                      id: true,
                      name: true,
                      primaryMuscle: true,
                      defaultDuration: true,
                      demoImageUrl: true
                    }
                  }
                },
                orderBy: { sequenceOrder: 'asc' }
              }
            }
          }
        }
      });
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
      return await this.findUnique(
        { id },
        {
          user: {
            select: {
              id: true,
              name: true,
              avatarUrl: true
            }
          },
          session: {
            include: {
              sessionExercises: {
                include: {
                  exercise: {
                    select: {
                      id: true,
                      name: true,
                      primaryMuscle: true,
                      defaultDuration: true,
                      demoImageUrl: true
                    }
                  }
                },
                orderBy: { sequenceOrder: 'asc' }
              },
              scenario: {
                select: {
                  id: true,
                  name: true,
                  code: true,
                  iconUrl: true
                }
              }
            }
          }
        }
      );
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
      const where: any = { userId };

      if (filters?.rarity) {
        where.rarity = filters.rarity;
      }

      if (filters?.equipmentSeries) {
        where.equipmentSeries = filters.equipmentSeries;
      }

      if (filters?.themeWeek) {
        where.themeWeek = filters.themeWeek;
      }

      if (filters?.publicOnly) {
        where.isPublic = true;
      }

      if (filters?.fromDate || filters?.toDate) {
        where.createdAt = {};
        if (filters.fromDate) {
          where.createdAt.gte = filters.fromDate;
        }
        if (filters.toDate) {
          where.createdAt.lte = filters.toDate;
        }
      }

      return await this.findMany(
        where,
        {
          session: {
            select: {
              id: true,
              intentType: true,
              totalDuration: true,
              actualDuration: true,
              completedAt: true,
              sessionExercises: {
                select: {
                  exercise: {
                    select: {
                      name: true,
                      primaryMuscle: true
                    }
                  }
                }
              }
            }
          }
        },
        filters?.limit || 20,
        { createdAt: 'desc' },
        filters?.offset || 0
      );
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
      return await this.update({ id }, updateData);
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
      return await this.prisma.shareCard.update({
        where: { id },
        data: {
          shareCount: { increment: 1 }
        }
      });
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
      return await this.prisma.shareCard.update({
        where: { id },
        data: {
          viewCount: { increment: 1 }
        }
      });
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
      return await this.findMany(
        { isPublic: true },
        {
          user: {
            select: {
              id: true,
              name: true,
              avatarUrl: true
            }
          },
          session: {
            select: {
              intentType: true,
              totalDuration: true,
              actualDuration: true,
              completedAt: true,
              sessionExercises: {
                select: {
                  exercise: {
                    select: {
                      name: true,
                      primaryMuscle: true
                    }
                  }
                }
              }
            }
          }
        },
        limit,
        { createdAt: 'desc' },
        offset
      );
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

      return await this.prisma.rarityTable.findUnique({
        where: {
          equipmentCode_weekStart: {
            equipmentCode,
            weekStart: currentWeekStart
          }
        },
        include: {
          equipment: {
            select: {
              id: true,
              name: true,
              code: true,
              category: true,
              iconUrl: true
            }
          }
        }
      });
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
      return await this.prisma.rarityTable.upsert({
        where: {
          equipmentCode_weekStart: {
            equipmentCode: rarityData.equipmentCode,
            weekStart: rarityData.weekStart
          }
        },
        update: {
          rarityScore: rarityData.rarityScore,
          rarityLevel: rarityData.rarityLevel,
          dataSource: rarityData.dataSource,
          region: rarityData.region,
          updatedAt: new Date()
        },
        create: rarityData,
        include: {
          equipment: {
            select: {
              id: true,
              name: true,
              code: true,
              category: true,
              iconUrl: true
            }
          }
        }
      });
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

      return await this.prisma.rarityTable.findMany({
        where: {
          equipmentCode: { in: equipmentCodes },
          weekStart: currentWeekStart
        },
        include: {
          equipment: {
            select: {
              id: true,
              name: true,
              code: true,
              category: true,
              iconUrl: true
            }
          }
        },
        orderBy: { rarityScore: 'asc' }
      });
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

      if (dimension === 'rarity') {
        // 按稀有度统计
        return await this.prisma.shareCard.groupBy({
          by: ['rarity'],
          where: {
            userId,
            createdAt: { gte: fromDate }
          },
          _count: { rarity: true },
          orderBy: { _count: { rarity: 'desc' } }
        });
      } else if (dimension === 'equipment') {
        // 按器材系列统计
        return await this.prisma.shareCard.groupBy({
          by: ['equipmentSeries'],
          where: {
            userId,
            createdAt: { gte: fromDate }
          },
          _count: { equipmentSeries: true },
          orderBy: { _count: { equipmentSeries: 'desc' } }
        });
      } else if (dimension === 'theme_week') {
        // 按主题周统计
        return await this.prisma.shareCard.groupBy({
          by: ['themeWeek'],
          where: {
            userId,
            createdAt: { gte: fromDate },
            themeWeek: { not: null }
          },
          _count: { themeWeek: true },
          orderBy: { _count: { themeWeek: 'desc' } }
        });
      } else {
        // 按月份统计
        const monthlyStats = await this.prisma.$queryRaw`
          SELECT
            DATE_TRUNC('month', created_at) as month,
            COUNT(*) as count,
            COUNT(DISTINCT equipment_series) as unique_equipment,
            AVG(rarity_score) as avg_rarity_score
          FROM share_cards
          WHERE user_id = ${userId}
            AND created_at >= ${fromDate}
          GROUP BY DATE_TRUNC('month', created_at)
          ORDER BY month DESC
        `;
        return monthlyStats;
      }
    } catch (error) {
      logger.error(`获取用户收藏统计失败: userId=${userId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.SHARE_CARD.FETCH_FAILED, error, { userId, dimension });
    }
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