import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import { logger } from '../common/logger/logger';

@Injectable()
export class ThemeWeeksDao {
  // private readonly logger = new Logger(ThemeWeeksDao.name);

  constructor(private readonly prisma: PrismaService) {
    logger.info('ThemeWeeksDao initialized with Prisma');
  }

  /**
   * 获取当前活跃的主题周
   */
  async getCurrentThemeWeek() {
    const now = new Date();

    logger.info(`🔍 Querying for current theme week at ${now.toISOString()}`);

    // 首先查看所有主题周的数据
    const allThemeWeeks = await this.prisma.themeWeek.findMany({
      select: {
        id: true,
        title: true,
        code: true,
        status: true,
        isVisible: true,
        startDate: true,
        endDate: true,
      },
      orderBy: {
        startDate: 'desc',
      },
    });

    logger.info(`📊 Found ${allThemeWeeks.length} total theme weeks in database:`);
    allThemeWeeks.forEach(week => {
      const isInDateRange = week.startDate <= now && week.endDate >= now;
      logger.info(`- ${week.code}: status=${week.status}, visible=${week.isVisible}, start=${week.startDate.toISOString()}, end=${week.endDate.toISOString()}, inRange=${isInDateRange}`);
    });

    const result = await this.prisma.themeWeek.findFirst({
      where: {
        status: 'ACTIVE',
        isVisible: true,
        startDate: { lte: now },
        endDate: { gte: now },
      },
      orderBy: {
        startDate: 'desc',
      },
    });

    if (result) {
      logger.info(`✅ Found current theme week: ${result.code} (${result.title})`);
    } else {
      logger.warn('❌ No current theme week found matching criteria');
    }

    return result;
  }

  /**
   * 获取即将到来的主题周（用于预览）
   */
  async getUpcomingThemeWeeks(limit: number = 2) {
    const now = new Date();

    return await this.prisma.themeWeek.findMany({
      where: {
        status: 'UPCOMING',
        isVisible: true,
        startDate: { gt: now },
      },
      orderBy: {
        startDate: 'asc',
      },
      take: limit,
      select: {
        title: true,
        equipmentCode: true,
        startDate: true,
      },
    });
  }

  /**
   * 获取用户在特定主题周的参与信息
   */
  async getUserParticipation(userId: string, themeWeekId: string) {
    return await this.prisma.themeWeekParticipation.findUnique({
      where: {
        userId_themeWeekId: {
          userId,
          themeWeekId,
        },
      },
    });
  }

  /**
   * 创建主题周参与记录
   */
  async createParticipation(userId: string, themeWeekId: string, targetExercises: number) {
    return await this.prisma.themeWeekParticipation.create({
      data: {
        userId,
        themeWeekId,
        targetExercises,
        status: 'JOINED',
      },
    });
  }

  /**
   * 更新用户参与进度
   */
  async updateParticipationProgress(
    userId: string,
    themeWeekId: string,
    exercisesCompleted: number,
  ) {
    const participation = await this.getUserParticipation(userId, themeWeekId);
    if (!participation) {
      throw new Error('Participation not found');
    }

    const progressPercent = (exercisesCompleted / participation.targetExercises) * 100;
    const isCompleted = exercisesCompleted >= participation.targetExercises;

    return await this.prisma.themeWeekParticipation.update({
      where: {
        userId_themeWeekId: {
          userId,
          themeWeekId,
        },
      },
      data: {
        exercisesCompleted,
        progressPercent,
        status: isCompleted ? 'COMPLETED' : 'IN_PROGRESS',
        completedAt: isCompleted ? new Date() : null,
        rewardEarned: isCompleted,
      },
    });
  }

  /**
   * 检查用户是否已经加入特定主题周
   */
  async hasUserJoinedThemeWeek(userId: string, themeWeekId: string): Promise<boolean> {
    const participation = await this.getUserParticipation(userId, themeWeekId);
    return !!participation;
  }

  /**
   * 获取主题周的全局统计信息
   */
  async getThemeWeekGlobalStats(themeWeekId: string) {
    const themeWeek = await this.prisma.themeWeek.findUnique({
      where: { id: themeWeekId },
      select: {
        totalParticipants: true,
        totalCompletions: true,
        completionRate: true,
      },
    });

    return themeWeek;
  }

  /**
   * 更新主题周的全局统计信息（当有新用户加入或完成时调用）
   */
  async updateThemeWeekStats(themeWeekId: string) {
    // 统计总参与人数
    const totalParticipants = await this.prisma.themeWeekParticipation.count({
      where: { themeWeekId },
    });

    // 统计总完成人数
    const totalCompletions = await this.prisma.themeWeekParticipation.count({
      where: {
        themeWeekId,
        status: 'COMPLETED',
      },
    });

    // 计算完成率
    const completionRate = totalParticipants > 0 ? (totalCompletions / totalParticipants) * 100 : 0;

    // 更新主题周统计信息
    return await this.prisma.themeWeek.update({
      where: { id: themeWeekId },
      data: {
        totalParticipants,
        totalCompletions,
        completionRate,
      },
    });
  }

  /**
   * 获取主题周详细信息（包含参与信息）
   */
  async getThemeWeekWithParticipation(themeWeekId: string, userId?: string) {
    const themeWeek = await this.prisma.themeWeek.findUnique({
      where: { id: themeWeekId },
      include: {
        participations: userId ? {
          where: { userId },
        } : false,
      },
    });

    return themeWeek;
  }
}