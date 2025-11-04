import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import { PrismaBaseDao } from '../common/dao/prisma-base.dao';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { SessionStatus } from '../common/types/prisma-enums';

/**
 * WorkoutSessions DAO 类
 * 使用 Prisma ORM 进行数据库操作
 */
@Injectable()
export class WorkoutSessionsDao extends PrismaBaseDao<any> {
  private readonly logger = new Logger(WorkoutSessionsDao.name);

  constructor(prisma: PrismaService) {
    super(prisma);
    this.logger.log('WorkoutSessionsDao initialized with Prisma');
  }

  protected getDelegate() {
    return this.prisma.workoutSession;
  }

  /**
   * 创建训练会话和关联的动作
   * @param sessionData 会话数据
   * @returns 创建的会话
   */
  async createSessionWithExercises(sessionData: any) {
    try {
      const { exercises, ...sessionBase } = sessionData;

      const session = await this.prisma.workoutSession.create({
        data: {
          ...sessionBase,
          sessionExercises: {
            create: exercises.map((exercise: any) => ({
              exerciseId: exercise.exerciseId,
              sequenceOrder: exercise.sequenceOrder,
              duration: exercise.duration,
              sets: exercise.sets || 1
            }))
          }
        },
        include: {
          sessionExercises: {
            include: {
              exercise: {
                include: {
                  exerciseEquipment: {
                    include: { equipment: true }
                  }
                }
              }
            },
            orderBy: { sequenceOrder: 'asc' }
          },
          scenario: true
        }
      });

      return session;
    } catch (error) {
      this.logger.error(`创建训练会话失败: ${error.message}`, error.stack);
      throw new ResponseError(ErrorCodes.WORKOUT_SESSION.CREATE_FAILED, error, { sessionData });
    }
  }

