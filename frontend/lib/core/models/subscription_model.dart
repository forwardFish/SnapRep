/// 订阅相关数据模型
/// 用于管理用户订阅状态、试用期、每日使用限制等

/// 订阅层级枚举
enum SubscriptionTier {
  free('FREE'),
  premium('PREMIUM'),
  premiumYearly('PREMIUM_YEARLY');

  const SubscriptionTier(this.value);
  final String value;

  static SubscriptionTier fromString(String value) {
    switch (value.toUpperCase()) {
      case 'FREE':
        return SubscriptionTier.free;
      case 'PREMIUM':
        return SubscriptionTier.premium;
      case 'PREMIUM_YEARLY':
        return SubscriptionTier.premiumYearly;
      default:
        return SubscriptionTier.free;
    }
  }
}

/// 订阅状态枚举
enum SubscriptionStatusEnum {
  active('ACTIVE'),
  pastDue('PAST_DUE'),
  canceled('CANCELED'),
  unpaid('UNPAID'),
  expired('EXPIRED');

  const SubscriptionStatusEnum(this.value);
  final String value;

  static SubscriptionStatusEnum fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ACTIVE':
        return SubscriptionStatusEnum.active;
      case 'PAST_DUE':
        return SubscriptionStatusEnum.pastDue;
      case 'CANCELED':
        return SubscriptionStatusEnum.canceled;
      case 'UNPAID':
        return SubscriptionStatusEnum.unpaid;
      case 'EXPIRED':
        return SubscriptionStatusEnum.expired;
      default:
        return SubscriptionStatusEnum.expired;
    }
  }
}

/// 订阅状态信息
class SubscriptionStatus {
  final bool isActive;                    // 是否有有效订阅(包括试用期)
  final SubscriptionTier tier;           // 订阅层级
  final SubscriptionStatusEnum status;    // 订阅状态
  final DateTime? expiresAt;             // 订阅到期时间
  final bool isTrialActive;              // 试用期是否激活
  final DateTime? trialEndsAt;           // 试用期结束时间
  final bool canStartTrial;              // 是否可以开始试用

  SubscriptionStatus({
    required this.isActive,
    required this.tier,
    required this.status,
    this.expiresAt,
    required this.isTrialActive,
    this.trialEndsAt,
    required this.canStartTrial,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      isActive: json['isActive'] ?? false,
      tier: SubscriptionTier.fromString(json['tier'] ?? 'FREE'),
      status: SubscriptionStatusEnum.fromString(json['status'] ?? 'EXPIRED'),
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'])
          : null,
      isTrialActive: json['isTrialActive'] ?? false,
      trialEndsAt: json['trialEndsAt'] != null
          ? DateTime.parse(json['trialEndsAt'])
          : null,
      canStartTrial: json['canStartTrial'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'tier': tier.value,
      'status': status.value,
      'expiresAt': expiresAt?.toIso8601String(),
      'isTrialActive': isTrialActive,
      'trialEndsAt': trialEndsAt?.toIso8601String(),
      'canStartTrial': canStartTrial,
    };
  }

  /// 是否为付费用户(不包括试用期)
  bool get isPremiumUser =>
      tier != SubscriptionTier.free &&
      status == SubscriptionStatusEnum.active &&
      !isTrialActive;

  /// 是否有使用权限(付费用户或试用期)
  bool get hasAccess => isActive;

  /// 获取订阅状态的用户友好描述
  String get displayStatus {
    if (isTrialActive) {
      final daysLeft = trialEndsAt?.difference(DateTime.now()).inDays ?? 0;
      if (daysLeft > 0) {
        return '$daysLeft days left in trial';
      } else {
        return 'Trial ended';
      }
    }

    if (tier == SubscriptionTier.free) {
      return 'Free Plan';
    }

    switch (status) {
      case SubscriptionStatusEnum.active:
        return tier == SubscriptionTier.premium ? 'Premium Monthly' : 'Premium Yearly';
      case SubscriptionStatusEnum.expired:
        return 'Subscription Expired';
      case SubscriptionStatusEnum.canceled:
        return 'Subscription Canceled';
      default:
        return 'Inactive';
    }
  }

  @override
  String toString() {
    return 'SubscriptionStatus(isActive: $isActive, tier: ${tier.value}, status: ${status.value})';
  }
}

/// 每日使用情况
class DailyUsage {
  final int exercisesUsed;      // 今日已使用的训练次数
  final int? exerciseLimit;     // 每日训练限制(null表示无限制)
  final bool canStartExercise;  // 是否可以开始新的训练
  final DateTime resetAt;       // 重置时间(午夜)

