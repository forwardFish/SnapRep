import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
  HttpStatus,
  Logger,
  Query,
  UseFilters,
  ValidationPipe,
  UsePipes,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiQuery } from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { SubscriptionService, CreateSubscriptionDto } from './subscription.service';
import { DailyUsageService } from './daily-usage.service';
import { ResponseError } from '../exception/response-error';
import { ErrorCodes } from '../exception/error-codes';
import { ResponseErrorFilter } from '../exception/response-error.filter';

export class StartTrialDto {
  timezone?: string;
}

export class VerifyPurchaseDto {
  productId: string;
  purchaseToken: string;
  orderId?: string;
  actualPrice: number;
  originalPrice: number;
  tier: 'PREMIUM' | 'PREMIUM_YEARLY';
  currency?: string;
}

export class RecordExerciseDto {
  timezone?: string;
}

export class CancelSubscriptionDto {
  reason?: string;
}

/**
 * SubscriptionController
 * 提供订阅相关的REST API接口
 * 使用 SupabaseApiService 绕过 Prisma 连接问题
 */
@ApiTags('Subscription')
@Controller('subscription')
@UseFilters(ResponseErrorFilter)
@UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
export class SubscriptionController {
  private readonly logger = new Logger(SubscriptionController.name);

  constructor(
    private readonly subscriptionService: SubscriptionService,
    private readonly dailyUsageService: DailyUsageService,
  ) {
    this.logger.log('✅ SubscriptionController initialized');
  }

