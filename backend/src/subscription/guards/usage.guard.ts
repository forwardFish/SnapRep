import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { SubscriptionService } from '../subscription.service.temp';

@Injectable()
export class UsageGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private subscriptionService: SubscriptionService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Check if the endpoint requires usage validation
    const checksUsageLimit = this.reflector.get<boolean>('checksUsageLimit', context.getHandler());

    if (!checksUsageLimit) {
      return true; // No usage limit check required
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('User authentication required');
    }

    const timezone = request.body?.timezone || request.query?.timezone || 'UTC';

    // Check if user can start a new exercise
    const canStart = await this.subscriptionService.canStartExercise(user.id, timezone);

    if (!canStart) {
      const hasPremium = await this.subscriptionService.hasPremiumAccess(user.id);

      if (hasPremium) {
        // Premium user but still can't start - might be a different issue
        throw new ForbiddenException({
          message: 'Unable to start exercise',
          code: 'EXERCISE_BLOCKED',
        });
      } else {
        // Free user has reached daily limit
        throw new ForbiddenException({
          message: 'Daily exercise limit reached',
          code: 'DAILY_LIMIT_REACHED',
          limit: 3,
          upgradeMessage: 'Upgrade to Premium for unlimited daily exercises',
          upgradeUrl: '/subscription',
          features: [
            'Unlimited daily exercises',
            'Premium workout plans',
            'Advanced analytics',
          ],
        });
      }
    }

    return true;
  }
}