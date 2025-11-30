import { Injectable, Logger } from '@nestjs/common';
import { SupabaseApiService } from '../common/services/supabase-api.service';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';

export enum SubscriptionTier {
  FREE = 'FREE',
  PREMIUM = 'PREMIUM',
  PREMIUM_YEARLY = 'PREMIUM_YEARLY',
}

export enum SubscriptionStatus {
  ACTIVE = 'ACTIVE',
  CANCELED = 'CANCELED',
  EXPIRED = 'EXPIRED',
  PENDING = 'PENDING',
  TRIAL = 'TRIAL',
}

export enum PaymentPlatform {
  GOOGLE_PLAY = 'GOOGLE_PLAY',
  APPLE_STORE = 'APPLE_STORE',
  PAYPAL = 'PAYPAL',
  STRIPE = 'STRIPE',
}

export interface CreateSubscriptionDto {
  userId: string;
  tier: string;
  purchaseToken?: string;
  orderId?: string;
  productId?: string;
  actualPrice?: number;
  originalPrice?: number;
  currency?: string;
}

export interface SubscriptionStatusResponse {
  isActive: boolean;
  tier: SubscriptionTier;
  status: SubscriptionStatus;
  isTrialActive: boolean;
  canStartTrial: boolean;
  hasUsedTrial: boolean;
  isPremiumUser: boolean;
  hasAccess: boolean;
  startDate?: Date;
  endDate?: Date;
  willRenew?: boolean;
  platform?: PaymentPlatform;
}

/**
 * SubscriptionService
 * 订阅管理服务 - 使用 SupabaseApiService 直接操作数据库
 * 绕过 Prisma 连接问题
 */
@Injectable()
export class SubscriptionService {
  private readonly logger = new Logger(SubscriptionService.name);
  private readonly FREE_DAILY_LIMIT = parseInt(process.env.FREE_DAILY_EXERCISE_LIMIT || '3');
  private readonly TRIAL_DAYS = parseInt(process.env.FREE_TRIAL_DAYS || '7');

  constructor(private readonly supabaseApi: SupabaseApiService) {
    this.logger.log('✅ SubscriptionService initialized with SupabaseApiService');
  }

  /**
   * 获取用户订阅状态
   * @param userId 用户ID
   */
  async getSubscriptionStatus(userId: string): Promise<SubscriptionStatusResponse> {
    try {
      this.logger.debug(`Getting subscription status for user: ${userId}`);

      // 查询用户的活跃订阅
      const subscriptions = await this.supabaseApi.get('subscriptions', {
        user_id: userId,
        status: 'in.(ACTIVE,TRIAL)',
      });

      // 没有活跃订阅 - 免费用户
      if (!subscriptions || subscriptions.length === 0) {
        this.logger.debug(`No active subscription found for user ${userId}`);

        // 检查用户是否使用过试用
        const trialUsed = await this.hasUsedTrial(userId);

        return {
          isActive: false,
          tier: SubscriptionTier.FREE,
          status: SubscriptionStatus.EXPIRED,
          isTrialActive: false,
          canStartTrial: !trialUsed,
          hasUsedTrial: trialUsed,
          isPremiumUser: false,
          hasAccess: false,
        };
      }

      const subscription = subscriptions[0];
      const now = new Date();
      const endDate = new Date(subscription.end_date);
      const isTrial = subscription.status === 'TRIAL';
      const isExpired = endDate < now;

      // 订阅已过期
      if (isExpired) {
        // 更新订阅状态为过期
        await this.supabaseApi.update(
          'subscriptions',
          subscription.id,
          { status: 'EXPIRED' },
        );

        const trialUsed = await this.hasUsedTrial(userId);

        return {
          isActive: false,
          tier: SubscriptionTier.FREE,
          status: SubscriptionStatus.EXPIRED,
          isTrialActive: false,
          canStartTrial: !trialUsed,
          hasUsedTrial: trialUsed,
          isPremiumUser: false,
          hasAccess: false,
          endDate: subscription.end_date,
        };
      }

      // 订阅活跃
      const isPremium = subscription.tier === 'PREMIUM' || subscription.tier === 'PREMIUM_YEARLY';

      return {
        isActive: true,
        tier: subscription.tier,
        status: subscription.status,
        isTrialActive: isTrial,
        canStartTrial: false,
        hasUsedTrial: true,
        isPremiumUser: isPremium,
        hasAccess: true,
        startDate: subscription.start_date,
        endDate: subscription.end_date,
        willRenew: subscription.will_renew,
        platform: subscription.payment_platform,
      };
    } catch (error) {
      this.logger.error(`Failed to get subscription status for user ${userId}:`, error);
      throw new ResponseError(ErrorCodes.SUBSCRIPTION.FETCH_FAILED);
    }
  }

