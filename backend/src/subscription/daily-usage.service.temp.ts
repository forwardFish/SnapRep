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
   * TEMPORARY: Returns mock data until database migration is completed
   */
  async getTodayUsage(userId: string, timezone = 'UTC'): Promise<DailyUsageRecord> {
    // TODO: Implement after running database migration
    return {
      id: 'temp-id',
      userId,
      usageDate: new Date(),
      exerciseCount: 0,
      resetAt: new Date(Date.now() + 24 * 60 * 60 * 1000), // tomorrow
    };
  }

  /**
   * Increment daily usage count
   * TEMPORARY: Returns mock data until database migration is completed
   */
  async incrementUsage(userId: string, timezone = 'UTC'): Promise<DailyUsageRecord> {
    // TODO: Implement after running database migration
    return this.getTodayUsage(userId, timezone);
  }

  /**
   * Get usage history for a user
   * TEMPORARY: Returns empty array until database migration is completed
   */
  async getUsageHistory(userId: string, days = 30): Promise<DailyUsageRecord[]> {
    // TODO: Implement after running database migration
    return [];
  }

  /**
   * Reset daily usage for all users (cron job - runs at midnight UTC)
   * TEMPORARY: Mock implementation until database migration is completed
   */
  async resetDailyUsage(): Promise<void> {
    // TODO: Implement after running database migration
  }

  /**
   * Get user's weekly exercise summary
   * TEMPORARY: Returns mock data until database migration is completed
   */
  async getWeeklySummary(userId: string, timezone = 'UTC') {
    // TODO: Implement after running database migration
    return {
      totalExercises: 0,
      activeDays: 0,
      averagePerDay: 0,
      dailyRecords: [],
    };
  }

  /**
   * Check if user has reached daily limit
   * TEMPORARY: Returns false until database migration is completed
   */
  async hasReachedDailyLimit(userId: string, timezone = 'UTC'): Promise<boolean> {
    // TODO: Implement after running database migration
    return false; // Allow all exercises for now
  }
}