import { Injectable, CanActivate, ExecutionContext, ForbiddenException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { SubscriptionService } from '../subscription.service';

@Injectable()
export class SubscriptionGuard implements CanActivate {
  constructor(
    private reflector: Reflector,
    private subscriptionService: SubscriptionService,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    // Check if the endpoint requires premium access
    const requiresPremium = this.reflector.get<boolean>('requiresPremium', context.getHandler());

    if (!requiresPremium) {
      return true; // No premium requirement
    }

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (!user) {
      throw new ForbiddenException('User authentication required');
    }

    // Check if user has premium access
    const hasPremiumAccess = await this.subscriptionService.hasPremiumAccess(user.id);

    if (!hasPremiumAccess) {
      throw new ForbiddenException({
        message: 'Premium subscription required',
        code: 'PREMIUM_REQUIRED',
        upgradeUrl: '/subscription',
        features: [
          'Unlimited daily exercises',
          'Premium workout plans',
          'Advanced analytics',
          'Priority support',
        ],
      });
    }

    return true;
  }
}