  /**
   * 检查用户是否可以开始训练
   * @param userId 用户ID
   * @param timezone 用户时区(可选)
   */
  async canStartExercise(userId: string, timezone?: string): Promise<boolean> {
    try {
      const status = await this.getSubscriptionStatus(userId);

      // Premium 或试用期用户可以无限训练
      if (status.hasAccess) {
        return true;
      }

      // 免费用户需要检查每日限制
      // 这个逻辑将由 DailyUsageService 处理
      // 这里先返回 true,后续会在 controller 层调用 DailyUsageService 检查
      return true;
    } catch (error) {
      this.logger.error(`Failed to check exercise permission for user ${userId}:`, error);
      return false;
    }
  }

  /**
   * 开始免费试用
   * @param userId 用户ID
   */
  async startFreeTrial(userId: string): Promise<void> {
    try {
      this.logger.log(`Starting free trial for user: ${userId}`);

      // 1. 检查用户是否存在
      const users = await this.supabaseApi.get('users', { id: userId });
      if (!users || users.length === 0) {
        this.logger.error(`User not found: ${userId}`);
        throw new ResponseError(ErrorCodes.SUBSCRIPTION.USER_NOT_FOUND);
      }

      // 2. 检查是否已经使用过试用
      const hasUsed = await this.hasUsedTrial(userId);
      if (hasUsed) {
        this.logger.warn(`User ${userId} has already used trial`);
        throw new ResponseError(ErrorCodes.SUBSCRIPTION.TRIAL_ALREADY_USED);
      }

      // 3. 检查是否有活跃的订阅
      const activeSubscriptions = await this.supabaseApi.get('subscriptions', {
        user_id: userId,
        status: 'in.(ACTIVE,TRIAL)',
      });

      if (activeSubscriptions && activeSubscriptions.length > 0) {
        this.logger.warn(`User ${userId} already has an active subscription`);
        throw new ResponseError(ErrorCodes.SUBSCRIPTION.TRIAL_ALREADY_STARTED);
      }

      // 4. 创建试用订阅
      const now = new Date();
      const endDate = new Date(now.getTime() + this.TRIAL_DAYS * 24 * 60 * 60 * 1000);

      const trialSubscription = {
        user_id: userId,
        tier: SubscriptionTier.PREMIUM,
        status: SubscriptionStatus.TRIAL,
        start_date: now.toISOString(),
        end_date: endDate.toISOString(),
        trial_start_date: now.toISOString(),
        trial_end_date: endDate.toISOString(),
        is_trial_used: true,
        will_renew: false,
        payment_platform: null,
        purchase_token: null,
        order_id: null,
        product_id: 'trial_7_days',
        actual_price: 0,
        original_price: 0,
        currency: 'USD',
      };

      const created = await this.supabaseApi.create('subscriptions', trialSubscription);

      if (!created) {
        this.logger.error(`Failed to create trial subscription for user ${userId}`);
        throw new ResponseError(ErrorCodes.SUBSCRIPTION.CREATE_FAILED);
      }

      this.logger.log(`✅ Free trial started successfully for user ${userId}, expires at ${endDate}`);
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`Failed to start free trial for user ${userId}:`, error);
      throw new ResponseError(ErrorCodes.SUBSCRIPTION.CREATE_FAILED);
    }
  }

  /**
   * 创建订阅(通过 Google Play 购买验证)
   * @param dto 订阅创建DTO
   */
  async createSubscription(dto: CreateSubscriptionDto): Promise<any> {
    try {
      this.logger.log(`Creating subscription for user: ${dto.userId}, tier: ${dto.tier}`);

      // 1. 检查用户是否存在
      const users = await this.supabaseApi.get('users', { id: dto.userId });
      if (!users || users.length === 0) {
        throw new ResponseError(ErrorCodes.SUBSCRIPTION.USER_NOT_FOUND);
      }

      // 2. 检查是否已有活跃订阅
      const activeSubscriptions = await this.supabaseApi.get('subscriptions', {
        user_id: dto.userId,
        status: 'in.(ACTIVE,TRIAL)',
      });

      if (activeSubscriptions && activeSubscriptions.length > 0) {
        // 取消之前的试用订阅
        const oldSubscription = activeSubscriptions[0];
        if (oldSubscription.status === 'TRIAL') {
          await this.supabaseApi.update(
            'subscriptions',
            oldSubscription.id,
            { status: 'CANCELED', will_renew: false },
          );
          this.logger.log(`Canceled trial subscription ${oldSubscription.id} for user ${dto.userId}`);
        } else {
          // 如果已有付费订阅,抛出错误
          throw new ResponseError(ErrorCodes.SUBSCRIPTION.ALREADY_EXISTS);
        }
      }

      // 3. 计算订阅结束日期
      const now = new Date();
      let endDate: Date;

      if (dto.tier === SubscriptionTier.PREMIUM_YEARLY) {
        endDate = new Date(now.getTime() + 365 * 24 * 60 * 60 * 1000);
      } else {
        endDate = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
      }

      // 4. 创建订阅记录
      const subscriptionData = {
        user_id: dto.userId,
        tier: dto.tier,
        status: SubscriptionStatus.ACTIVE,
        start_date: now.toISOString(),
        end_date: endDate.toISOString(),
        renews_at: endDate.toISOString(),
        will_renew: true,
        payment_platform: PaymentPlatform.GOOGLE_PLAY,
        purchase_token: dto.purchaseToken,
        order_id: dto.orderId,
        product_id: dto.productId,
        actual_price: dto.actualPrice || 0,
        original_price: dto.originalPrice || 0,
        currency: dto.currency || 'USD',
        is_trial_used: false,
      };

      const created = await this.supabaseApi.create('subscriptions', subscriptionData);

      if (!created) {
        throw new ResponseError(ErrorCodes.SUBSCRIPTION.CREATE_FAILED);
      }

      this.logger.log(`✅ Subscription created successfully: ${created.id}`);

      return created;
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`Failed to create subscription for user ${dto.userId}:`, error);
      throw new ResponseError(ErrorCodes.SUBSCRIPTION.CREATE_FAILED);
    }
  }

  /**
   * 取消订阅
   * @param userId 用户ID
   * @param reason 取消原因
   */
  async cancelSubscription(userId: string, reason?: string): Promise<void> {
    try {
      this.logger.log(`Canceling subscription for user: ${userId}`);

      // 查询活跃订阅
      const subscriptions = await this.supabaseApi.get('subscriptions', {
        user_id: userId,
        status: 'in.(ACTIVE,TRIAL)',
      });

      if (!subscriptions || subscriptions.length === 0) {
        throw new ResponseError(ErrorCodes.SUBSCRIPTION.NOT_FOUND);
      }

      const subscription = subscriptions[0];

      // 更新订阅状态
      await this.supabaseApi.update(
        'subscriptions',
        subscription.id,
        {
          status: SubscriptionStatus.CANCELED,
          will_renew: false,
          cancel_reason: reason || null,
          canceled_at: new Date().toISOString(),
        },
      );

      this.logger.log(`✅ Subscription canceled successfully for user ${userId}`);
    } catch (error) {
      if (error instanceof ResponseError) {
        throw error;
      }
      this.logger.error(`Failed to cancel subscription for user ${userId}:`, error);
      throw new ResponseError(ErrorCodes.SUBSCRIPTION.CANCEL_FAILED);
    }
  }

  /**
   * 获取用户订阅详情
   * @param userId 用户ID
   */
  async getUserSubscription(userId: string): Promise<any> {
    try {
      const subscriptions = await this.supabaseApi.get('subscriptions', {
        user_id: userId,
        status: 'in.(ACTIVE,TRIAL)',
      });

      if (!subscriptions || subscriptions.length === 0) {
        return null;
      }

      return subscriptions[0];
    } catch (error) {
      this.logger.error(`Failed to get subscription for user ${userId}:`, error);
      throw new ResponseError(ErrorCodes.SUBSCRIPTION.FETCH_FAILED);
    }
  }

  /**
   * 检查用户是否有高级访问权限
   * @param userId 用户ID
   */
  async hasPremiumAccess(userId: string): Promise<boolean> {
    try {
      const status = await this.getSubscriptionStatus(userId);
      return status.hasAccess;
    } catch (error) {
      this.logger.error(`Failed to check premium access for user ${userId}:`, error);
      return false;
    }
  }

  /**
   * 记录训练完成(更新每日使用统计)
   * @param userId 用户ID
   * @param timezone 用户时区
   */
  async recordExerciseCompletion(userId: string, timezone?: string): Promise<void> {
    // 这个方法将在 DailyUsageService 中实现
    // 这里只是一个占位符,保持接口一致性
    this.logger.debug(`Recording exercise completion for user ${userId}`);
  }

  /**
   * 检查用户是否使用过试用
   * @param userId 用户ID
   */
  private async hasUsedTrial(userId: string): Promise<boolean> {
    try {
      // 查询该用户的所有订阅记录,检查 is_trial_used 字段
      const allSubscriptions = await this.supabaseApi.get('subscriptions', {
        user_id: userId,
      });

      if (!allSubscriptions || allSubscriptions.length === 0) {
        return false;
      }

      // 如果有任何订阅记录标记为已使用试用,则返回 true
      return allSubscriptions.some((sub: any) => sub.is_trial_used === true);
    } catch (error) {
      this.logger.error(`Failed to check trial usage for user ${userId}:`, error);
      // 发生错误时,为了安全起见,假设已使用过试用
      return true;
    }
  }
}
