import 'package:flutter/foundation.dart';
import '../models/scenario.dart';
import '../models/equipment.dart';
import '../services/api_service.dart';
import '../services/default_data_service.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final DefaultDataService _defaultDataService = DefaultDataService.instance;

  // Loading states
  bool _isLoadingScenarios = false;
  bool _isLoadingEquipment = false;

  // Data
  List<Scenario> _scenarios = [];
  List<Equipment> _equipment = [];

  // Error states
  String? _scenariosError;
  String? _equipmentError;

  // Getters
  bool get isLoadingScenarios => _isLoadingScenarios;
  bool get isLoadingEquipment => _isLoadingEquipment;

  List<Scenario> get scenarios => _scenarios;
  List<Equipment> get equipment => _equipment;

  String? get scenariosError => _scenariosError;
  String? get equipmentError => _equipmentError;

  bool get isLoading => _isLoadingScenarios || _isLoadingEquipment;

  // Methods

  /// Load all homepage data
  Future<void> loadHomeData() async {
    await Future.wait([
      loadScenarios(),
      loadEquipment(),
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

  /// Refresh all data
  Future<void> refresh() async {
    await loadHomeData();
  }
}