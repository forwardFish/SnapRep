import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/exercise.dart';
import '../models/workout_intent.dart';
import '../models/target_muscle.dart';
import '../config/api_config.dart';
import '../utils/error_handler.dart';

class ExerciseService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// Quick workout recommendation
  Future<Map<String, dynamic>> getQuickRecommendation({
    required WorkoutIntent intent,
    required List<String> equipmentCodes,
    required String scenarioCode,
    List<TargetMuscle>? targetMuscles,
    String? difficultyLevel,
    int? maxDuration,
  }) async {
    try {
      final requestBody = {
        'intent': intent.code, // Use code instead of name
        'equipmentCodes': equipmentCodes,
        'scenarioCode': scenarioCode,
        if (targetMuscles != null && targetMuscles.isNotEmpty)
          'targetMuscles': targetMuscles.map((m) => m.code).toList(), // Use code instead of name
        if (difficultyLevel != null) 'difficultyLevel': difficultyLevel,
        if (maxDuration != null) 'maxDuration': maxDuration,
      };

      debugPrint('🚀 Sending quick recommendation request: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/recommendations/quick'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      debugPrint('📡 Quick recommendation response status: ${response.statusCode}');
      debugPrint('📡 Quick recommendation response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data;
      } else {
        debugPrint('❌ Failed to get recommendations: ${response.statusCode} - ${response.body}');

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
            message: '服务器返回错误，请稍后重试',
            category: 'SYSTEM',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Network error in getQuickRecommendation: $e');
      // 如果是 ErrorInfo 对象，直接重新抛出
      if (e is ErrorInfo) {
        rethrow;
      }
      // 其他网络错误，包装成 ErrorInfo
      throw ErrorInfo(
        code: 1004,
        message: '网络连接失败，请检查网络后重试',
        category: 'NETWORK',
      );
    }
  }

  /// Replace exercise with alternatives
  Future<List<Exercise>> getExerciseAlternatives({
    required String exerciseId,
    required String reason,
    List<String>? availableEquipment,
    String? scenario,
  }) async {
    try {
      final queryParams = <String, String>{
        'reason': reason,
        if (availableEquipment != null) 'equipment': availableEquipment.join(','),
        if (scenario != null) 'scenario': scenario,
      };

      final uri = Uri.parse('$_baseUrl/api/v1/recommendations/$exerciseId/alternatives')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> exercisesJson = data['alternatives'] ?? [];

        return exercisesJson
            .map((json) => Exercise.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get alternatives: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get exercises by equipment and scenario
  Future<List<Exercise>> getExercisesByContext({
    required List<String> equipmentCodes,
    required String scenarioCode,
    WorkoutIntent? intent,
    List<TargetMuscle>? targetMuscles,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'equipmentCodes': equipmentCodes.join(','),
        'scenarioCode': scenarioCode,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (intent != null) {
        queryParams['intent'] = intent.name.toUpperCase();
      }

      if (targetMuscles != null && targetMuscles.isNotEmpty) {
        queryParams['targetMuscles'] = targetMuscles.map((m) => m.name.toUpperCase()).join(',');
      }

      final uri = Uri.parse('$_baseUrl/api/v1/exercises/search')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> exercisesJson = data['data'] ?? [];

        return exercisesJson
            .map((json) => Exercise.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to search exercises: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Check if equipment has available exercises
  /// Returns the count of available exercises for the given equipment
  Future<int> checkEquipmentExercisesCount({
    required String equipmentCode,
  }) async {
    try {
      final requestBody = {
        'equipment': [equipmentCode],
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/exercises/check-availability'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] as int? ?? 0;
      } else if (response.statusCode == 404) {
        // API endpoint doesn't exist yet, try alternative method
        return await _checkEquipmentExercisesCountFallback(equipmentCode);
      } else {
        throw Exception('Failed to check availability: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Failed to check equipment exercises count: $e');
      // Return -1 to indicate error, let caller decide how to handle
      return -1;
    }
  }

  /// Fallback method to check exercises count by searching
  Future<int> _checkEquipmentExercisesCountFallback(String equipmentCode) async {
    try {
      // Try to get exercises with this equipment
      final exercises = await getExercisesByContext(
        equipmentCodes: [equipmentCode],
        scenarioCode: 'general', // Use a general scenario
        pageSize: 1, // We only need to know if any exist
      );
      return exercises.length;
    } catch (e) {
      debugPrint('⚠️ Fallback check also failed: $e');
      return -1;
    }
  }
}