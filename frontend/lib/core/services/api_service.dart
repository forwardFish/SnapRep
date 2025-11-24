import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/scenario.dart';
import '../models/equipment.dart';
import '../models/theme_week.dart';
import '../models/workout_session.dart';
import '../models/exercise.dart';
import '../models/share_card.dart';
import 'supabase_service.dart';
import 'token_service.dart';

class ApiService {
  static ApiService? _instance;
  late SupabaseService _supabaseService;
  late TokenService _tokenService;

  ApiService._internal() {
    _supabaseService = SupabaseService.instance;
    _tokenService = TokenService.instance;
  }

  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  // Helper method to get authorization headers
  Future<Map<String, String>> get _headers async {
    // 优先使用自定义JWT token
    final customToken = await _tokenService.getAccessToken();

    // 如果没有自定义token，尝试使用Supabase token (兼容性)
    final supabaseToken = _supabaseService.client.auth.currentSession?.accessToken;

    final token = customToken ?? supabaseToken;

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Homepage APIs

  /// Get scenarios list (NestJS Backend API)
  /// GET /api/v1/rest/v1/scenarios
  Future<List<Scenario>> getScenarios({int page = 1, int pageSize = 20}) async {
    try {
      print('🌐 Making API call to load scenarios from backend...');

      final queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      final uri = Uri.parse('${AppConstants.nestJsApiUrl}/rest/v1/scenarios')
          .replace(queryParameters: queryParams);

      print('📍 Scenarios API URL: $uri');

      final response = await http.get(uri, headers: await _headers);

      print('📊 Scenarios response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Scenarios loaded successfully: ${data['data']?.length ?? 0} items');

        final scenariosList = data['data'] as List;
        return scenariosList
            .map((json) => Scenario.fromJson(json))
            .toList();
      } else {
        print('❌ Scenarios API call failed with status: ${response.statusCode}');
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to load scenarios: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception in getScenarios: $e');
      throw Exception('Failed to load scenarios: $e');
    }
  }

  /// Get equipment list (NestJS Backend API)
  /// GET /api/v1/rest/v1/equipment
  Future<List<Equipment>> getEquipment({int page = 1, int pageSize = 20}) async {
    try {
      print('🌐 Making API call to load equipment from backend...');

      final queryParams = {
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      final uri = Uri.parse('${AppConstants.nestJsApiUrl}/rest/v1/equipment')
          .replace(queryParameters: queryParams);

      print('📍 Equipment API URL: $uri');

      final response = await http.get(uri, headers: await _headers);

      print('📊 Equipment response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Equipment loaded successfully: ${data['data']?.length ?? 0} items');

        final equipmentList = data['data'] as List;
        return equipmentList
            .map((json) => Equipment.fromJson(json))
            .toList();
      } else {
        print('❌ Equipment API call failed with status: ${response.statusCode}');
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to load equipment: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception in getEquipment: $e');
      throw Exception('Failed to load equipment: $e');
    }
  }

  /// Get current theme week (NestJS Custom API)
  /// GET /api/v1/theme-weeks/current
  Future<ThemeWeek?> getCurrentThemeWeek() async {
    try {
      final url = '${AppConstants.nestJsApiUrl}/api/v1/theme-weeks/current';
      print('🌐 Making API call to: $url');

      final headers = await _headers;
      print('📋 Headers: $headers');

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      print('📊 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Parsed response data: $data');

        if (data['current'] != null) {
          final themeWeek = ThemeWeek.fromJson(data['current']);
          print('🎉 Successfully created ThemeWeek object: ${themeWeek.title}');
          return themeWeek;
        } else {
          print('ℹ️ No current theme week found');
          return null;
        }
      } else {
        print('❌ API call failed with status: ${response.statusCode}');
        print('❌ Error response: ${response.body}');
        throw Exception('Failed to load theme week: ${response.statusCode}');
      }
    } catch (e) {
      print('💥 Exception in getCurrentThemeWeek: $e');
      print('📍 Stack trace: ${StackTrace.current}');
      throw Exception('Failed to load current theme week: $e');
    }
  }

  /// Join theme week (NestJS Custom API)
  /// POST /api/v1/theme-weeks/{themeWeekId}/join
  Future<Map<String, dynamic>> joinThemeWeek(String themeWeekId) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('${AppConstants.nestJsApiUrl}/api/v1/theme-weeks/$themeWeekId/join'),
        headers: await _headers,
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']['message'] ?? 'Failed to join theme week');
      }
    } catch (e) {
      throw Exception('Failed to join theme week: $e');
    }
  }

  /// AI Equipment Recognition (NestJS Custom API)
  /// POST /api/v1/ai/recognize-equipment
  Future<Map<String, dynamic>> recognizeEquipment(List<int> imageBytes, {
    double confidence = 0.85,
    int maxResults = 5,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.nestJsApiUrl}/api/v1/ai/recognize-equipment'),
      );

      // Add headers
      request.headers.addAll(await _headers);

      // Add image file
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: 'image.jpg',
      ));

      // Add optional parameters
      request.fields['confidence'] = confidence.toString();
      request.fields['maxResults'] = maxResults.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to recognize equipment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to recognize equipment: $e');
    }
  }

  // Workout Recommendations APIs

  /// Generate quick recommendation (NestJS Custom API)
  /// POST /api/v1/recommendations/quick
  Future<WorkoutSession> generateQuickRecommendation(Map<String, dynamic> params) async {
    try {
      debugPrint('🤖 Generating quick recommendation with params: $params');

      // Try to get authenticated user ID, but don't fail if not available
      final userId = _supabaseService.currentUser?.id ?? 'anonymous-user';

      debugPrint('🆔 Using user ID: $userId');

      // 添加用户ID到请求参数
      final requestBody = {
        'userId': userId,
        ...params,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.nestJsApiUrl}/api/v1/recommendations/quick'),
        headers: await _headers,
        body: json.encode(requestBody),
      );

      debugPrint('📊 Quick recommendation response status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        debugPrint('✅ Quick recommendation successful: ${data.keys}');

        return WorkoutSession.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'Failed to generate recommendation');
      }
    } catch (e) {
      debugPrint('❌ Failed to generate quick recommendation: $e');
      throw Exception('Failed to generate recommendation: $e');
    }
  }

  /// Replace exercise in workout session (NestJS Custom API)
  /// POST /api/v1/recommendations/replace
  Future<Exercise> replaceExercise({
    required String sessionId,
    required int exercisePosition,
    required String currentExerciseId,
    Map<String, dynamic>? filters,
  }) async {
    try {
      debugPrint('🔄 Replacing exercise at position $exercisePosition');

      final requestBody = {
        'sessionId': sessionId,
        'exercisePosition': exercisePosition,
        'currentExerciseId': currentExerciseId,
        if (filters != null) 'filters': filters,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.nestJsApiUrl}/api/v1/recommendations/replace'),
        headers: await _headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Exercise.fromJson(data['newExercise']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'Failed to replace exercise');
      }
    } catch (e) {
      debugPrint('❌ Failed to replace exercise: $e');
      throw Exception('Failed to replace exercise: $e');
    }
  }

  /// Get alternative exercises for session (NestJS Custom API)
  /// GET /api/v1/recommendations/alternatives
  Future<List<Exercise>> getAlternativeExercises({
    required String sessionId,
    String? equipmentCode,
    int limit = 10,
  }) async {
    try {
      final queryParams = {
        'sessionId': sessionId,
        if (equipmentCode != null) 'equipment': equipmentCode,
        'limit': limit.toString(),
      };

      final uri = Uri.parse('${AppConstants.nestJsApiUrl}/api/v1/recommendations/alternatives')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['alternatives'] as List)
            .map((json) => Exercise.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to get alternative exercises: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Failed to get alternative exercises: $e');
      throw Exception('Failed to get alternative exercises: $e');
    }
  }

  // Workout Session Management APIs

  /// Get workout session details (Supabase Auto REST API)
  /// GET /rest/v1/workout_sessions/{sessionId}
  Future<WorkoutSession> getWorkoutSession(String sessionId) async {
    try {
      final response = await _supabaseService.client
          .from('workout_sessions')
          .select('*')
          .eq('id', sessionId)
          .single();

      return WorkoutSession.fromJson(response);
    } catch (e) {
      debugPrint('❌ Failed to get workout session: $e');
      throw Exception('Failed to load workout session: $e');
    }
  }

  /// Update workout session (Supabase Auto REST API)
  /// PATCH /rest/v1/workout_sessions/{sessionId}
  Future<WorkoutSession> updateWorkoutSession({
    required String sessionId,
    WorkoutSessionStatus? status,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    int? actualDurationSec,
    int? completedExerciseCount,
    int? skippedExerciseCount,
    int? actualCalories,
    String? notes,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (status != null) updateData['status'] = status.code;
      if (startedAt != null) updateData['started_at'] = startedAt.toIso8601String();
      if (completedAt != null) updateData['completed_at'] = completedAt.toIso8601String();
      if (cancelledAt != null) updateData['cancelled_at'] = cancelledAt.toIso8601String();
      if (actualDurationSec != null) updateData['actual_duration_sec'] = actualDurationSec;
      if (completedExerciseCount != null) updateData['completed_exercise_count'] = completedExerciseCount;
      if (skippedExerciseCount != null) updateData['skipped_exercise_count'] = skippedExerciseCount;
      if (actualCalories != null) updateData['actual_calories'] = actualCalories;
      if (notes != null) updateData['notes'] = notes;

      final response = await _supabaseService.client
          .from('workout_sessions')
          .update(updateData)
          .eq('id', sessionId)
          .select()
          .single();

      return WorkoutSession.fromJson(response);
    } catch (e) {
      debugPrint('❌ Failed to update workout session: $e');
      throw Exception('Failed to update workout session: $e');
    }
  }

  /// Get user's workout history (NestJS Custom API)
  /// GET /api/v1/users/:userId/sessions
  Future<List<WorkoutSession>> getUserWorkoutHistory({
    int page = 1,
    int pageSize = 20,
    WorkoutSessionStatus? status,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      // 优先从Supabase获取userId，如果不可用则通过API获取
      String? userId = _supabaseService.currentUser?.id;

      if (userId == null) {
        // 如果Supabase session不可用，通过后端API获取当前用户信息
        debugPrint('📅 Supabase userId not available, fetching from backend API...');
        final currentUser = await getCurrentUser();
        userId = currentUser['id'] as String?;

        if (userId == null) {
          throw Exception('User not authenticated');
        }
      }

      debugPrint('📅 Fetching workout history for user: $userId');

      // Build query parameters
      final queryParams = <String, String>{
        'limit': pageSize.toString(),
        'offset': ((page - 1) * pageSize).toString(),
      };

      if (status != null) {
        queryParams['status'] = status.code;
      }

      if (fromDate != null) {
        queryParams['fromDate'] = fromDate.toIso8601String();
      }

      if (toDate != null) {
        queryParams['toDate'] = toDate.toIso8601String();
      }

      final uri = Uri.parse('${AppConstants.nestJsApiUrl}/api/v1/users/$userId/sessions')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sessionsData = data['data'] as List;

        debugPrint('✅ Found ${sessionsData.length} workout sessions');

        return sessionsData
            .map((json) => WorkoutSession.fromJson(json))
            .toList();
      } else {
        debugPrint('⚠️ Failed to get workout history: ${response.statusCode}');
        throw Exception('Failed to load workout history: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Failed to get workout history: $e');
      throw Exception('Failed to load workout history: $e');
    }
  }

  // Share Card APIs

  /// Generate result card (NestJS Custom API)
  /// POST /api/v1/cards/generate
  Future<ShareCard> generateResultCard({
    required String sessionId,
    String template = 'classic',
    Map<String, dynamic>? style,
  }) async {
    try {
      debugPrint('🎨 Generating result card for session: $sessionId');

      final requestBody = {
        'sessionId': sessionId,
        'template': template,
        if (style != null) 'style': style,
      };

      final response = await http.post(
        Uri.parse('${AppConstants.nestJsApiUrl}/api/v1/cards/generate'),
        headers: await _headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        debugPrint('✅ Result card generated: ${data['cardId']}');

        return ShareCard.fromJson(data);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error']?['message'] ?? 'Failed to generate result card');
      }
    } catch (e) {
      debugPrint('❌ Failed to generate result card: $e');
      throw Exception('Failed to generate result card: $e');
    }
  }

  /// Get card rarity calculation (NestJS Custom API)
  /// GET /api/v1/rarity/calculate/{equipmentCode}
  Future<Map<String, dynamic>> calculateRarity({
    required String equipmentCode,
    String? scenarioCode,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (scenarioCode != null) {
        queryParams['scenario'] = scenarioCode;
      }

      final uri = Uri.parse('${AppConstants.nestJsApiUrl}/api/v1/rarity/calculate/$equipmentCode')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to calculate rarity: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Failed to calculate rarity: $e');
      throw Exception('Failed to calculate rarity: $e');
    }
  }

  /// Get user's share cards (NestJS Custom API)
  /// GET /api/v1/users/:userId/cards
  Future<List<ShareCard>> getUserShareCards({
    int page = 1,
    int pageSize = 20,
    RarityLevel? rarity,
    EquipmentSeries? series,
  }) async {
    try {
      // 优先从Supabase获取userId，如果不可用则通过API获取
      String? userId = _supabaseService.currentUser?.id;

      if (userId == null) {
        // 如果Supabase session不可用，通过后端API获取当前用户信息
        debugPrint('📦 Supabase userId not available, fetching from backend API...');
        final currentUser = await getCurrentUser();
        userId = currentUser['id'] as String?;

        if (userId == null) {
          throw Exception('User not authenticated');
        }
      }

      debugPrint('📦 Fetching user share cards for user: $userId');

      // Build query parameters
      final queryParams = <String, String>{
        'limit': pageSize.toString(),
        'offset': ((page - 1) * pageSize).toString(),
      };

      if (rarity != null) {
        queryParams['rarity'] = rarity.code;
      }

      if (series != null) {
        queryParams['series'] = series.code;
      }

      final uri = Uri.parse('${AppConstants.nestJsApiUrl}/api/v1/users/$userId/cards')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final cardsData = data['data'] as List;

        debugPrint('✅ Found ${cardsData.length} share cards');

        return cardsData
            .map((json) => ShareCard.fromJson(json))
            .toList();
      } else {
        debugPrint('⚠️ Failed to get share cards: ${response.statusCode}');
        throw Exception('Failed to load share cards: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Failed to get share cards: $e');
      throw Exception('Failed to load share cards: $e');
    }
  }

  /// Get share card by ID (Supabase Auto REST API)
  /// GET /rest/v1/share_cards/{cardId}
  Future<ShareCard> getShareCard(String cardId) async {
    try {
      final response = await _supabaseService.client
          .from('share_cards')
          .select('*')
          .eq('id', cardId)
          .single();

      return ShareCard.fromJson(response);
    } catch (e) {
      debugPrint('❌ Failed to get share card: $e');
      throw Exception('Failed to load share card: $e');
    }
  }

  /// Increment card share count (Supabase Auto REST API)
  /// PATCH /rest/v1/share_cards/{cardId}
  Future<void> incrementCardShareCount(String cardId) async {
    try {
      await _supabaseService.client.rpc('increment_card_share_count', params: {
        'card_id': cardId,
      });
    } catch (e) {
      debugPrint('❌ Failed to increment share count: $e');
      // 不抛出异常，分享计数失败不应该影响用户体验
    }
  }

  // User Management APIs

  /// Get current user info using custom JWT token
  /// GET /rest/v1/auth/me
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      // 使用自定义JWT token通过后端API获取用户信息
      final response = await http.get(
        Uri.parse('${AppConstants.nestJsApiUrl}/rest/v1/auth/me'),
        headers: await _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Got current user from backend API');
        return data;
      } else {
        debugPrint('❌ Failed to get current user: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        throw Exception('User not authenticated');
      }
    } catch (e) {
      debugPrint('❌ Failed to get current user: $e');
      throw Exception('Failed to load user info: $e');
    }
  }

  /// Update user setting (Supabase Auto REST API)
  /// PATCH /rest/v1/users/{userId}
  Future<void> updateUserSetting(String key, dynamic value) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabaseService.client
          .from('users')
          .update({key: value})
          .eq('id', userId);

      debugPrint('✅ User setting updated: $key = $value');
    } catch (e) {
      debugPrint('❌ Failed to update user setting: $e');
      throw Exception('Failed to update user setting: $e');
    }
  }

  /// Get user calendar data (custom aggregation)
  /// GET /api/v1/users/{userId}/calendar
  Future<Map<String, dynamic>> getUserCalendarData({
    required int year,
    required int month,
  }) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final queryParams = {
        'year': year.toString(),
        'month': month.toString(),
      };

      final uri = Uri.parse('${AppConstants.nestJsApiUrl}/api/v1/users/$userId/calendar')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get calendar data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Failed to get calendar data: $e');
      throw Exception('Failed to load calendar data: $e');
    }
  }

  /// Get user workout dates (from workout sessions)
  /// GET /api/v1/users/{userId}/sessions with COMPLETED status
  /// Returns a Set of DateTime objects representing dates when user completed workouts
  Future<Set<DateTime>> getUserWorkoutDates() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        debugPrint('⚠️ User not authenticated, returning empty workout dates');
        return {};
      }

      debugPrint('📅 Fetching workout dates for user: $userId');

      // Get completed workout sessions from backend
      final uri = Uri.parse('${AppConstants.nestJsApiUrl}/api/v1/users/$userId/sessions')
          .replace(queryParameters: {
        'status': 'COMPLETED',
        'limit': '100', // Get last 100 completed sessions
      });

      final response = await http.get(uri, headers: await _headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final sessions = data['data'] as List;

        debugPrint('✅ Found ${sessions.length} completed workout sessions');

        // Extract unique dates from completed_at timestamps
        final workoutDates = <DateTime>{};
        for (final session in sessions) {
          if (session['completedAt'] != null || session['completed_at'] != null) {
            final completedAtStr = session['completedAt'] ?? session['completed_at'];
            final completedAt = DateTime.parse(completedAtStr);
            // Normalize to date only (remove time)
            final dateOnly = DateTime(completedAt.year, completedAt.month, completedAt.day);
            workoutDates.add(dateOnly);
          }
        }

        debugPrint('📊 Extracted ${workoutDates.length} unique workout dates');
        return workoutDates;
      } else {
        debugPrint('⚠️ Failed to get workout sessions: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      debugPrint('❌ Failed to get workout dates: $e');
      return {}; // Return empty set instead of throwing, so UI can still render
    }
  }
}