  DailyUsage({
    required this.exercisesUsed,
    this.exerciseLimit,
    required this.canStartExercise,
    required this.resetAt,
  });

  factory DailyUsage.fromJson(Map<String, dynamic> json) {
    return DailyUsage(
      exercisesUsed: json['exercisesUsed'] ?? 0,
      exerciseLimit: json['exerciseLimit'],
      canStartExercise: json['canStartExercise'] ?? true,
      resetAt: json['resetAt'] != null
          ? DateTime.parse(json['resetAt'])
          : _getNextMidnight(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exercisesUsed': exercisesUsed,
      'exerciseLimit': exerciseLimit,
      'canStartExercise': canStartExercise,
      'resetAt': resetAt.toIso8601String(),
    };
  }

  /// 获取剩余可用次数
  int? get remainingExercises {
    if (exerciseLimit == null) return null;
    return (exerciseLimit! - exercisesUsed).clamp(0, exerciseLimit!);
  }

  /// 是否达到每日限制
  bool get hasReachedLimit {
    if (exerciseLimit == null) return false;
    return exercisesUsed >= exerciseLimit!;
  }

  /// 获取限制重置倒计时的小时数
  int get hoursUntilReset {
    final now = DateTime.now();
    final diff = resetAt.difference(now);
    return diff.inHours.clamp(0, 24);
  }

  /// 获取限制信息的用户友好描述
  String get displayLimit {
    if (exerciseLimit == null) {
      return 'Unlimited exercises';
    }

    if (hasReachedLimit) {
      return 'Daily limit reached (resets in ${hoursUntilReset}h)';
    }

    return '$exercisesUsed/$exerciseLimit exercises today';
  }

  static DateTime _getNextMidnight() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  @override
  String toString() {
    return 'DailyUsage(exercisesUsed: $exercisesUsed, exerciseLimit: $exerciseLimit, canStart: $canStartExercise)';
  }
}

/// 订阅完整状态响应
class SubscriptionStatusResponse {
  final SubscriptionStatus subscription;
  final DailyUsage dailyUsage;
  final Map<String, dynamic>? weeklySummary;

  SubscriptionStatusResponse({
    required this.subscription,
    required this.dailyUsage,
    this.weeklySummary,
  });

  factory SubscriptionStatusResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;

    return SubscriptionStatusResponse(
      subscription: SubscriptionStatus.fromJson(data['subscription'] ?? {}),
      dailyUsage: DailyUsage.fromJson(data['dailyUsage'] ?? {}),
      weeklySummary: data['weeklySummary'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subscription': subscription.toJson(),
      'dailyUsage': dailyUsage.toJson(),
      'weeklySummary': weeklySummary,
    };
  }

  @override
  String toString() {
    return 'SubscriptionStatusResponse(subscription: $subscription, dailyUsage: $dailyUsage)';
  }
}

/// 试用期开始请求
class StartTrialRequest {
  final String? timezone;

  StartTrialRequest({this.timezone});

  Map<String, dynamic> toJson() {
    return {
      if (timezone != null) 'timezone': timezone,
    };
  }
}

/// Google Play 购买验证请求
class VerifyPurchaseRequest {
  final String productId;
  final String purchaseToken;
  final String? orderId;
  final double actualPrice;
  final double originalPrice;
  final SubscriptionTier tier;
  final String currency;

  VerifyPurchaseRequest({
    required this.productId,
    required this.purchaseToken,
    this.orderId,
    required this.actualPrice,
    required this.originalPrice,
    required this.tier,
    this.currency = 'USD',
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'purchaseToken': purchaseToken,
      'orderId': orderId,
      'actualPrice': actualPrice,
      'originalPrice': originalPrice,
      'tier': tier.value,
      'currency': currency,
    };
  }
}