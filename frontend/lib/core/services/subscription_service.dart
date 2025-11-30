import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/subscription_model.dart';
import 'token_service.dart';

/// 订阅服务
/// 负责处理用户订阅状态查询、试用期管理、购买验证等
class SubscriptionService {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  // 缓存订阅状态,避免频繁请求
  SubscriptionStatusResponse? _cachedStatus;
  DateTime? _cacheTime;
  static const Duration _cacheExpiration = Duration(minutes: 5);

  /// 获取用户订阅状态
  /// [forceRefresh] - 是否强制刷新,忽略缓存
  Future<SubscriptionStatusResponse> getSubscriptionStatus({
    bool forceRefresh = false,
  }) async {
    try {
      // 检查缓存
      if (!forceRefresh &&
          _cachedStatus != null &&
          _cacheTime != null &&
          DateTime.now().difference(_cacheTime!) < _cacheExpiration) {
        debugPrint('📦 Using cached subscription status');
        return _cachedStatus!;
      }

      debugPrint('🔄 Fetching subscription status from API...');

      final accessToken = await TokenService.instance.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token found. User not logged in.');
      }

      final response = await http.get(
        Uri.parse('${AppConstants.nestJsApiUrl}/subscription/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
      );

      debugPrint('📊 Subscription status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = SubscriptionStatusResponse.fromJson(data);

        // 更新缓存
        _cachedStatus = status;
        _cacheTime = DateTime.now();

        debugPrint('✅ Subscription status: ${status.subscription}');
        debugPrint('✅ Daily usage: ${status.dailyUsage}');

        return status;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized. Please login again.');
      } else {
        throw Exception('Failed to get subscription status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting subscription status: $e');

      // 返回默认的免费用户状态
      return SubscriptionStatusResponse(
        subscription: SubscriptionStatus(
          isActive: false,
          tier: SubscriptionTier.free,
          status: SubscriptionStatusEnum.expired,
          isTrialActive: false,
          canStartTrial: false,
        ),
        dailyUsage: DailyUsage(
          exercisesUsed: 0,
          exerciseLimit: 3,
          canStartExercise: true,
          resetAt: DateTime.now().add(const Duration(days: 1)),
        ),
      );
    }
  }

  /// 检查用户是否可以开始训练
  /// 综合判断订阅状态和每日限制
  Future<bool> canStartExercise() async {
    try {
      final status = await getSubscriptionStatus();

      // Premium 用户可以无限训练
      if (status.subscription.isPremiumUser) {
        return true;
      }

      // 试用期用户可以无限训练
      if (status.subscription.isTrialActive) {
        return true;
      }

      // 免费用户检查每日限制
      return status.dailyUsage.canStartExercise;
    } catch (e) {
      debugPrint('❌ Error checking exercise permission: $e');
      return false;
    }
  }

  /// 开始免费试用
  Future<bool> startFreeTrial({String? timezone}) async {
    try {
      debugPrint('🎁 Starting free trial...');

      final accessToken = await TokenService.instance.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token found. User not logged in.');
      }

      final request = StartTrialRequest(timezone: timezone);
      final response = await http.post(
        Uri.parse('${AppConstants.nestJsApiUrl}/subscription/trial/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );

      debugPrint('📊 Start trial response: ${response.statusCode}');
      debugPrint('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Free trial started successfully');

        // 清除缓存,强制刷新状态
        _clearCache();

        return true;
      } else {
        // 解析错误信息
        try {
          final errorData = jsonDecode(response.body);
          final errorMessage = errorData['message'] ?? 'Unknown error';
          debugPrint('❌ Failed to start trial: $errorMessage');

          // 抛出包含后端错误信息的异常
          throw Exception(errorMessage);
        } catch (e) {
          if (e is Exception && e.toString().contains('message')) {
            rethrow;
          }
          debugPrint('❌ Failed to parse error response');
          throw Exception('Failed to start trial (Status ${response.statusCode})');
        }
      }
    } catch (e) {
      debugPrint('❌ Error starting free trial: $e');
      rethrow; // 重新抛出异常,让调用方处理
    }
  }

  /// 验证 Google Play 购买
  Future<bool> verifyPurchase(VerifyPurchaseRequest request) async {
    try {
      debugPrint('💳 Verifying purchase...');

      final accessToken = await TokenService.instance.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token found. User not logged in.');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.nestJsApiUrl}/subscription/verify-purchase'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(request.toJson()),
      );

      debugPrint('📊 Verify purchase response: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Purchase verified successfully');

        // 清除缓存,强制刷新状态
        _clearCache();

        return true;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error';
        debugPrint('❌ Failed to verify purchase: $errorMessage');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error verifying purchase: $e');
      return false;
    }
  }

  /// 取消订阅
  Future<bool> cancelSubscription({String? reason}) async {
    try {
      debugPrint('🚫 Canceling subscription...');

      final accessToken = await TokenService.instance.getAccessToken();
      if (accessToken == null) {
        throw Exception('No access token found. User not logged in.');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.nestJsApiUrl}/subscription/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'reason': reason}),
      );

      debugPrint('📊 Cancel subscription response: ${response.statusCode}');

      if (response.statusCode == 200) {
        debugPrint('✅ Subscription canceled successfully');

        // 清除缓存,强制刷新状态
        _clearCache();

        return true;
      } else {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['message'] ?? 'Unknown error';
        debugPrint('❌ Failed to cancel subscription: $errorMessage');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error canceling subscription: $e');
      return false;
    }
  }

  /// 记录一次训练使用(用于每日限制统计)
  Future<void> recordExercise({String? timezone}) async {
    try {
      debugPrint('📝 Recording exercise usage...');

      final accessToken = await TokenService.instance.getAccessToken();
      if (accessToken == null) {
        debugPrint('⚠️ No access token, skipping exercise recording');
        return;
      }

      final response = await http.post(
        Uri.parse('${AppConstants.nestJsApiUrl}/daily-usage/record-exercise'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({'timezone': timezone}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ Exercise recorded successfully');

        // 清除缓存,强制刷新状态
        _clearCache();
      } else {
        debugPrint('⚠️ Failed to record exercise: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error recording exercise: $e');
    }
  }

  /// 获取每日使用统计
  Future<DailyUsage?> getDailyUsage() async {
    try {
      final status = await getSubscriptionStatus();
      return status.dailyUsage;
    } catch (e) {
      debugPrint('❌ Error getting daily usage: $e');
      return null;
    }
  }

  /// 检查是否需要显示订阅提示
  /// 返回 true 表示需要显示付费弹窗
  Future<bool> shouldShowSubscriptionPrompt() async {
    try {
      final status = await getSubscriptionStatus();

      // 付费用户或试用期用户不显示
      if (status.subscription.hasAccess) {
        return false;
      }

      // 免费用户达到每日限制时显示
      if (status.dailyUsage.hasReachedLimit) {
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Error checking subscription prompt: $e');
      return false;
    }
  }

  /// 清除缓存
  void _clearCache() {
    _cachedStatus = null;
    _cacheTime = null;
    debugPrint('🗑️ Subscription cache cleared');
  }

  /// 手动清除缓存(用于登出等场景)
  void clearCache() {
    _clearCache();
  }
}
