import { SetMetadata } from '@nestjs/common';

/**
 * Decorator to mark endpoints that require premium subscription
 * Use with SubscriptionGuard
 */
export const RequiresPremium = () => SetMetadata('requiresPremium', true);

/**
 * Decorator to mark endpoints that should check daily usage limits
 * Use with UsageGuard
 */
export const ChecksUsageLimit = () => SetMetadata('checksUsageLimit', true);

/**
 * Decorator to mark endpoints that require both premium access and usage validation
 */
export const RequiresPremiumOrUsageCheck = () => {
  return (target: any, propertyKey: string, descriptor: PropertyDescriptor) => {
    SetMetadata('requiresPremium', false)(target, propertyKey, descriptor);
    SetMetadata('checksUsageLimit', true)(target, propertyKey, descriptor);
    return descriptor;
  };
};