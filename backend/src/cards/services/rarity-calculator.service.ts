import { Injectable, Logger } from '@nestjs/common';
import { CardsDao } from '../cards.dao';
import { PrismaService } from 'nestjs-prisma';
import { RarityLevel, DataSource } from '@prisma/client';

/**
 * 稀有度计算服务
 * 处理器材稀有度的计算和缓存逻辑
 */
@Injectable()
export class RarityCalculatorService {
  private readonly logger = new Logger(RarityCalculatorService.name);

  constructor(
    private readonly cardsDao: CardsDao,
    private readonly prisma: PrismaService
  ) {}

  /**
   * 计算器材稀有度
   * @param equipmentCode 器材代码
   * @param region 地区代码
   * @param forceRecalculate 是否强制重新计算
   * @returns 稀有度信息
   */
  async calculateRarity(equipmentCode: string, region?: string, forceRecalculate: boolean = false) {
    try {
      const weekStart = this.getCurrentWeekStart();

      // 检查是否已有当周的稀有度数据
      if (!forceRecalculate) {
        const existingRecord = await this.cardsDao.findRarityRecord(equipmentCode, weekStart);
        if (existingRecord && existingRecord.dataSource === 'WEEKLY_TABLE') {
          this.logger.debug(`使用缓存的稀有度数据: ${equipmentCode}, rarity=${existingRecord.rarityLevel}`);
          return existingRecord;
        }
      }

      // 获取器材信息
      const equipment = await this.prisma.equipment.findUnique({
        where: { code: equipmentCode }
      });

      if (!equipment) {
        throw new Error(`Equipment not found: ${equipmentCode}`);
      }

      // 计算稀有度分数
      const rarityScore = await this.calculateRarityScore(equipmentCode, weekStart, region);
      const rarityLevel = this.determineRarityLevel(rarityScore);

      // 保存或更新稀有度记录
      const rarityRecord = await this.cardsDao.upsertRarityRecord({
        equipmentId: equipment.id,
        equipmentCode,
        weekStart,
        rarityScore,
        rarityLevel,
        dataSource: 'WEEKLY_TABLE',
        region
      });

      this.logger.log(`稀有度计算完成: ${equipmentCode}, score=${rarityScore}, level=${rarityLevel}`);
      return rarityRecord;

    } catch (error) {
      this.logger.error(`稀有度计算失败: equipmentCode=${equipmentCode}, error=${error.message}`, error.stack);

      // 如果计算失败，尝试返回估算值
      return await this.getEstimatedRarity(equipmentCode, region);
    }
  }

  /**
   * 批量计算稀有度
   * @param equipmentCodes 器材代码列表
   * @param region 地区代码
   * @returns 稀有度信息列表
   */
  async calculateBatchRarity(equipmentCodes: string[], region?: string) {
    try {
      const weekStart = this.getCurrentWeekStart();

      // 获取已有的稀有度记录
      const existingRecords = await this.cardsDao.findBatchRarityRecords(equipmentCodes, weekStart);
      const existingCodes = existingRecords.map(record => record.equipmentCode);
      const missingCodes = equipmentCodes.filter(code => !existingCodes.includes(code));

      // 计算缺失的稀有度
      const newRecords = await Promise.all(
        missingCodes.map(code => this.calculateRarity(code, region))
      );

      // 合并结果
      const allRecords = [...existingRecords, ...newRecords.filter(Boolean)];

      this.logger.log(`批量稀有度计算完成: 总计${allRecords.length}个器材`);
      return allRecords;

    } catch (error) {
      this.logger.error(`批量稀有度计算失败: ${error.message}`, error.stack);
      throw error;
    }
  }

