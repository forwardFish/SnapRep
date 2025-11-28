import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/popular_exercise_dto.dart';
import '../utils/error_handler.dart';

/// 热门推荐动作服务（通用，不需要个人信息）
class PopularExercisesService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// 获取热门推荐动作
  /// [limit] 返回数量限制，默认6个
  Future<List<PopularExerciseDto>> getPopularExercises({
    int limit = 6,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/v1/recommendations/popular-exercises')
          .replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(uri);

      debugPrint('📡 Popular exercises response status: ${response.statusCode}');
      debugPrint('📡 Popular exercises response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final exercises = data['data']['exercises'] as List<dynamic>;

          return exercises
              .map((json) => PopularExerciseDto.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        debugPrint('❌ Failed to load popular exercises: ${response.statusCode} - ${response.body}');

        // ✅ 使用统一的错误处理器解析后端返回的错误信息
        try {
          final errorResponse = json.decode(response.body);
          final errorInfo = ErrorHandler.parseErrorResponse(errorResponse);

          debugPrint('📋 Parsed error: ${errorInfo.toString()}');

          // 抛出 ErrorInfo 对象，让上层调用者处理
          throw errorInfo;
        } catch (parseError) {
          // 如果无法解析，抛出通用错误
          if (parseError is ErrorInfo) {
            rethrow;
          }
          throw ErrorInfo(
            code: 1004,
            message: 'Server error, please try again later',
            category: 'SYSTEM',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Network error in getPopularExercises: $e');
      // 如果是 ErrorInfo 对象，直接重新抛出
      if (e is ErrorInfo) {
        rethrow;
      }
      // Other network errors, wrap as ErrorInfo
      throw ErrorInfo(
        code: 1004,
        message: 'Network connection failed, please check your connection and try again',
        category: 'NETWORK',
      );
    }
  }

  /// 检查是否有可用的推荐动作
  Future<bool> hasPopularExercises() async {
    try {
      final exercises = await getPopularExercises(limit: 1);
      return exercises.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}