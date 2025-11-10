import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/scenario.dart';
import '../models/equipment.dart';
import '../models/theme_week.dart';
import 'supabase_service.dart';

class ApiService {
  static ApiService? _instance;
  late SupabaseService _supabaseService;

  ApiService._internal() {
    _supabaseService = SupabaseService.instance;
  }

  static ApiService get instance {
    _instance ??= ApiService._internal();
    return _instance!;
  }

  // Helper method to get authorization headers
  Map<String, String> get _headers {
    final token = _supabaseService.client.auth.currentSession?.accessToken;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Homepage APIs

  /// Get scenarios list (Supabase Auto REST API)
  /// GET /rest/v1/scenarios
  Future<List<Scenario>> getScenarios({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _supabaseService.client
          .from('scenarios')
          .select('*')
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .limit(pageSize)
          .range((page - 1) * pageSize, page * pageSize - 1);

      return (response as List)
          .map((json) => Scenario.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load scenarios: $e');
    }
  }

  /// Get equipment list (Supabase Auto REST API)
  /// GET /rest/v1/equipment
  Future<List<Equipment>> getEquipment({int page = 1, int pageSize = 20}) async {
    try {
      final response = await _supabaseService.client
          .from('equipment')
          .select('*')
          .eq('is_active', true)
          .order('display_order', ascending: true)
          .limit(pageSize)
          .range((page - 1) * pageSize, page * pageSize - 1);

      return (response as List)
          .map((json) => Equipment.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load equipment: $e');
    }
  }

  /// Get current theme week (NestJS Custom API)
  /// GET /api/v1/theme-weeks/current
  Future<ThemeWeek?> getCurrentThemeWeek() async {
    try {
      final url = '${AppConstants.nestJsApiUrl}/theme-weeks/current';
      print('🌐 Making API call to: $url');
      print('📋 Headers: $_headers');

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
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
        Uri.parse('${AppConstants.nestJsApiUrl}/theme-weeks/$themeWeekId/join'),
        headers: _headers,
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
        Uri.parse('${AppConstants.nestJsApiUrl}/ai/recognize-equipment'),
      );

      // Add headers
      request.headers.addAll(_headers);

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
}