  /**
   * 获取当前周稀有度排行榜
   * @param limit 返回数量
   * @returns 稀有度排行榜
   */
  async getCurrentWeekRarityRanking(limit: number = 10) {
    try {
      const weekStart = this.getCurrentWeekStart();

      const rankings = await this.prisma.rarityTable.findMany({
        where: { weekStart },
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
        orderBy: { rarityScore: 'asc' }, // 稀有度越低越排前面
        take: limit
      });

      return rankings;
    } catch (error) {
      this.logger.error(`获取稀有度排行榜失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 计算器材的稀有度分数
   * @param equipmentCode 器材代码
   * @param weekStart 周开始时间
   * @param region 地区
   * @returns 稀有度分数 (0.0-1.0)
   */
  private async calculateRarityScore(equipmentCode: string, weekStart: Date, region?: string): Promise<number> {
    try {
      // 计算当周该器材的使用频率
      const weekEnd = new Date(weekStart);
      weekEnd.setDate(weekStart.getDate() + 7);

      // 查询当周该器材在训练会话中的使用次数
      let equipmentUsageCount;
      if (region) {
        equipmentUsageCount = await this.prisma.$queryRaw<Array<{ count: bigint }>>`
          SELECT COUNT(*) as count
          FROM workout_sessions ws
          JOIN session_exercises se ON ws.id = se.session_id
          JOIN exercise_equipment ee ON se.exercise_id = ee.exercise_id
          JOIN equipment eq ON ee.equipment_id = eq.id
          WHERE eq.code = ${equipmentCode}
            AND ws.completed_at >= ${weekStart}
            AND ws.completed_at < ${weekEnd}
            AND ws.status = 'COMPLETED'
            AND ws.region = ${region}
        `;
      } else {
        equipmentUsageCount = await this.prisma.$queryRaw<Array<{ count: bigint }>>`
          SELECT COUNT(*) as count
          FROM workout_sessions ws
          JOIN session_exercises se ON ws.id = se.session_id
          JOIN exercise_equipment ee ON se.exercise_id = ee.exercise_id
          JOIN equipment eq ON ee.equipment_id = eq.id
          WHERE eq.code = ${equipmentCode}
            AND ws.completed_at >= ${weekStart}
            AND ws.completed_at < ${weekEnd}
            AND ws.status = 'COMPLETED'
        `;
      }

      // 查询当周总的完成会话数
      let totalSessionsCount;
      if (region) {
        totalSessionsCount = await this.prisma.$queryRaw<Array<{ count: bigint }>>`
          SELECT COUNT(*) as count
          FROM workout_sessions
          WHERE completed_at >= ${weekStart}
            AND completed_at < ${weekEnd}
            AND status = 'COMPLETED'
            AND region = ${region}
        `;
      } else {
        totalSessionsCount = await this.prisma.$queryRaw<Array<{ count: bigint }>>`
          SELECT COUNT(*) as count
          FROM workout_sessions
          WHERE completed_at >= ${weekStart}
            AND completed_at < ${weekEnd}
            AND status = 'COMPLETED'
        `;
      }

      const usageCount = Number(equipmentUsageCount[0]?.count || 0);
      const totalSessions = Number(totalSessionsCount[0]?.count || 1); // 避免除零

      // 计算使用频率
      const usageFrequency = usageCount / totalSessions;

      // 稀有度分数 = 1 - 使用频率 (使用越少越稀有)
      const rarityScore = Math.max(0, Math.min(1, 1 - usageFrequency));

      this.logger.debug(`稀有度计算详情: ${equipmentCode}, usage=${usageCount}, total=${totalSessions}, frequency=${usageFrequency.toFixed(4)}, score=${rarityScore.toFixed(4)}`);

      return rarityScore;

    } catch (error) {
      this.logger.error(`稀有度分数计算失败: ${error.message}`);

      // 使用预设的估算值
      return this.getEstimatedRarityScore(equipmentCode);
    }
  }

  /**
   * 根据稀有度分数确定稀有度等级
   * @param score 稀有度分数 (0.0-1.0)
   * @returns 稀有度等级
   */
  private determineRarityLevel(score: number): RarityLevel {
    if (score >= 0.95) return 'LEGENDARY'; // 传说 (<5%使用率)
    if (score >= 0.80) return 'EPIC';      // 史诗 (5-20%使用率)
    if (score >= 0.50) return 'RARE';      // 稀有 (20-50%使用率)
    if (score >= 0.20) return 'UNCOMMON';  // 不常见 (50-80%使用率)
    return 'COMMON';                       // 常见 (>80%使用率)
  }

  /**
   * 获取器材的估算稀有度（当无法计算实际数据时使用）
   * @param equipmentCode 器材代码
   * @param region 地区
   * @returns 估算的稀有度记录
   */
  private async getEstimatedRarity(equipmentCode: string, region?: string) {
    try {
      const equipment = await this.prisma.equipment.findUnique({
        where: { code: equipmentCode }
      });

      if (!equipment) {
        throw new Error(`Equipment not found: ${equipmentCode}`);
      }

      const estimatedScore = this.getEstimatedRarityScore(equipmentCode);
      const rarityLevel = this.determineRarityLevel(estimatedScore);
      const weekStart = this.getCurrentWeekStart();

      const rarityRecord = await this.cardsDao.upsertRarityRecord({
        equipmentId: equipment.id,
        equipmentCode,
        weekStart,
        rarityScore: estimatedScore,
        rarityLevel,
        dataSource: 'ON_THE_FLY_ESTIMATE',
        region
      });

      this.logger.warn(`使用估算稀有度: ${equipmentCode}, score=${estimatedScore}, level=${rarityLevel}`);
      return rarityRecord;

    } catch (error) {
      this.logger.error(`获取估算稀有度失败: ${error.message}`);
      throw error;
    }
  }

  /**
   * 获取器材的预设估算分数
   * @param equipmentCode 器材代码
   * @returns 估算分数
   */
  private getEstimatedRarityScore(equipmentCode: string): number {
    // 基于常识的估算稀有度
    const estimatedScores = {
      'none': 0.05,      // 徒手训练最常见
      'chair': 0.35,     // 椅子比较常见
      'wall': 0.55,      // 墙壁中等稀有
      'bottle': 0.75,    // 水瓶较稀有
      'bag': 0.85,       // 背包稀有
      'stairs': 0.90,    // 楼梯很稀有
      'fabric': 0.92,    // 布料很稀有
      'stick': 0.94,     // 棍棒极稀有
      'outdoor': 0.96,   // 户外器材极稀有
      'creative': 0.98   // 创意器材传说级
    };

    return estimatedScores[equipmentCode] || 0.5; // 默认中等稀有
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

  /**
   * 获取器材稀有度历史趋势
   * @param equipmentCode 器材代码
   * @param weeks 历史周数
   * @returns 稀有度历史数据
   */
  async getRarityTrend(equipmentCode: string, weeks: number = 8) {
    try {
      const trends = await this.prisma.rarityTable.findMany({
        where: { equipmentCode },
        include: {
          equipment: {
            select: {
              name: true,
              iconUrl: true
            }
          }
        },
        orderBy: { weekStart: 'desc' },
        take: weeks
      });

      return trends.reverse(); // 按时间正序排列
    } catch (error) {
      this.logger.error(`获取稀有度趋势失败: ${error.message}`);
      throw error;
    }
  }
}