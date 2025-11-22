import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/popular_exercise_dto.dart';

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
        throw Exception('Failed to load popular exercises: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
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