  /**
   * 根据ID获取训练会话
   * @param id 会话ID
   * @param includeExercises 是否包含动作信息
   * @returns 训练会话
   */
  async findSessionById(id: string, includeExercises: boolean = true) {
    try {
      const include: any = {
        scenario: true
      };

      if (includeExercises) {
        include.sessionExercises = {
          include: {
            exercise: {
              include: {
                exerciseEquipment: {
                  include: { equipment: true }
                }
              }
            }
          },
          orderBy: { sequenceOrder: 'asc' }
        };
      }

      return await this.findUnique({ id }, include);
    } catch (error) {
      this.logger.error(`根据ID获取训练会话失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.WORKOUT_SESSION.FETCH_FAILED, error, { sessionId: id });
    }
  }

  /**
   * 获取用户的训练会话列表
   * @param userId 用户ID
   * @param filters 筛选条件
   * @returns 会话列表
   */
  async findUserSessions(
    userId: string,
    filters?: {
      status?: string;
      fromDate?: Date;
      toDate?: Date;
      limit?: number;
      offset?: number;
    }
  ) {
    try {
      const where: any = { userId };

      if (filters?.status) {
        where.status = filters.status;
      }

      if (filters?.fromDate || filters?.toDate) {
        where.completedAt = {};
        if (filters.fromDate) {
          where.completedAt.gte = filters.fromDate;
        }
        if (filters.toDate) {
          where.completedAt.lte = filters.toDate;
        }
      }

      return await this.findMany(
        where,
        {
          sessionExercises: {
            include: {
              exercise: {
                select: {
                  id: true,
                  name: true,
                  primaryMuscle: true
                }
              }
            }
          },
          scenario: true
        },
        filters?.limit || 50,
        { completedAt: 'desc' },
        filters?.offset || 0
      );
    } catch (error) {
      this.logger.error(`获取用户训练会话失败: userId=${userId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.WORKOUT_SESSION.FETCH_FAILED, error, { userId, filters });
    }
  }

  /**
   * 更新训练会话
   * @param id 会话ID
   * @param updateData 更新数据
   * @returns 更新后的会话
   */
  async updateSession(id: string, updateData: any) {
    try {
      return await this.update({ id }, updateData);
    } catch (error) {
      this.logger.error(`更新训练会话失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.WORKOUT_SESSION.UPDATE_FAILED, error, { sessionId: id, updateData });
    }
  }

  /**
   * 更新会话动作
   * @param sessionId 会话ID
   * @param exerciseId 动作ID
   * @param updateData 更新数据
   * @returns 更新后的会话动作
   */
  async updateSessionExercise(sessionId: string, exerciseId: string, updateData: any) {
    try {
      // First find the session exercise by sessionId and exerciseId
      const sessionExercise = await this.prisma.sessionExercise.findFirst({
        where: {
          sessionId,
          exerciseId
        }
      });

      if (!sessionExercise) {
        throw new Error(`SessionExercise not found for sessionId=${sessionId}, exerciseId=${exerciseId}`);
      }

      // Update using the ID
      return await this.prisma.sessionExercise.update({
        where: {
          id: sessionExercise.id
        },
        data: updateData
      });
    } catch (error) {
      this.logger.error(`更新会话动作失败: sessionId=${sessionId}, exerciseId=${exerciseId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.WORKOUT_SESSION.UPDATE_FAILED, error, { sessionId, exerciseId, updateData });
    }
  }

  /**
   * 获取用户训练统计
   * @param userId 用户ID
   * @param days 统计天数
   * @returns 统计数据
   */
  async getUserStats(userId: string, days: number = 30) {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - days);

      const sessions = await this.findMany(
        {
          userId,
          status: SessionStatus.COMPLETED,
          completedAt: { gte: cutoffDate }
        },
        undefined,
        undefined,
        { completedAt: 'desc' }
      );

      const totalSessions = sessions.length;
      const totalDuration = sessions.reduce((sum: number, session: any) => sum + (session.actualDuration || 0), 0);

      // 计算连击天数
      const streak = await this.calculateStreak(userId);

      return {
        totalSessions,
        totalDuration,
        averageDuration: totalSessions > 0 ? Math.round(totalDuration / totalSessions) : 0,
        currentStreak: streak,
        recentSessions: sessions.slice(0, 10)
      };
    } catch (error) {
      this.logger.error(`获取用户训练统计失败: userId=${userId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.WORKOUT_SESSION.FETCH_FAILED, error, { userId });
    }
  }

  /**
   * 计算用户连击天数
   * @param userId 用户ID
   * @returns 连击天数
   */
  private async calculateStreak(userId: string): Promise<number> {
    try {
      // 获取用户最近的完成会话（按日期分组）
      const recentDays = await this.prisma.workoutSession.groupBy({
        by: ['completedAt'],
        where: {
          userId,
          status: SessionStatus.COMPLETED,
          completedAt: { not: null }
        },
        orderBy: { completedAt: 'desc' },
        take: 365 // 最多查看一年
      });

      if (recentDays.length === 0) return 0;

      // 转换为日期字符串（忽略时间）
      const uniqueDays = Array.from(new Set(
        recentDays.map(day => day.completedAt?.toISOString().split('T')[0])
      )).filter(Boolean).sort((a, b) => (b as string).localeCompare(a as string));

      // 计算连续天数
      let streak = 0;
      const today = new Date().toISOString().split('T')[0];
      let currentDate = today;

      for (const day of uniqueDays) {
        if (day === currentDate) {
          streak++;
          // 向前推一天
          const date = new Date(currentDate);
          date.setDate(date.getDate() - 1);
          currentDate = date.toISOString().split('T')[0];
        } else {
          break;
        }
      }

      return streak;
    } catch (error) {
      this.logger.error(`计算连击天数失败: userId=${userId}, error=${error.message}`);
      return 0;
    }
  }

  /**
   * 获取活跃会话数量
   * @returns 活跃会话数量
   */
  async getActiveSessionsCount(): Promise<number> {
    try {
      return await this.count({
        status: { in: ['PENDING', 'IN_PROGRESS'] }
      });
    } catch (error) {
      this.logger.error(`获取活跃会话数量失败: ${error.message}`);
      return 0;
    }
  }

  /**
   * 获取今日完成的会话数量
   * @returns 今日完成会话数量
   */
  async getTodayCompletedCount(): Promise<number> {
    try {
      const today = new Date();
      const todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate());
      const todayEnd = new Date(todayStart);
      todayEnd.setDate(todayEnd.getDate() + 1);

      return await this.count({
        status: SessionStatus.COMPLETED,
        completedAt: {
          gte: todayStart,
          lt: todayEnd
        }
      });
    } catch (error) {
      this.logger.error(`获取今日完成会话数量失败: ${error.message}`);
      return 0;
    }
  }
}