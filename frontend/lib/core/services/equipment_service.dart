import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/equipment.dart';
import '../config/api_config.dart';

/// Service for managing equipment data and API calls
class EquipmentService {
  static const String _baseUrl = ApiConfig.baseUrl;

  /// Get all equipment items
  Future<List<Equipment>> getEquipment({
    int page = 1,
    int pageSize = 50,
    String? category,
    bool? includeInactive = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      };

      if (category != null) {
        queryParams['category'] = category;
      }

      if (includeInactive != null) {
        queryParams['includeInactive'] = includeInactive.toString();
      }

      final uri = Uri.parse('$_baseUrl/rest/v1/equipment')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> equipmentJson = data['data'] ?? [];

        return equipmentJson
            .map((json) => Equipment.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load equipment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get equipment by scenario code
  /// Returns equipment items that are commonly used in a specific scenario
  Future<List<Equipment>> getEquipmentByScenario(String scenarioCode) async {
    try {
      // For now, we'll get all equipment and filter by some logic
      // In a real implementation, this would be a specific API endpoint
      final allEquipment = await getEquipment(includeInactive: false);

      // Mock filtering logic based on scenario
      // This should be replaced with actual scenario-based filtering from the backend
      return _filterEquipmentByScenario(allEquipment, scenarioCode);
    } catch (e) {
      throw Exception('Failed to load equipment for scenario: $e');
    }
  }

  /// Get single equipment item by ID
  Future<Equipment> getEquipmentById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/rest/v1/equipment/$id'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Equipment.fromJson(data);
      } else if (response.statusCode == 404) {
        throw Exception('Equipment not found');
      } else {
        throw Exception('Failed to load equipment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get equipment by category
  Future<List<Equipment>> getEquipmentByCategory(String category) async {
    try {
      return await getEquipment(category: category, includeInactive: false);
    } catch (e) {
      throw Exception('Failed to load equipment by category: $e');
    }
  }

  /// Get active equipment list (most commonly used)
  Future<List<Equipment>> getActiveEquipment() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/rest/v1/equipment/active/list'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final List<dynamic> equipmentJson = json.decode(response.body);
        return equipmentJson
            .map((json) => Equipment.fromJson(json))
            .toList();
      } else {
        throw Exception('Failed to load active equipment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get grouped equipment by categories
  Future<Map<String, List<Equipment>>> getGroupedEquipment() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/rest/v1/equipment/category/grouped'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> groupedData = data['data'];
        final Map<String, List<Equipment>> result = {};

        groupedData.forEach((category, equipmentList) {
          result[category] = (equipmentList as List)
              .map((json) => Equipment.fromJson(json))
              .toList();
        });

        return result;
      } else {
        throw Exception('Failed to load grouped equipment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Get equipment statistics
  Future<Map<String, dynamic>> getEquipmentStats() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/rest/v1/equipment/stats/summary'),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load equipment stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  /// Private helper method to filter equipment by scenario
  /// This is a mock implementation - in production this should come from the backend
  List<Equipment> _filterEquipmentByScenario(List<Equipment> allEquipment, String scenarioCode) {
    // Define scenario-equipment mappings
    const Map<String, List<String>> scenarioEquipmentMap = {
      'office': ['FURNITURE', 'WALL', 'BOTTLE', 'BAG', 'FABRIC'],
      'home': ['FURNITURE', 'WALL', 'BOTTLE', 'BAG', 'STAIRS', 'FABRIC', 'STICK'],
      'travel': ['BOTTLE', 'BAG', 'FABRIC', 'WALL'],
      'outdoor': ['OUTDOOR', 'BOTTLE', 'BAG', 'STAIRS', 'STICK'],
    };

    final allowedCategories = scenarioEquipmentMap[scenarioCode] ??
        scenarioEquipmentMap['office']!;

    return allEquipment
        .where((equipment) => allowedCategories.contains(equipment.category))
        .toList();
  }

  /// Mock AI recognition result
  /// In production, this would call an actual AI service
  Future<List<Equipment>> recognizeEquipmentFromImage(String imagePath) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    try {
      // Mock recognition result - return some common equipment
      final allEquipment = await getEquipment(pageSize: 10);

      // Return first 3 items as "recognized" equipment
      return allEquipment.take(3).toList();
    } catch (e) {
      throw Exception('AI recognition failed: $e');
    }
  }

  /// Search equipment by name or code
  Future<List<Equipment>> searchEquipment(String query) async {
    try {
      final allEquipment = await getEquipment();

      // Simple client-side filtering
      // In production, this should be a server-side search endpoint
      final searchQuery = query.toLowerCase();

      return allEquipment.where((equipment) =>
          equipment.name.toLowerCase().contains(searchQuery) ||
          equipment.code.toLowerCase().contains(searchQuery)
      ).toList();
    } catch (e) {
      throw Exception('Equipment search failed: $e');
    }
  }
}