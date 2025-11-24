import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Token管理服务
/// 负责保存、获取和删除认证token
///
/// Token过期时间说明:
/// - Access Token: 1小时 (3600秒)
/// - Refresh Token: 7天 (604800秒)
///
/// 一般APP会保留token信息:
/// - 短期: Access Token 通常1-2小时
/// - 长期: Refresh Token 通常7-30天
/// - 记住我: 可以保存更长时间 (30-90天)
class TokenService {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';

  static TokenService? _instance;
  SharedPreferences? _prefs;

  TokenService._internal();

  static TokenService get instance {
    _instance ??= TokenService._internal();
    return _instance!;
  }

  /// 初始化 SharedPreferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// 保存认证token
  ///
  /// [accessToken] - 访问令牌 (有效期1小时)
  /// [refreshToken] - 刷新令牌 (有效期7天)
  /// [expiresIn] - 过期时间(秒)，默认3600秒(1小时)
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    int expiresIn = 3600, // 默认1小时
  }) async {
    await init();

    final expiryTime = DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);

    await _prefs!.setString(_accessTokenKey, accessToken);
    await _prefs!.setString(_refreshTokenKey, refreshToken);
    await _prefs!.setInt(_tokenExpiryKey, expiryTime);

    debugPrint('💾 Tokens saved successfully');
    debugPrint('📅 Access token expires in: $expiresIn seconds');
    debugPrint('📅 Expiry time: ${DateTime.fromMillisecondsSinceEpoch(expiryTime)}');
  }

  /// 获取访问令牌
  Future<String?> getAccessToken() async {
    await init();

    final token = _prefs!.getString(_accessTokenKey);

    if (token != null && await isTokenValid()) {
      return token;
    }

    return null;
  }

  /// 获取刷新令牌
  Future<String?> getRefreshToken() async {
    await init();
    return _prefs!.getString(_refreshTokenKey);
  }

  /// 检查token是否有效(未过期)
  Future<bool> isTokenValid() async {
    await init();

    final expiryTime = _prefs!.getInt(_tokenExpiryKey);

    if (expiryTime == null) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final isValid = now < expiryTime;

    if (!isValid) {
      debugPrint('⚠️ Access token has expired');
    }

    return isValid;
  }

  /// 清除所有token (登出时调用)
  Future<void> clearTokens() async {
    await init();

    await _prefs!.remove(_accessTokenKey);
    await _prefs!.remove(_refreshTokenKey);
    await _prefs!.remove(_tokenExpiryKey);

    debugPrint('🗑️ All tokens cleared');
  }

  /// 检查是否已登录
  Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && await isTokenValid();
  }
}
