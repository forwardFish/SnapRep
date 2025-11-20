# SnapRep Subscription System

A comprehensive subscription system for SnapRep app with Google Play Billing integration, free trial management, and daily exercise limits.

## Features

- **Google Play Billing Integration**: Full support for subscription verification and management
- **Free Trial System**: 7-day free trial for new users
- **Daily Exercise Limits**: 3 exercises per day for free users, unlimited for premium
- **Subscription Tiers**: Monthly ($4.99) and Yearly ($29.99) plans
- **Automatic Expiration Handling**: Background tasks to process expired subscriptions
- **Usage Analytics**: Track user exercise patterns and subscription metrics

## Architecture

### Database Schema

The subscription system adds the following tables to the existing SnapRep database:

1. **subscriptions**: Main subscription records with Google Play integration
2. **payment_transactions**: Transaction history and verification data
3. **daily_usage**: Daily exercise usage tracking for free tier limits

### Services

- **SubscriptionService**: Core subscription management logic
- **DailyUsageService**: Exercise usage tracking and limits
- **GooglePlayService**: Google Play purchase verification
- **SubscriptionTasksService**: Background tasks for maintenance

### Guards and Decorators

- **SubscriptionGuard**: Protects premium-only endpoints
- **UsageGuard**: Enforces daily exercise limits for free users
- **@RequiresPremium()**: Decorator for premium endpoints
- **@ChecksUsageLimit()**: Decorator for usage limit checking

## API Endpoints

### Subscription Management

```http
GET    /subscription/status           # Get subscription status
POST   /subscription/trial/start      # Start free trial
POST   /subscription/verify           # Verify Google Play purchase
POST   /subscription/cancel           # Cancel subscription
GET    /subscription/details          # Get detailed subscription info
```

### Usage Tracking

```http
POST   /subscription/exercise/record  # Record exercise completion
GET    /subscription/usage/check      # Check if user can start exercise
GET    /subscription/usage/history    # Get usage history
```

## Usage Examples

### Protecting Premium Endpoints

```typescript
@Get('premium-feature')
@UseGuards(JwtAuthGuard, SubscriptionGuard)
@RequiresPremium()
async getPremiumFeature(@Request() req) {
  // Only premium users can access this endpoint
}
```

### Enforcing Daily Exercise Limits

```typescript
@Post('exercises/start')
@UseGuards(JwtAuthGuard, UsageGuard)
@ChecksUsageLimit()
async startExercise(@Request() req) {
  // Free users limited to 3 exercises per day
  // Premium users have unlimited access
}
```

### Creating a Subscription

```typescript
const subscription = await subscriptionService.createSubscription({
  userId: 'user_id',
  tier: 'PREMIUM_YEARLY',
  purchaseToken: 'google_play_token',
  productId: 'snaprep_premium',
  actualPrice: 29.99,
  originalPrice: 29.99,
});
```

## Google Play Integration

### Setup Requirements

1. **Google Play Developer Account**: Set up subscription products
2. **Service Account**: Create credentials for API access
3. **Product Configuration**: Configure `snaprep_premium` with monthly and yearly plans

### Product Configuration

```
Product ID: snaprep_premium
Base Plans:
- monthly-plan: P1M, $4.99 USD
- yearly-plan: P1Y, $29.99 USD (50% savings)
Free Trial: 7 days for both plans
```

### Environment Variables

```env
GOOGLE_PLAY_KEY_FILE=path/to/service-account.json
ANDROID_PACKAGE_NAME=com.snaprep.app
NODE_ENV=production
```

## Subscription Tiers

### FREE
- 3 exercises per day
- 7-day free trial available
- Basic features access

### PREMIUM (Monthly)
- $4.99/month
- Unlimited exercises
- Premium features access
- Priority support

### PREMIUM_YEARLY (Yearly)
- $29.99/year (50% savings)
- All monthly premium benefits
- Best value option

## Error Handling

The system provides comprehensive error responses:

### Daily Limit Reached
```json
{
  "statusCode": 403,
  "message": "Daily exercise limit reached",
  "code": "DAILY_LIMIT_REACHED",
  "limit": 3,
  "upgradeMessage": "Upgrade to Premium for unlimited daily exercises",
  "upgradeUrl": "/subscription",
  "features": ["Unlimited daily exercises", "Premium workout plans"]
}
```

### Premium Required
```json
{
  "statusCode": 403,
  "message": "Premium subscription required",
  "code": "PREMIUM_REQUIRED",
  "upgradeUrl": "/subscription",
  "features": ["Unlimited daily exercises", "Advanced analytics"]
}
```

## Background Tasks

The system includes several automated tasks:

### Hourly Tasks
- Process expired subscriptions
- Verify pending Google Play purchases

### Daily Tasks
- Clean up old usage records (90+ days)
- Send renewal reminders
- Generate subscription analytics

## Development Mode

For development, the Google Play verification is simulated:

```typescript
// Use development tokens starting with 'dev_'
const purchaseToken = 'dev_test_token_123';
const verification = await googlePlayService.verifyPurchase(productId, purchaseToken);
// Returns { isValid: true } for development tokens
```

## Testing

### Test Scenarios

1. **Free Trial Flow**:
   - New user starts trial → gets 7 days premium access
   - Trial expires → reverts to free tier with daily limits

2. **Premium Subscription**:
   - User purchases monthly/yearly → immediate premium access
   - Subscription expires → graceful downgrade to free tier

3. **Daily Limits**:
   - Free user completes 3 exercises → blocked from more
   - Premium user → unlimited exercise access

4. **Cancellation**:
   - User cancels subscription → retains access until end of period
   - Subscription expires → downgrades to free tier

## Security Considerations

1. **Purchase Verification**: All Google Play purchases are verified server-side
2. **RLS Policies**: Database-level security for subscription data
3. **Rate Limiting**: Prevent abuse of trial and subscription endpoints
4. **Token Validation**: Secure handling of Google Play purchase tokens

## Migration and Deployment

### Database Migration

1. Run the SQL migration in Supabase:
```sql
-- Execute backend/sql/supabase_migration.sql
```

2. Update Prisma schema:
```bash
npx prisma generate
```

3. Verify tables are created correctly

### Environment Setup

1. Configure Google Play credentials
2. Set up environment variables
3. Enable background task scheduling

## Monitoring and Analytics

The system tracks key metrics:

- **Conversion Rates**: Free to premium conversion
- **Retention Rates**: Subscription renewal rates
- **Usage Patterns**: Daily exercise completion trends
- **Revenue Metrics**: Monthly/yearly revenue tracking

## Support and Troubleshooting

### Common Issues

1. **Purchase Verification Failed**
   - Check Google Play credentials
   - Verify product ID configuration
   - Review purchase token format

2. **Daily Limits Not Working**
   - Verify timezone handling
   - Check DailyUsage table records
   - Review guard configuration

3. **Trial Not Starting**
   - Check user's trial history
   - Verify trial start logic
   - Review user table updates

For additional support, check the logs and monitoring dashboards for detailed error information.