import '../models/scenario.dart';
import '../models/equipment.dart';
import '../models/theme_week.dart';

/// Default/Fallback data service for offline mode
/// 提供默认数据当后端服务不可用时
class DefaultDataService {
  static DefaultDataService? _instance;

  DefaultDataService._internal();

  static DefaultDataService get instance {
    _instance ??= DefaultDataService._internal();
    return _instance!;
  }

  /// Get default scenarios for fallback
  List<Scenario> getDefaultScenarios() {
    // Create scenarios from JSON to match API response format
    final defaultScenariosJson = [
      {
        'id': 'default-1',
        'code': 'OFFICE',
        'name': 'Office Workout',
        'description': 'Quick exercises perfect for office breaks',
        'icon_url': '🏢',
        'is_active': true,
      },
      {
        'id': 'default-2',
        'code': 'HOME',
        'name': 'Home Fitness',
        'description': 'Home-based exercises using household items',
        'icon_url': '🏠',
        'is_active': true,
      },
      {
        'id': 'default-3',
        'code': 'GYM',
        'name': 'Gym Training',
        'description': 'Professional gym equipment workouts',
        'icon_url': '🏋️',
        'is_active': true,
      },
      {
        'id': 'default-4',
        'code': 'OUTDOOR',
        'name': 'Outdoor Activities',
        'description': 'Fresh air exercises in parks and outdoors',
        'icon_url': '🌳',
        'is_active': true,
      },
    ];

    return defaultScenariosJson.map((json) => Scenario.fromJson(json)).toList();
  }

  /// Get default equipment for fallback
  List<Equipment> getDefaultEquipment() {
    // Create equipment from JSON to match API response format
    final defaultEquipmentJson = [
      {
        'id': 'default-eq-1',
        'code': 'WATER_BOTTLE',
        'name': 'Water Bottle',
        'category': 'BASIC',
        'icon_url': '💧',
        'is_active': true,
        'display_order': 1,
      },
      {
        'id': 'default-eq-2',
        'code': 'CHAIR',
        'name': 'Chair',
        'category': 'BASIC',
        'icon_url': '🪑',
        'is_active': true,
        'display_order': 2,
      },
      {
        'id': 'default-eq-3',
        'code': 'TOWEL',
        'name': 'Towel',
        'category': 'BASIC',
        'icon_url': '🤚',
        'is_active': true,
        'display_order': 3,
      },
      {
        'id': 'default-eq-4',
        'code': 'BOOK',
        'name': 'Book',
        'category': 'BASIC',
        'icon_url': '📚',
        'is_active': true,
        'display_order': 4,
      },
      {
        'id': 'default-eq-5',
        'code': 'BACKPACK',
        'name': 'Backpack',
        'category': 'WEIGHT',
        'icon_url': '🎒',
        'is_active': true,
        'display_order': 5,
      },
      {
        'id': 'default-eq-6',
        'code': 'WALL',
        'name': 'Wall',
        'category': 'BASIC',
        'icon_url': '🧱',
        'is_active': true,
        'display_order': 6,
      },
    ];

    return defaultEquipmentJson.map((json) => Equipment.fromJson(json)).toList();
  }

  /// Get default theme week for fallback
  ThemeWeek? getDefaultThemeWeek() {
    // Create theme week from JSON to match API response format
    final defaultThemeWeekJson = {
      'id': 'default-theme-1',
      'code': 'DEMO_WEEK',
      'title': 'Demo Week - Water Bottle Challenge',
      'description': 'Experience SnapRep with simple water bottle exercises. Perfect for getting started!',
      'equipment_code': 'WATER_BOTTLE',
      'start_date': '2024-11-01T00:00:00.000Z',
      'end_date': '2024-11-08T23:59:59.000Z',
      'target_exercise_count': 10,
      'participation': {
        'is_joined': false,
        'progress': {
          'completed': 0,
          'target': 10,
          'percentage': 0.0,
        },
        'time_left': '7 days',
      },
      'global_stats': {
        'total_participants': 1250,
        'completion_rate': 78.5,
      },
    };

    return ThemeWeek.fromJson(defaultThemeWeekJson);
  }
}