import { Injectable } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';

export interface DailyUsageRecord {
  id: string;
  userId: string;
  usageDate: Date;
  exerciseCount: number;
  resetAt: Date;
}

@Injectable()
export class DailyUsageService {
  constructor(private prisma: PrismaService) {}

  /**
   * Get today's usage for a user
   */
  async getTodayUsage(userId: string, timezone = 'UTC'): Promise<DailyUsageRecord> {
    const today = this.getLocalDate(timezone);
    const resetAt = this.getNextResetTime(timezone);

    // Try to find existing record
    let usage = await this.prisma.dailyUsage.findUnique({
      where: {
        userId_usageDate: {
          userId,
          usageDate: today,
        },
      },
    });

    // Create record if it doesn't exist
    if (!usage) {
      usage = await this.prisma.dailyUsage.create({
        data: {
          userId,
          usageDate: today,
          exerciseCount: 0,
          resetAt,
        },
      });
    }

    return usage;
  }

  /**
   * Increment daily usage count
   */
  async incrementUsage(userId: string, timezone = 'UTC'): Promise<DailyUsageRecord> {
    const today = this.getLocalDate(timezone);
    const resetAt = this.getNextResetTime(timezone);

    const usage = await this.prisma.dailyUsage.upsert({
      where: {
        userId_usageDate: {
          userId,
          usageDate: today,
        },
      },
      update: {
        exerciseCount: {
          increment: 1,
        },
      },
      create: {
        userId,
        usageDate: today,
        exerciseCount: 1,
        resetAt,
      },
    });

    return usage;
  }

  /**
   * Get usage history for a user
   */
  async getUsageHistory(userId: string, days = 30): Promise<DailyUsageRecord[]> {
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    return this.prisma.dailyUsage.findMany({
      where: {
        userId,
        usageDate: {
          gte: startDate,
        },
      },
      orderBy: {
        usageDate: 'desc',
      },
    });
  }

  /**
   * Reset daily usage for all users (cron job - runs at midnight UTC)
   */
  async resetDailyUsage(): Promise<void> {
    // This is handled automatically by our upsert logic
    // Old records with past reset times will naturally expire

    // Optional: Clean up old usage records (older than 90 days)
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - 90);

    await this.prisma.dailyUsage.deleteMany({
      where: {
        usageDate: {
          lt: cutoffDate,
        },
      },
    });
  }

  /**
   * Get user's weekly exercise summary
   */
  async getWeeklySummary(userId: string, timezone = 'UTC') {
    const endDate = this.getLocalDate(timezone);
    const startDate = new Date(endDate);
    startDate.setDate(startDate.getDate() - 6); // Last 7 days

    const records = await this.prisma.dailyUsage.findMany({
      where: {
        userId,
        usageDate: {
          gte: startDate,
          lte: endDate,
        },
      },
      orderBy: {
        usageDate: 'asc',
      },
    });

    const totalExercises = records.reduce((sum, record) => sum + record.exerciseCount, 0);
    const activeDays = records.filter(record => record.exerciseCount > 0).length;
    const averagePerDay = activeDays > 0 ? totalExercises / activeDays : 0;

    return {
      totalExercises,
      activeDays,
      averagePerDay: Math.round(averagePerDay * 10) / 10, // Round to 1 decimal
      dailyRecords: records,
    };
  }

  /**
   * Check if user has reached daily limit
   */
  async hasReachedDailyLimit(userId: string, timezone = 'UTC'): Promise<boolean> {
    const usage = await this.getTodayUsage(userId, timezone);
    return usage.exerciseCount >= 3; // Free tier limit
  }

  /**
   * Get local date in user's timezone
   */
  private getLocalDate(timezone: string): Date {
    const now = new Date();

    // Convert to user's timezone and get just the date part
    const localTime = new Date(now.toLocaleString('en-US', { timeZone: timezone }));

    // Return date at midnight local time
    return new Date(localTime.getFullYear(), localTime.getMonth(), localTime.getDate());
  }

  /**
   * Get next reset time (midnight in user's timezone)
   */
  private getNextResetTime(timezone: string): Date {
    const localDate = this.getLocalDate(timezone);
    const nextDay = new Date(localDate);
    nextDay.setDate(nextDay.getDate() + 1);

    // Convert back to UTC
    const utcOffset = new Date().getTimezoneOffset() * 60000;
    const timezoneOffset = this.getTimezoneOffset(timezone);

    return new Date(nextDay.getTime() - timezoneOffset);
  }

  /**
   * Get timezone offset in milliseconds
   */
  private getTimezoneOffset(timezone: string): number {
    const now = new Date();
    const utcTime = now.getTime();
    const localTime = new Date(now.toLocaleString('en-US', { timeZone: timezone })).getTime();

    return utcTime - localTime;
  }
}