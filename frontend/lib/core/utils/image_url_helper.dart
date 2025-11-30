import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// 图片 URL 辅助工具类
/// 用于将后端返回的相对路径转换为完整的后端 API URL
class ImageUrlHelper {
  /// 将后端返回的相对路径转换为完整的图片 URL
  ///
  /// 示例:
  /// - 输入: "exercise/bottle_bicep_curl.jpg"
  /// - 输出: "http://127.0.0.1:3000/api/v1/assets/images/exercise/bottle_bicep_curl.jpg"
  ///
  /// 如果输入已经是完整 URL（http/https 开头），则直接返回
  static String getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      debugPrint('🖼️ Image URL Transform: null/empty => empty string');
      return '';
    }

    // 如果已经是完整的 URL，直接返回
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      debugPrint('🖼️ Image URL Transform: $imagePath => (already full URL)');
      return imagePath;
    }

    // 如果是本地 asset 路径，直接返回
    if (imagePath.startsWith('assets/')) {
      debugPrint('🖼️ Image URL Transform: $imagePath => (local asset)');
      return imagePath;
    }

    // 转换为后端 API URL
    // 移除开头的 '/' 如果存在
    final cleanPath = imagePath.startsWith('/') ? imagePath.substring(1) : imagePath;
    final fullUrl = '${AppConstants.nestJsApiUrl}/api/v1/assets/images/$cleanPath';

    debugPrint('🖼️ Image URL Transform: $imagePath => $fullUrl');
    return fullUrl;
  }

  /// 获取 Exercise 的缩略图 URL
  static String getExerciseThumbnail(String? thumbnailPath) {
    return getImageUrl(thumbnailPath);
  }

  /// 获取 Exercise 的演示图片 URL
  static String getExerciseDemoImage(String? demoImagePath) {
    return getImageUrl(demoImagePath);
  }

  /// 获取 Exercise 的演示视频 URL
  static String getExerciseDemoVideo(String? demoVideoPath) {
    return getImageUrl(demoVideoPath);
  }

  /// 获取 Scenario 的图片 URL
  static String getScenarioImage(String? scenarioImagePath) {
    return getImageUrl(scenarioImagePath);
  }

  /// 检查是否为有效的图片 URL
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }

    // 检查是否为完整 URL 或本地 asset
    return url.startsWith('http://') ||
           url.startsWith('https://') ||
           url.startsWith('assets/');
  }
}
