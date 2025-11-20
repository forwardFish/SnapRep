import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from 'nestjs-prisma';
import { GooglePlayService } from './google-play.service';
import { DailyUsageService } from './daily-usage.service';

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
   */
  async getSubscriptionStatus(userId: string): Promise<SubscriptionStatus> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        subscriptionTier: true,
        subscriptionStatus: true,
        premiumExpiresAt: true,
        freeTrialUsed: true,
        trialStartedAt: true,
      },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    const now = new Date();
    const trialEndsAt = user.trialStartedAt
      ? new Date(user.trialStartedAt.getTime() + 7 * 24 * 60 * 60 * 1000) // 7 days
      : null;

    const isTrialActive = !user.freeTrialUsed &&
      trialEndsAt &&
      now <= trialEndsAt;

    const isPremiumActive = user.subscriptionTier !== 'FREE' &&
      user.subscriptionStatus === 'ACTIVE' &&
      (!user.premiumExpiresAt || user.premiumExpiresAt > now);

    return {
      isActive: isPremiumActive || isTrialActive,
      tier: user.subscriptionTier,
      status: user.subscriptionStatus,
      expiresAt: user.premiumExpiresAt,
      isTrialActive,
      trialEndsAt,
      canStartTrial: !user.freeTrialUsed && !user.trialStartedAt,
    };
  }

  /**
   * Start free trial for user
   */
  async startFreeTrial(userId: string): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { freeTrialUsed: true, trialStartedAt: true },
    });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (user.freeTrialUsed || user.trialStartedAt) {
      throw new BadRequestException('Free trial already used or started');
    }

    await this.prisma.user.update({
      where: { id: userId },
      data: {
        trialStartedAt: new Date(),
        freeTrialUsed: true,
      },
    });
  }

  /**
   * Create a premium subscription
   */
  async createSubscription(data: CreateSubscriptionDto): Promise<any> {
    const { userId, tier, purchaseToken, orderId, productId, actualPrice, originalPrice, currency = 'USD' } = data;

    // Verify Google Play purchase if provided
    if (purchaseToken) {
      const verification = await this.googlePlayService.verifyPurchase(
        productId,
        purchaseToken
      );

      if (!verification.isValid) {
        throw new BadRequestException('Invalid purchase token');
      }
    }

    const now = new Date();
    const endDate = tier === 'PREMIUM_YEARLY'
      ? new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000) // 1 year
      : new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);  // 1 month

    const renewsAt = new Date(endDate);

    // Create subscription in a transaction
    const result = await this.prisma.$transaction(async (tx) => {
      // Create subscription record
      const subscription = await tx.subscription.create({
        data: {
          userId,
          tier: tier as any,
          status: 'ACTIVE',
          paymentPlatform: 'GOOGLE_PLAY',
          productId,
          purchaseToken,
          orderId,
          startDate: now,
          endDate,
          renewsAt,
          currency,
          originalPrice: originalPrice,
          actualPrice: actualPrice,
        },
      });

      // Update user subscription status for quick queries
      await tx.user.update({
        where: { id: userId },
        data: {
          subscriptionTier: tier as any,
          subscriptionStatus: 'ACTIVE',
          premiumExpiresAt: endDate,
        },
      });

      // Create payment transaction record
      if (purchaseToken) {
        await tx.paymentTransaction.create({
          data: {
            subscriptionId: subscription.id,
            userId,
            platform: 'GOOGLE_PLAY',
            transactionId: orderId || purchaseToken,
            purchaseToken,
            amount: actualPrice,
            currency,
            productId,
            status: 'SUCCESS',
            processedAt: now,
            verifiedAt: now,
          },
        });
      }

      return subscription;
    });

    return result;
  }

  /**
   * Cancel subscription
   */
  async cancelSubscription(userId: string, reason?: string): Promise<void> {
    const subscription = await this.prisma.subscription.findUnique({
      where: { userId },
    });

    if (!subscription) {
      throw new NotFoundException('No active subscription found');
    }

    await this.prisma.$transaction(async (tx) => {
      // Update subscription status
      await tx.subscription.update({
        where: { userId },
        data: {
          status: 'CANCELED',
          canceledAt: new Date(),
          cancelReason: reason,
          willRenew: false,
        },
      });

      // Note: Keep user's premium access until end date
      // Don't update user.subscriptionStatus immediately
    });
  }

  /**
   * Check if user has premium access (including trial)
   */
  async hasPremiumAccess(userId: string): Promise<boolean> {
    const status = await this.getSubscriptionStatus(userId);
    return status.isActive;
  }

  /**
   * Check if user can start a new exercise (respects daily limits)
   */
  async canStartExercise(userId: string, timezone = 'UTC'): Promise<boolean> {
    // Premium users have unlimited access
    const hasPremium = await this.hasPremiumAccess(userId);
    if (hasPremium) {
      return true;
    }

    // Check daily limit for free users (3 exercises per day)
    const today = await this.dailyUsageService.getTodayUsage(userId, timezone);
    return today.exerciseCount < 3;
  }

  /**
   * Record exercise completion
   */
  async recordExerciseCompletion(userId: string, timezone = 'UTC'): Promise<void> {
    await this.dailyUsageService.incrementUsage(userId, timezone);
  }

  /**
   * Get user's current subscription
   */
  async getUserSubscription(userId: string) {
    return this.prisma.subscription.findUnique({
      where: { userId },
      include: {
        paymentTransactions: {
          orderBy: { createdAt: 'desc' },
          take: 10,
        },
      },
    });
  }

  /**
   * Verify Google Play subscription
   */
  async verifyGooglePlayPurchase(productId: string, purchaseToken: string): Promise<any> {
    return this.googlePlayService.verifyPurchase(productId, purchaseToken);
  }

  /**
   * Clean up expired subscriptions (cron job)
   */
  async processExpiredSubscriptions(): Promise<void> {
    const now = new Date();

    // Find expired premium subscriptions
    const expiredSubscriptions = await this.prisma.subscription.findMany({
      where: {
        status: 'ACTIVE',
        endDate: {
          lt: now,
        },
      },
      include: { user: true },
    });

    // Update expired subscriptions
    for (const subscription of expiredSubscriptions) {
      await this.prisma.$transaction(async (tx) => {
        // Update subscription status
        await tx.subscription.update({
          where: { id: subscription.id },
          data: { status: 'EXPIRED' },
        });

        // Update user status to free
        await tx.user.update({
          where: { id: subscription.userId },
          data: {
            subscriptionTier: 'FREE',
            subscriptionStatus: 'EXPIRED',
          },
        });
      });
    }
  }
}