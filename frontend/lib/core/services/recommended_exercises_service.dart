import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/recommended_exercise_dto.dart';

/// 推荐动作服务
class RecommendedExercisesService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// 获取用户最常训练的动作
  /// [userId] 用户ID
  /// [limit] 返回数量限制，默认6个
  Future<List<RecommendedExerciseDto>> getUserMostTrainedExercises(
    String userId, {
    int limit = 6,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/rest/v1/users/$userId/most-trained-exercises')
          .replace(queryParameters: {'limit': limit.toString()});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final exercises = data['data']['exercises'] as List<dynamic>;

          return exercises
              .map((json) => RecommendedExerciseDto.fromJson(json))
              .toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load most trained exercises: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// 检查用户是否有训练历史
  /// [userId] 用户ID
  Future<bool> hasTrainingHistory(String userId) async {
    try {
      final exercises = await getUserMostTrainedExercises(userId, limit: 1);
      return exercises.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// 获取用户训练统计摘要
  /// [userId] 用户ID
  Future<Map<String, dynamic>> getUserTrainingSummary(String userId) async {
    try {
      final uri = Uri.parse('$_baseUrl/rest/v1/users/$userId/stats')
          .replace(queryParameters: {'days': '7'}); // 获取近7天的统计

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        } else {
          return {};
        }
      } else {
        return {};
      }
    } catch (e) {
      return {};
    }
  }
}