import 'package:flutter/foundation.dart';
import '../models/scenario.dart';
import '../models/equipment.dart';
import '../models/theme_week.dart';
import '../services/api_service.dart';
import '../services/default_data_service.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final DefaultDataService _defaultDataService = DefaultDataService.instance;

  // Loading states
  bool _isLoadingScenarios = false;
  bool _isLoadingEquipment = false;
  bool _isLoadingThemeWeek = false;
  bool _isJoiningThemeWeek = false;

  // Data
  List<Scenario> _scenarios = [];
  List<Equipment> _equipment = [];
  ThemeWeek? _currentThemeWeek;

  // Error states
  String? _scenariosError;
  String? _equipmentError;
  String? _themeWeekError;

  // Getters
  bool get isLoadingScenarios => _isLoadingScenarios;
  bool get isLoadingEquipment => _isLoadingEquipment;
  bool get isLoadingThemeWeek => _isLoadingThemeWeek;
  bool get isJoiningThemeWeek => _isJoiningThemeWeek;

  List<Scenario> get scenarios => _scenarios;
  List<Equipment> get equipment => _equipment;
  ThemeWeek? get currentThemeWeek => _currentThemeWeek;

  String? get scenariosError => _scenariosError;
  String? get equipmentError => _equipmentError;
  String? get themeWeekError => _themeWeekError;

  bool get isLoading => _isLoadingScenarios || _isLoadingEquipment || _isLoadingThemeWeek;

  // Methods

  /// Load all homepage data
  Future<void> loadHomeData() async {
    await Future.wait([
      loadScenarios(),
      loadEquipment(),
      loadCurrentThemeWeek(),
    ]);
  }

  /// Load scenarios
  Future<void> loadScenarios() async {
    _isLoadingScenarios = true;
    _scenariosError = null;
    notifyListeners();

    try {
      _scenarios = await _apiService.getScenarios();
      _scenariosError = null;
      debugPrint('✅ Scenarios loaded successfully from API: ${_scenarios.length} scenarios');
    } catch (e) {
      debugPrint('❌ API failed to load scenarios: $e');

      // Show error to user but only fallback if we have no data at all
      _scenariosError = 'Failed to load scenarios from server: ${e.toString().split(':').first}';

      if (_scenarios.isEmpty) {
        debugPrint('⚠️ Using default scenarios as emergency fallback');
        _scenarios = _defaultDataService.getDefaultScenarios();
        // Keep the error message so user knows there was a problem
      }
    } finally {
      _isLoadingScenarios = false;
      notifyListeners();
    }
  }

  /// Load equipment
  Future<void> loadEquipment() async {
    _isLoadingEquipment = true;
    _equipmentError = null;
    notifyListeners();

    try {
      _equipment = await _apiService.getEquipment();
      _equipmentError = null;
      debugPrint('✅ Equipment loaded successfully from API: ${_equipment.length} items');
    } catch (e) {
      debugPrint('❌ API failed to load equipment: $e');

      // Show error to user but only fallback if we have no data at all
      _equipmentError = 'Failed to load equipment from server: ${e.toString().split(':').first}';

      if (_equipment.isEmpty) {
        debugPrint('⚠️ Using default equipment as emergency fallback');
        _equipment = _defaultDataService.getDefaultEquipment();
        // Keep the error message so user knows there was a problem
      }
    } finally {
      _isLoadingEquipment = false;
      notifyListeners();
    }
  }

  /// Load current theme week
  Future<void> loadCurrentThemeWeek() async {
    debugPrint('🔄 Starting to load current theme week...');
    _isLoadingThemeWeek = true;
    _themeWeekError = null;
    notifyListeners();

    try {
      debugPrint('📡 Calling API service to get current theme week...');
      _currentThemeWeek = await _apiService.getCurrentThemeWeek();
      _themeWeekError = null;

      if (_currentThemeWeek != null) {
        debugPrint('✅ Successfully loaded theme week: ${_currentThemeWeek!.title}');
      } else {
        debugPrint('ℹ️ No current theme week found from API');
      }
    } catch (e) {
      debugPrint('❌ API failed to load theme week: $e');

      // Show error to user but only fallback if we have no data at all
      _themeWeekError = 'Failed to load theme week from server: ${e.toString().split(':').first}';

      if (_currentThemeWeek == null) {
        debugPrint('⚠️ Using default theme week as emergency fallback');
        _currentThemeWeek = _defaultDataService.getDefaultThemeWeek();

        if (_currentThemeWeek != null) {
          debugPrint('🔄 Using default theme week: ${_currentThemeWeek!.title}');
        } else {
          debugPrint('❌ Even default theme week is null!');
        }
        // Keep the error message so user knows there was a problem
      }
    } finally {
      _isLoadingThemeWeek = false;
      debugPrint('🏁 Theme week loading completed. IsLoading: $_isLoadingThemeWeek');
      notifyListeners();
    }
  }

  /// Join current theme week
  Future<bool> joinThemeWeek() async {
    if (_currentThemeWeek == null) return false;

    _isJoiningThemeWeek = true;
    notifyListeners();

    try {
      await _apiService.joinThemeWeek(_currentThemeWeek!.id);
      // Reload theme week data to get updated participation status
      await loadCurrentThemeWeek();
      return true;
    } catch (e) {
      _themeWeekError = e.toString();
      return false;
    } finally {
      _isJoiningThemeWeek = false;
      notifyListeners();
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadHomeData();
  }
}