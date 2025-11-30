import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import { GooglePlayService } from './google-play.service';
import { DailyUsageService } from './daily-usage.service.temp';

export interface CreateSubscriptionDto {
  userId: string;
  tier: 'PREMIUM' | 'PREMIUM_YEARLY';
  purchaseToken?: string;
  orderId?: string;
  productId: string;
  actualPrice: number;
  originalPrice: number;
  currency?: string;
}

export interface SubscriptionStatus {
  isActive: boolean;
  tier: string;
  status: string;
  expiresAt: Date | null;
  isTrialActive: boolean;
  trialEndsAt: Date | null;
  canStartTrial: boolean;
}

@Injectable()
export class SubscriptionService {
  constructor(
    private prisma: PrismaService,
    private googlePlayService: GooglePlayService,
    private dailyUsageService: DailyUsageService,
  ) {}

  /**
   * Get user's current subscription status
   * TEMPORARY: Returns mock data until database migration is completed
   */
  async getSubscriptionStatus(userId: string): Promise<SubscriptionStatus> {
    // TODO: Implement after running database migration
    // For now, return mock data to avoid Prisma errors
    return {
      isActive: false,
      tier: 'FREE',
      status: 'ACTIVE',
      expiresAt: null,
      isTrialActive: false,
      trialEndsAt: null,
      canStartTrial: true,
    };
  }

  /**
   * Start free trial for user
   * TEMPORARY: Mock implementation until database migration is completed
   */
  async startFreeTrial(userId: string): Promise<void> {
    // TODO: Implement after running database migration
    throw new BadRequestException('Subscription system is being initialized. Please try again later.');
  }

  /**
   * Create a premium subscription
   * TEMPORARY: Mock implementation until database migration is completed
   */
  async createSubscription(data: CreateSubscriptionDto): Promise<any> {
    // TODO: Implement after running database migration
    throw new BadRequestException('Subscription system is being initialized. Please try again later.');
  }

  /**
   * Cancel subscription
   * TEMPORARY: Mock implementation until database migration is completed
   */
  async cancelSubscription(userId: string, reason?: string): Promise<void> {
    // TODO: Implement after running database migration
    throw new BadRequestException('Subscription system is being initialized. Please try again later.');
  }

  /**
   * Check if user has premium access (including trial)
   * TEMPORARY: Returns false until database migration is completed
   */
  async hasPremiumAccess(userId: string): Promise<boolean> {
    // TODO: Implement after running database migration
    return false;
  }

  /**
   * Check if user can start a new exercise (respects daily limits)
   * TEMPORARY: Returns true until database migration is completed
   */
  async canStartExercise(userId: string, timezone = 'UTC'): Promise<boolean> {
    // TODO: Implement after running database migration
    // For now, allow all exercises to avoid blocking users
    return true;
  }

  /**
   * Record exercise completion
   * TEMPORARY: Mock implementation until database migration is completed
   */
  async recordExerciseCompletion(userId: string, timezone = 'UTC'): Promise<void> {
    // TODO: Implement after running database migration
    // For now, do nothing
  }

  /**
   * Get user's current subscription
   * TEMPORARY: Returns null until database migration is completed
   */
  async getUserSubscription(userId: string) {
    // TODO: Implement after running database migration
    return null;
  }

  /**
   * Verify Google Play subscription
   */
  async verifyGooglePlayPurchase(productId: string, purchaseToken: string): Promise<any> {
    return this.googlePlayService.verifyPurchase(productId, purchaseToken);
  }

  /**
   * Clean up expired subscriptions (cron job)
   * TEMPORARY: Mock implementation until database migration is completed
   */
  async processExpiredSubscriptions(): Promise<void> {
    // TODO: Implement after running database migration
  }
}