  /**
   * 获取用户订阅状态
   * GET /subscription/status
   */
  @Get('status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user subscription status' })
  @ApiResponse({ status: 200, description: 'Subscription status retrieved successfully' })
  @ApiQuery({ name: 'timezone', required: false, description: 'User timezone (e.g., Asia/Shanghai)' })
  async getStatus(@Request() req, @Query('timezone') timezone?: string) {
    try {
      const userId = req.user.id;
      const userTimezone = timezone || 'UTC';

      this.logger.debug(`Getting subscription status for user ${userId}`);

      // 获取订阅状态
      const status = await this.subscriptionService.getSubscriptionStatus(userId);

      // 获取每日使用统计
      const dailyUsage = await this.dailyUsageService.getTodayUsage(userId, userTimezone);

      // 获取本周统计
      const weeklySummary = await this.dailyUsageService.getWeeklySummary(userId, userTimezone);

      // 检查是否可以开始训练
      const canStartExercise = status.hasAccess
        ? true
        : !(await this.dailyUsageService.hasReachedDailyLimit(userId, userTimezone));

      return {
        statusCode: HttpStatus.OK,
        data: {
          subscription: status,
          dailyUsage: {
            exercisesUsed: dailyUsage.exerciseCount,
            exerciseLimit: status.hasAccess ? null : 3,
            canStartExercise,
            resetAt: dailyUsage.resetAt,
          },
          weeklySummary,
        },
      };
    } catch (error) {
      this.logger.error('Failed to get subscription status:', error);
      if (error instanceof ResponseError) {
        throw error;
      }
      throw new ResponseError(ErrorCodes.SUBSCRIPTION.FETCH_FAILED);
    }
  }

  /**
   * 开始免费试用
   * POST /subscription/trial/start
   */
  @Post('trial/start')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Start free trial' })
  @ApiResponse({ status: 200, description: 'Free trial started successfully' })
  @ApiResponse({ status: 400, description: 'Trial already used or active subscription exists' })
  async startTrial(@Request() req, @Body() body: StartTrialDto) {
    try {
      const userId = req.user.id;

      this.logger.log(`User ${userId} starting free trial`);

      await this.subscriptionService.startFreeTrial(userId);

      const trialDays = parseInt(process.env.FREE_TRIAL_DAYS || '7');
      const trialEndsAt = new Date(Date.now() + trialDays * 24 * 60 * 60 * 1000);

      return {
        statusCode: HttpStatus.OK,
        message: 'Free trial started successfully',
        data: {
          trialDuration: `${trialDays} days`,
          trialEndsAt,
        },
      };
    } catch (error) {
      this.logger.error('Failed to start trial:', error);
      if (error instanceof ResponseError) {
        throw error;
      }
      throw new ResponseError(ErrorCodes.SUBSCRIPTION.CREATE_FAILED);
    }
  }

  /**
   * 验证并创建订阅(Google Play 购买)
   * POST /subscription/verify
   */
  @Post('verify')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Verify and create subscription from Google Play purchase' })
  @ApiResponse({ status: 200, description: 'Subscription created successfully' })
  @ApiResponse({ status: 400, description: 'Invalid purchase or subscription already exists' })
  async verifyPurchase(@Request() req, @Body() body: VerifyPurchaseDto) {
    try {
      const userId = req.user.id;

      this.logger.log(`User ${userId} verifying purchase for tier ${body.tier}`);

      // 验证必填字段
      if (!body.productId || !body.purchaseToken) {
        throw new ResponseError(ErrorCodes.SUBSCRIPTION.INVALID_PURCHASE_TOKEN);
      }

      if (!body.tier || !['PREMIUM', 'PREMIUM_YEARLY'].includes(body.tier)) {
        throw new ResponseError(ErrorCodes.SUBSCRIPTION.INVALID_TIER);
      }

      // 创建订阅
      const subscription = await this.subscriptionService.createSubscription({
        userId,
        tier: body.tier,
        purchaseToken: body.purchaseToken,
        orderId: body.orderId,
        productId: body.productId,
        actualPrice: body.actualPrice,
        originalPrice: body.originalPrice,
        currency: body.currency || 'USD',
      });

      return {
        statusCode: HttpStatus.OK,
        message: 'Subscription created successfully',
        data: {
          subscriptionId: subscription.id,
          tier: subscription.tier,
          startDate: subscription.start_date,
          endDate: subscription.end_date,
          status: 'active',
        },
      };
    } catch (error) {
      this.logger.error('Failed to verify purchase:', error);
      if (error instanceof ResponseError) {
        throw error;
      }
      throw new ResponseError(ErrorCodes.SUBSCRIPTION.CREATE_FAILED);
    }
  }

  /**
   * 取消订阅
   * POST /subscription/cancel
   */
  @Post('cancel')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Cancel subscription' })
  @ApiResponse({ status: 200, description: 'Subscription canceled successfully' })
  @ApiResponse({ status: 404, description: 'No active subscription found' })
  async cancelSubscription(@Request() req, @Body() body: CancelSubscriptionDto) {
    try {
      const userId = req.user.id;

      this.logger.log(`User ${userId} canceling subscription`);

      await this.subscriptionService.cancelSubscription(userId, body.reason);

      return {
        statusCode: HttpStatus.OK,
        message: 'Subscription canceled successfully',
        data: {
          note: 'Your premium access will continue until the end of your current billing period',
        },
      };
    } catch (error) {
      this.logger.error('Failed to cancel subscription:', error);
      if (error instanceof ResponseError) {
        throw error;
      }
      throw new ResponseError(ErrorCodes.SUBSCRIPTION.CANCEL_FAILED);
    }
  }

  /**
   * 获取订阅详情
   * GET /subscription/details
   */
  @Get('details')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get detailed subscription information' })
  @ApiResponse({ status: 200, description: 'Subscription details retrieved successfully' })
  async getDetails(@Request() req) {
    try {
      const userId = req.user.id;

      this.logger.debug(`Getting subscription details for user ${userId}`);

      const subscription = await this.subscriptionService.getUserSubscription(userId);

      if (!subscription) {
        return {
          statusCode: HttpStatus.OK,
          data: {
            subscription: null,
            message: 'No active subscription found',
          },
        };
      }

      return {
        statusCode: HttpStatus.OK,
        data: {
          subscription: {
            id: subscription.id,
            tier: subscription.tier,
            status: subscription.status,
            startDate: subscription.start_date,
            endDate: subscription.end_date,
            willRenew: subscription.will_renew,
            platform: subscription.payment_platform,
            currency: subscription.currency,
            actualPrice: subscription.actual_price,
            isTrialUsed: subscription.is_trial_used,
          },
        },
      };
    } catch (error) {
      this.logger.error('Failed to get subscription details:', error);
      if (error instanceof ResponseError) {
        throw error;
      }
      throw new ResponseError(ErrorCodes.SUBSCRIPTION.FETCH_FAILED);
    }
  }

  /**
   * 记录训练完成(用于每日限制统计)
   * POST /subscription/exercise/record
   *
   * ⚠️ 注意: 这个接口已废弃,建议使用 /daily-usage/record-exercise
   */
  @Post('exercise/record')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: '[DEPRECATED] Record exercise completion for daily usage tracking' })
  @ApiResponse({ status: 200, description: 'Exercise recorded successfully' })
  @ApiResponse({ status: 403, description: 'Daily exercise limit reached' })
  async recordExercise(@Request() req, @Body() body: RecordExerciseDto) {
    try {
      const userId = req.user.id;
      const timezone = body.timezone || 'UTC';

      this.logger.debug(`Recording exercise for user ${userId}`);

      // 检查用户是否可以开始训练
      const hasPremium = await this.subscriptionService.hasPremiumAccess(userId);

      if (!hasPremium) {
        const hasReachedLimit = await this.dailyUsageService.hasReachedDailyLimit(userId, timezone);
        if (hasReachedLimit) {
          throw new ResponseError(ErrorCodes.SUBSCRIPTION.DAILY_LIMIT_REACHED);
        }
      }

      // 增加使用计数
      const updatedUsage = await this.dailyUsageService.incrementUsage(userId, timezone);

      return {
        statusCode: HttpStatus.OK,
        message: 'Exercise recorded successfully',
        data: {
          exercisesCompletedToday: updatedUsage.exerciseCount,
          remainingExercises: hasPremium ? null : Math.max(0, 3 - updatedUsage.exerciseCount),
          resetAt: updatedUsage.resetAt,
        },
      };
    } catch (error) {
      this.logger.error('Failed to record exercise:', error);
      if (error instanceof ResponseError) {
        throw error;
      }
      throw new ResponseError(ErrorCodes.DAILY_USAGE.UPDATE_FAILED);
    }
  }

  /**
   * 检查用户是否可以开始训练
   * GET /subscription/usage/check
   */
  @Get('usage/check')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Check if user can start exercise (respects daily limits)' })
  @ApiResponse({ status: 200, description: 'Usage check completed' })
  @ApiQuery({ name: 'timezone', required: false, description: 'User timezone' })
  async checkUsage(@Request() req, @Query('timezone') timezone?: string) {
    try {
      const userId = req.user.id;
      const userTimezone = timezone || 'UTC';

      this.logger.debug(`Checking usage for user ${userId}`);

      const hasPremium = await this.subscriptionService.hasPremiumAccess(userId);
      const dailyUsage = await this.dailyUsageService.getTodayUsage(userId, userTimezone);
      const hasReachedLimit = await this.dailyUsageService.hasReachedDailyLimit(userId, userTimezone);

      const canStartExercise = hasPremium || !hasReachedLimit;

      return {
        statusCode: HttpStatus.OK,
        data: {
          canStartExercise,
          hasPremiumAccess: hasPremium,
          exercisesUsedToday: dailyUsage.exerciseCount,
          exerciseLimit: hasPremium ? null : 3,
          remainingExercises: hasPremium ? null : Math.max(0, 3 - dailyUsage.exerciseCount),
          resetAt: dailyUsage.resetAt,
          upgradeRequired: !canStartExercise,
        },
      };
    } catch (error) {
      this.logger.error('Failed to check usage:', error);
      if (error instanceof ResponseError) {
        throw error;
      }
      throw new ResponseError(ErrorCodes.DAILY_USAGE.FETCH_FAILED);
    }
  }

  /**
   * 获取训练使用历史
   * GET /subscription/usage/history
   */
  @Get('usage/history')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get exercise usage history' })
  @ApiResponse({ status: 200, description: 'Usage history retrieved successfully' })
  @ApiQuery({ name: 'days', required: false, description: 'Number of days to query (default: 30)' })
  async getUsageHistory(@Request() req, @Query('days') days?: string) {
    try {
      const userId = req.user.id;
      const queryDays = days ? parseInt(days) : 30;

      this.logger.debug(`Getting usage history for user ${userId}, last ${queryDays} days`);

      const history = await this.dailyUsageService.getUsageHistory(userId, queryDays);

      return {
        statusCode: HttpStatus.OK,
        data: {
          history,
          summary: {
            totalDays: history.length,
            totalExercises: history.reduce((sum, record) => sum + record.exerciseCount, 0),
            averagePerDay: history.length > 0
              ? Math.round((history.reduce((sum, record) => sum + record.exerciseCount, 0) / history.length) * 10) / 10
              : 0,
          },
        },
      };
    } catch (error) {
      this.logger.error('Failed to get usage history:', error);
      if (error instanceof ResponseError) {
        throw error;
      }
      throw new ResponseError(ErrorCodes.DAILY_USAGE.FETCH_FAILED);
    }
  }
}
