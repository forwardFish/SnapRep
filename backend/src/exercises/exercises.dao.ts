import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import { PrismaBaseDao } from '../common/dao/prisma-base.dao';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';

/**
 * Exercise DAO 类
 * 使用 Prisma ORM 进行数据库操作
 */
@Injectable()
export class ExercisesDao extends PrismaBaseDao<any> {
  private readonly logger = new Logger(ExercisesDao.name);

  constructor(prisma: PrismaService) {
    super(prisma);
    this.logger.log('ExercisesDao initialized with Prisma');
  }

  protected getDelegate() {
    return this.prisma.exercise;
  }

  /**
   * 根据ID查找练习动作
   * @param id 动作ID
   * @param includeInactive 是否包含非活跃动作
   * @returns 动作实体或null
   */
  async findById(id: string, includeInactive: boolean = false): Promise<any | null> {
    try {
      const where: any = { id };
      if (!includeInactive) {
        where.isActive = true;
      }

      return await this.findUnique(
        where,
        {
          exerciseEquipment: {
            include: { equipment: true }
          },
          exerciseScenarios: {
            include: { scenario: true }
          }
        }
      );
    } catch (error) {
      this.logger.error(`根据ID查找动作失败: id=${id}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EXERCISE.FETCH_FAILED, error, { exerciseId: id });
    }
  }

  /**
   * 根据代码查找练习动作
   * @param code 动作代码
   * @param includeInactive 是否包含非活跃动作
   * @returns 动作实体或null
   */
  async findByCode(code: string, includeInactive: boolean = false): Promise<any | null> {
    try {
      const where: any = { code };
      if (!includeInactive) {
        where.isActive = true;
      }

      return await this.findUnique(
        where,
        {
          exerciseEquipment: {
            include: { equipment: true }
          },
          exerciseScenarios: {
            include: { scenario: true }
          }
        }
      );
    } catch (error) {
      this.logger.error(`根据代码查找动作失败: code=${code}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EXERCISE.FETCH_FAILED, error, { exerciseCode: code });
    }
  }

  /**
   * 智能筛选练习动作
   * @param criteria 筛选条件
   * @returns 匹配的动作列表
   */
  async findBySmartCriteria(criteria: {
    intent?: string;
    equipment?: string[];
    scenario?: string;
    targetMuscles?: string[];
    difficulty?: string;
    excludeIds?: string[];
    limit?: number;
  }): Promise<any[]> {
    try {
      const where: any = { isActive: true };

      // 意图筛选
      if (criteria.intent) {
        where.intentType = criteria.intent;
      }

      // 难度筛选
      if (criteria.difficulty) {
        where.difficulty = criteria.difficulty;
      }

      // 排除指定动作
      if (criteria.excludeIds && criteria.excludeIds.length > 0) {
        where.NOT = { id: { in: criteria.excludeIds } };
      }

      // 器材筛选
      if (criteria.equipment && criteria.equipment.length > 0) {
        where.exerciseEquipment = {
          some: {
            equipment: {
              code: { in: criteria.equipment }
            }
          }
        };
      }

      // 场景筛选
      if (criteria.scenario) {
        where.exerciseScenarios = {
          some: {
            scenario: {
              code: criteria.scenario
            }
          }
        };
      }

      // 目标肌群筛选
      if (criteria.targetMuscles && criteria.targetMuscles.length > 0) {
        where.OR = [
          { primaryMuscle: { in: criteria.targetMuscles } },
          { secondaryMuscles: { hasSome: criteria.targetMuscles } }
        ];
      }

      return await this.findMany(
        where,
        {
          exerciseEquipment: {
            include: { equipment: true }
          },
          exerciseScenarios: {
            include: { scenario: true }
          }
        },
        criteria.limit || 50,
        { createdAt: 'desc' }
      );
    } catch (error) {
      this.logger.error(`智能筛选动作失败: criteria=${JSON.stringify(criteria)}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EXERCISE.FETCH_FAILED, error, { criteria });
    }
  }

  /**
   * 获取用户最近训练的动作ID
   * @param userId 用户ID
   * @param days 查看最近几天
   * @returns 最近训练的动作ID列表
   */
  async findRecentlyUsedByUser(userId: string, days: number = 7): Promise<string[]> {
    try {
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - days);

      const recentSessions = await this.prisma.workoutSession.findMany({
        where: {
          userId,
          completedAt: { gte: cutoffDate },
          status: 'COMPLETED'
        },
        include: {
          sessionExercises: {
            select: { exerciseId: true }
          }
        }
      });

      const exerciseIds = new Set<string>();
      recentSessions.forEach(session => {
        session.sessionExercises.forEach(se => {
          exerciseIds.add(se.exerciseId);
        });
      });

      return Array.from(exerciseIds);
    } catch (error) {
      this.logger.error(`获取用户最近训练动作失败: userId=${userId}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EXERCISE.FETCH_FAILED, error, { userId });
    }
  }

  /**
   * 获取动作统计信息
   * @returns 动作统计
   */
  async getExerciseStats(): Promise<any> {
    try {
      const [total, active, byDifficulty, byIntent] = await Promise.all([
        this.count(),
        this.count({ isActive: true }),
        this.getExercisesByDifficulty(),
        this.getExercisesByIntent()
      ]);

      return {
        total,
        active,
        inactive: total - active,
        byDifficulty,
        byIntent
      };
    } catch (error) {
      this.logger.error(`获取动作统计失败: error=${error.message}`);
      throw new ResponseError(ErrorCodes.EXERCISE.FETCH_FAILED, error);
    }
  }

  /**
   * 按难度分组获取动作
   */
  private async getExercisesByDifficulty(): Promise<Record<string, number>> {
    try {
      const result = await this.prisma.exercise.groupBy({
        by: ['difficulty'],
        where: { isActive: true },
        _count: { id: true }
      });

      return result.reduce((acc, item) => {
        acc[item.difficulty] = item._count.id;
        return acc;
      }, {} as Record<string, number>);
    } catch (error) {
      this.logger.error(`按难度分组获取动作失败: error=${error.message}`);
      throw error;
    }
  }

  /**
   * 按意图分组获取动作
   */
  private async getExercisesByIntent(): Promise<Record<string, number>> {
    try {
      const result = await this.prisma.exercise.groupBy({
        by: ['intentType'],
        where: { isActive: true },
        _count: { id: true }
      });

      return result.reduce((acc, item) => {
        acc[item.intentType] = item._count.id;
        return acc;
      }, {} as Record<string, number>);
    } catch (error) {
      this.logger.error(`按意图分组获取动作失败: error=${error.message}`);
      throw error;
    }
  }

  /**
   * 检查动作代码是否存在
   * @param code 动作代码
   * @param excludeId 排除的动作ID
   * @returns 是否存在
   */
  async isCodeExists(code: string, excludeId?: string): Promise<boolean> {
    try {
      const where: any = { code };
      if (excludeId) {
        where.NOT = { id: excludeId };
      }

      return await this.exists(where);
    } catch (error) {
      this.logger.error(`检查动作代码是否存在失败: code=${code}, error=${error.message}`);
      throw new ResponseError(ErrorCodes.EXERCISE.FETCH_FAILED, error, { exerciseCode: code });
    }
  }
}