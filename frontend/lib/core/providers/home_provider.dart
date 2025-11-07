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
    } catch (e) {
      // Fallback to default data when API fails
      debugPrint('⚠️  API failed, using default scenarios: $e');
      _scenarios = _defaultDataService.getDefaultScenarios();
      // Don't set error when we have fallback data
      _scenariosError = null;
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
    } catch (e) {
      // Fallback to default data when API fails
      debugPrint('⚠️  API failed, using default equipment: $e');
      _equipment = _defaultDataService.getDefaultEquipment();
      // Don't set error when we have fallback data
      _equipmentError = null;
    } finally {
      _isLoadingEquipment = false;
      notifyListeners();
    }
  }

  /// Load current theme week
  Future<void> loadCurrentThemeWeek() async {
    _isLoadingThemeWeek = true;
    _themeWeekError = null;
    notifyListeners();

    try {
      _currentThemeWeek = await _apiService.getCurrentThemeWeek();
      _themeWeekError = null;
    } catch (e) {
      // Fallback to default data when API fails
      debugPrint('⚠️  API failed, using default theme week: $e');
      _currentThemeWeek = _defaultDataService.getDefaultThemeWeek();
      // Don't set error when we have fallback data
      _themeWeekError = null;
    } finally {
      _isLoadingThemeWeek = false;
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