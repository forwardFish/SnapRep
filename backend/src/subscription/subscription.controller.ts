import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
  BadRequestException,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth } from '@nestjs/swagger';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { SubscriptionService, CreateSubscriptionDto } from './subscription.service.temp';
import { DailyUsageService } from './daily-usage.service.temp';

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

@ApiTags('Subscription')
@Controller('subscription')
export class SubscriptionController {
  constructor(
    private subscriptionService: SubscriptionService,
    private dailyUsageService: DailyUsageService,
  ) {}

  @Get('status')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get user subscription status' })
  @ApiResponse({ status: 200, description: 'Subscription status retrieved successfully' })
  async getStatus(@Request() req) {
    const userId = req.user.id;
    const status = await this.subscriptionService.getSubscriptionStatus(userId);

    // Also get daily usage info
    const dailyUsage = await this.dailyUsageService.getTodayUsage(userId, req.body.timezone);
    const weeklySummary = await this.dailyUsageService.getWeeklySummary(userId, req.body.timezone);

    return {
      statusCode: HttpStatus.OK,
      data: {
        subscription: status,
        dailyUsage: {
          exercisesUsed: dailyUsage.exerciseCount,
          exerciseLimit: status.isActive ? null : 3, // Premium users have no limit
          canStartExercise: await this.subscriptionService.canStartExercise(userId),
        },
        weeklySummary,
      },
    };
  }

  @Post('trial/start')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Start free trial' })
  @ApiResponse({ status: 200, description: 'Free trial started successfully' })
  async startTrial(@Request() req, @Body() body: StartTrialDto) {
    const userId = req.user.id;

    await this.subscriptionService.startFreeTrial(userId);

    return {
      statusCode: HttpStatus.OK,
      message: 'Free trial started successfully',
      data: {
        trialDuration: '7 days',
        trialEndsAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    };
  }

  @Post('verify')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Verify and create subscription from Google Play purchase' })
  @ApiResponse({ status: 200, description: 'Subscription created successfully' })
  async verifyPurchase(@Request() req, @Body() body: VerifyPurchaseDto) {
    const userId = req.user.id;

    // Validate required fields
    if (!body.productId || !body.purchaseToken) {
      throw new BadRequestException('Product ID and purchase token are required');
    }

    if (!body.tier || !['PREMIUM', 'PREMIUM_YEARLY'].includes(body.tier)) {
      throw new BadRequestException('Valid subscription tier is required');
    }

    // Create subscription
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
        expiresAt: subscription.endDate,
        trialStatus: 'premium_active',
      },
    };
  }

  @Post('cancel')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Cancel subscription' })
  @ApiResponse({ status: 200, description: 'Subscription canceled successfully' })
  async cancelSubscription(@Request() req, @Body() body: CancelSubscriptionDto) {
    const userId = req.user.id;

    await this.subscriptionService.cancelSubscription(userId, body.reason);

    return {
      statusCode: HttpStatus.OK,
      message: 'Subscription canceled successfully',
      data: {
        note: 'Your premium access will continue until the end of your current billing period',
      },
    };
  }

  @Get('details')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get detailed subscription information' })
  @ApiResponse({ status: 200, description: 'Subscription details retrieved successfully' })
  async getDetails(@Request() req) {
    const userId = req.user.id;
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
          startDate: subscription.startDate,
          endDate: subscription.endDate,
          willRenew: subscription.willRenew,
          platform: subscription.paymentPlatform,
          currency: subscription.currency,
          actualPrice: subscription.actualPrice,
        },
        recentTransactions: subscription.paymentTransactions.map(tx => ({
          id: tx.id,
          amount: tx.amount,
          currency: tx.currency,
          status: tx.status,
          processedAt: tx.processedAt,
        })),
      },
    };
  }

  @Post('exercise/record')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Record exercise completion for daily usage tracking' })
  @ApiResponse({ status: 200, description: 'Exercise recorded successfully' })
  async recordExercise(@Request() req, @Body() body: RecordExerciseDto) {
    const userId = req.user.id;
    const timezone = body.timezone || 'UTC';

    // Check if user can start exercise before recording
    const canStart = await this.subscriptionService.canStartExercise(userId, timezone);
    if (!canStart) {
      throw new BadRequestException('Daily exercise limit reached. Upgrade to premium for unlimited access.');
    }

    await this.subscriptionService.recordExerciseCompletion(userId, timezone);

    const updatedUsage = await this.dailyUsageService.getTodayUsage(userId, timezone);

    return {
      statusCode: HttpStatus.OK,
      message: 'Exercise recorded successfully',
      data: {
        exercisesCompletedToday: updatedUsage.exerciseCount,
        remainingExercises: Math.max(0, 3 - updatedUsage.exerciseCount),
        resetAt: updatedUsage.resetAt,
      },
    };
  }

  @Get('usage/check')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Check if user can start exercise (respects daily limits)' })
  @ApiResponse({ status: 200, description: 'Usage check completed' })
  async checkUsage(@Request() req) {
    const userId = req.user.id;
    const timezone = req.query.timezone as string || 'UTC';

    const canStart = await this.subscriptionService.canStartExercise(userId, timezone);
    const hasPremium = await this.subscriptionService.hasPremiumAccess(userId);
    const dailyUsage = await this.dailyUsageService.getTodayUsage(userId, timezone);

    return {
      statusCode: HttpStatus.OK,
      data: {
        canStartExercise: canStart,
        hasPremiumAccess: hasPremium,
        exercisesUsedToday: dailyUsage.exerciseCount,
        exerciseLimit: hasPremium ? null : 3,
        remainingExercises: hasPremium ? null : Math.max(0, 3 - dailyUsage.exerciseCount),
        resetAt: dailyUsage.resetAt,
        upgradeRequired: !canStart && !hasPremium,
      },
    };
  }

  @Get('usage/history')
  @UseGuards(JwtAuthGuard)
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Get exercise usage history' })
  @ApiResponse({ status: 200, description: 'Usage history retrieved successfully' })
  async getUsageHistory(@Request() req) {
    const userId = req.user.id;
    const days = parseInt(req.query.days as string) || 30;

    const history = await this.dailyUsageService.getUsageHistory(userId, days);

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
  }
}