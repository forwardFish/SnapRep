import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/challenge_item.dart';
import '../config/api_config.dart';

class ChallengesService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// Get all challenge items
  Future<List<ChallengeItem>> getChallenges({
    int page = 1,
    int pageSize = 12,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (isActive != null) {
        queryParams['isActive'] = isActive.toString();
      }

      final uri = Uri.parse('$_baseUrl/challenges')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> challengesJson = data['data'] ?? [];

        return challengesJson
            .map((json) => ChallengeItem.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load challenges: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get single challenge item by ID
  Future<ChallengeItem> getChallengeById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/challenges/$id'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ChallengeItem.fromJson(data['data']);
      } else if (response.statusCode == 404) {
        throw Exception('Challenge not found');
      } else {
        throw Exception('Failed to load challenge: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Start a challenge
  Future<Map<String, dynamic>> startChallenge({
    required String userId,
    required String challengeItemId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/challenges/completions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'challengeItemId': challengeItemId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to start challenge: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Update challenge progress
  Future<Map<String, dynamic>> updateChallengeProgress({
    required String completionId,
    int? actualDuration,
    int? completedCount,
    double? progressPercent,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/challenges/completions/$completionId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'actualDuration': actualDuration,
          'completedCount': completedCount,
          'progressPercent': progressPercent,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to update progress: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Complete a challenge
  Future<Map<String, dynamic>> completeChallenge({
    required String completionId,
    int? actualDuration,
    required int completedCount,
    int? difficultyFelt,
    int? enjoymentRating,
    String? feedback,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/challenges/completions/$completionId/complete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'actualDuration': actualDuration,
          'completedCount': completedCount,
          'difficultyFelt': difficultyFelt,
          'enjoymentRating': enjoymentRating,
          'feedback': feedback,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to complete challenge: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Abandon a challenge
  Future<Map<String, dynamic>> abandonChallenge({
    required String completionId,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/challenges/completions/$completionId/abandon'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to abandon challenge: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get user's challenge completions
  Future<List<Map<String, dynamic>>> getUserCompletions(String userId, {
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) {
        queryParams['status'] = status;
      }

      final uri = Uri.parse('$_baseUrl/challenges/completions/user/$userId')
          .replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> completions = data['data'] ?? [];
        return completions.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load user completions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get challenges stats
  Future<Map<String, dynamic>> getChallengesStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/challenges/stats'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load challenges stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}