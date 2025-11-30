import { Injectable, Logger } from '@nestjs/common';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';

export interface DailyUsageRecord {
  id: string;
  userId: string;
  usageDate: Date;
  exerciseCount: number;
  resetAt: Date;
  createdAt?: Date;
  updatedAt?: Date;
}

/**
 * DailyUsageService
 * 每日使用统计服务 - 使用 SupabaseApiService 直接操作数据库
 * 绕过 Prisma 连接问题
 */
@Injectable()
export class DailyUsageService {
  private readonly logger = new Logger(DailyUsageService.name);
  private readonly FREE_DAILY_LIMIT = parseInt(process.env.FREE_DAILY_EXERCISE_LIMIT || '3');

  constructor(private readonly supabaseApi: SupabaseApiService) {
    this.logger.log('✅ DailyUsageService initialized with SupabaseApiService');
  }

  /**
   * 获取今日使用统计
   * @param userId 用户ID
   * @param timezone 用户时区(可选)
   */
  async getTodayUsage(userId: string, timezone = 'UTC'): Promise<DailyUsageRecord> {
    try {
      const today = this.getLocalDate(timezone);
      const resetAt = this.getNextResetTime(timezone);

      // 查找今日记录
      const records = await this.supabaseApi.get('daily_usage', {
        user_id: userId,
        usage_date: `eq.${today.toISOString().split('T')[0]}`,
      });

      // 如果存在记录,返回第一条
      if (records && records.length > 0) {
        const record = records[0];
        return {
          id: record.id,
          userId: record.user_id,
          usageDate: new Date(record.usage_date),
          exerciseCount: record.exercise_count,
          resetAt: new Date(record.reset_at),
          createdAt: record.created_at ? new Date(record.created_at) : undefined,
          updatedAt: record.updated_at ? new Date(record.updated_at) : undefined,
        };
      }

      // 不存在则创建新记录
      const newRecord = {
        user_id: userId,
        usage_date: today.toISOString().split('T')[0],
        exercise_count: 0,
        reset_at: resetAt.toISOString(),
      };

      const created = await this.supabaseApi.create('daily_usage', newRecord);

      if (!created) {
        this.logger.error(`Failed to create daily usage record for user ${userId}`);
        throw new ResponseError(ErrorCodes.DAILY_USAGE.CREATE_FAILED);
      }

      return {
        id: created.id,
        userId: created.user_id,
        usageDate: new Date(created.usage_date),
        exerciseCount: created.exercise_count,
        resetAt: new Date(created.reset_at),
        createdAt: created.created_at ? new Date(created.created_at) : undefined,
        updatedAt: created.updated_at ? new Date(created.updated_at) : undefined,
      };
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`Failed to get today's usage for user ${userId}:`, error);
      throw new ResponseError(ErrorCodes.DAILY_USAGE.FETCH_FAILED);
    }
  }

  /**
   * 增加每日使用计数
   * @param userId 用户ID
   * @param timezone 用户时区(可选)
   */
  async incrementUsage(userId: string, timezone = 'UTC'): Promise<DailyUsageRecord> {
    try {
      const today = this.getLocalDate(timezone);
      const todayStr = today.toISOString().split('T')[0];
      const resetAt = this.getNextResetTime(timezone);

      // 先尝试查找今日记录
      const existingRecords = await this.supabaseApi.get('daily_usage', {
        user_id: userId,
        usage_date: `eq.${todayStr}`,
      });

      if (existingRecords && existingRecords.length > 0) {
        // 更新现有记录
        const record = existingRecords[0];
        const updated = await this.supabaseApi.update(
          'daily_usage',
          record.id,
          { exercise_count: record.exercise_count + 1 },
        );

        if (!updated) {
          throw new ResponseError(ErrorCodes.DAILY_USAGE.UPDATE_FAILED);
        }

        return {
          id: updated.id,
          userId: updated.user_id,
          usageDate: new Date(updated.usage_date),
          exerciseCount: updated.exercise_count,
          resetAt: new Date(updated.reset_at),
          createdAt: updated.created_at ? new Date(updated.created_at) : undefined,
          updatedAt: updated.updated_at ? new Date(updated.updated_at) : undefined,
        };
      } else {
        // 创建新记录,初始值为1
        const newRecord = {
          user_id: userId,
          usage_date: todayStr,
          exercise_count: 1,
          reset_at: resetAt.toISOString(),
        };

        const created = await this.supabaseApi.create('daily_usage', newRecord);

        if (!created) {
          throw new ResponseError(ErrorCodes.DAILY_USAGE.CREATE_FAILED);
        }

        return {
          id: created.id,
          userId: created.user_id,
          usageDate: new Date(created.usage_date),
          exerciseCount: created.exercise_count,
          resetAt: new Date(created.reset_at),
          createdAt: created.created_at ? new Date(created.created_at) : undefined,
          updatedAt: created.updated_at ? new Date(created.updated_at) : undefined,
        };
      }
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`Failed to increment usage for user ${userId}:`, error);
      throw new ResponseError(ErrorCodes.DAILY_USAGE.UPDATE_FAILED);
    }
  }

  /**
   * 获取用户使用历史
   * @param userId 用户ID
   * @param days 查询天数(默认30天)
   */
  async getUsageHistory(userId: string, days = 30): Promise<DailyUsageRecord[]> {
    try {
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);
      const startDateStr = startDate.toISOString().split('T')[0];

      const records = await this.supabaseApi.get('daily_usage', {
        user_id: userId,
        usage_date: `gte.${startDateStr}`,
      });

      if (!records || records.length === 0) {
        return [];
      }

      return records.map((record: any) => ({
        id: record.id,
        userId: record.user_id,
        usageDate: new Date(record.usage_date),
        exerciseCount: record.exercise_count,
        resetAt: new Date(record.reset_at),
        createdAt: record.created_at ? new Date(record.created_at) : undefined,
        updatedAt: record.updated_at ? new Date(record.updated_at) : undefined,
      }));
    } catch (error) {
      this.logger.error(`Failed to get usage history for user ${userId}:`, error);
      throw new ResponseError(ErrorCodes.DAILY_USAGE.FETCH_FAILED);
    }
  }

  /**
   * 获取本周训练统计摘要
   * @param userId 用户ID
   * @param timezone 用户时区(可选)
   */
  async getWeeklySummary(userId: string, timezone = 'UTC') {
    try {
      const endDate = this.getLocalDate(timezone);
      const startDate = new Date(endDate);
      startDate.setDate(startDate.getDate() - 6); // Last 7 days

      const startDateStr = startDate.toISOString().split('T')[0];
      const endDateStr = endDate.toISOString().split('T')[0];

      const records = await this.supabaseApi.get('daily_usage', {
        user_id: userId,
        usage_date: `gte.${startDateStr}`,
      });

      if (!records || records.length === 0) {
        return {
          totalExercises: 0,
          activeDays: 0,
          averagePerDay: 0,
          dailyRecords: [],
        };
      }

      // 过滤并转换记录
      const dailyRecords = records
        .filter((record: any) => {
          const usageDate = new Date(record.usage_date);
          return usageDate <= endDate;
        })
        .map((record: any) => ({
          id: record.id,
          userId: record.user_id,
          usageDate: new Date(record.usage_date),
          exerciseCount: record.exercise_count,
          resetAt: new Date(record.reset_at),
        }));

      const totalExercises = dailyRecords.reduce((sum, record) => sum + record.exerciseCount, 0);
      const activeDays = dailyRecords.filter(record => record.exerciseCount > 0).length;
      const averagePerDay = activeDays > 0 ? totalExercises / activeDays : 0;

      return {
        totalExercises,
        activeDays,
        averagePerDay: Math.round(averagePerDay * 10) / 10, // Round to 1 decimal
        dailyRecords,
      };
    } catch (error) {
      this.logger.error(`Failed to get weekly summary for user ${userId}:`, error);
      throw new ResponseError(ErrorCodes.DAILY_USAGE.FETCH_FAILED);
    }
  }

  /**
   * 检查用户是否达到每日限制
   * @param userId 用户ID
   * @param timezone 用户时区(可选)
   */
  async hasReachedDailyLimit(userId: string, timezone = 'UTC'): Promise<boolean> {
    try {
      const usage = await this.getTodayUsage(userId, timezone);
      return usage.exerciseCount >= this.FREE_DAILY_LIMIT;
    } catch (error) {
      this.logger.error(`Failed to check daily limit for user ${userId}:`, error);
      // 发生错误时,为了安全起见,假设已达到限制
      return true;
    }
  }

  /**
   * 重置每日使用统计(定时任务 - 每天午夜UTC时间运行)
   */
  async resetDailyUsage(): Promise<void> {
    try {
      this.logger.log('Running daily usage cleanup...');

      // 清理90天以前的旧记录
      const cutoffDate = new Date();
      cutoffDate.setDate(cutoffDate.getDate() - 90);
      const cutoffDateStr = cutoffDate.toISOString().split('T')[0];

      // 注意: SupabaseApiService 的 delete 方法可能需要特殊处理
      // 这里我们使用简单的日期过滤
      const oldRecords = await this.supabaseApi.get('daily_usage', {
        usage_date: `lt.${cutoffDateStr}`,
      });

      if (oldRecords && oldRecords.length > 0) {
        this.logger.log(`Found ${oldRecords.length} old records to delete`);
        // 批量删除旧记录
        for (const record of oldRecords) {
          await this.supabaseApi.delete('daily_usage', record.id);
        }
        this.logger.log(`✅ Cleaned up ${oldRecords.length} old daily usage records`);
      } else {
        this.logger.log('No old records to clean up');
      }
    } catch (error) {
      this.logger.error('Failed to reset daily usage:', error);
    }
  }

  /**
   * 获取用户时区的本地日期(午夜时间)
   * @param timezone 时区字符串
   */
  private getLocalDate(timezone: string): Date {
    try {
      const now = new Date();

      // 转换到用户时区并获取日期部分
      const localTime = new Date(now.toLocaleString('en-US', { timeZone: timezone }));

      // 返回本地时区的午夜时间
      return new Date(localTime.getFullYear(), localTime.getMonth(), localTime.getDate());
    } catch (error) {
      this.logger.error(`Invalid timezone: ${timezone}, falling back to UTC`);
      // 如果时区无效,使用UTC
      const now = new Date();
      return new Date(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
    }
  }

  /**
   * 获取下次重置时间(用户时区的午夜)
   * @param timezone 时区字符串
   */
  private getNextResetTime(timezone: string): Date {
    try {
      const localDate = this.getLocalDate(timezone);
      const nextDay = new Date(localDate);
      nextDay.setDate(nextDay.getDate() + 1);

      // 转换回UTC时间
      const utcOffset = new Date().getTimezoneOffset() * 60000;
      const timezoneOffset = this.getTimezoneOffset(timezone);

      return new Date(nextDay.getTime() - timezoneOffset);
    } catch (error) {
      this.logger.error(`Failed to calculate reset time for timezone ${timezone}:`, error);
      // 如果计算失败,返回明天UTC午夜
      const tomorrow = new Date();
      tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);
      tomorrow.setUTCHours(0, 0, 0, 0);
      return tomorrow;
    }
  }

  /**
   * 获取时区偏移量(毫秒)
   * @param timezone 时区字符串
   */
  private getTimezoneOffset(timezone: string): number {
    try {
      const now = new Date();
      const utcTime = now.getTime();
      const localTime = new Date(now.toLocaleString('en-US', { timeZone: timezone })).getTime();

      return utcTime - localTime;
    } catch (error) {
      this.logger.error(`Failed to calculate timezone offset for ${timezone}:`, error);
      return 0; // 如果失败,返回0(UTC)
    }
  }
}
