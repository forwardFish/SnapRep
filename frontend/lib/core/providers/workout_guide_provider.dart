import 'package:flutter/material.dart';
import '../models/workout_intent.dart';
import '../models/target_muscle.dart';
import '../models/scenario.dart';
import '../models/equipment.dart';
import '../services/exercise_service.dart';
import '../utils/error_handler.dart';

/// 引导页状态管理Provider
/// 管理3步引导流程的状态和数据传递
class WorkoutGuideProvider with ChangeNotifier {
  // Services
  final ExerciseService _exerciseService = ExerciseService();
  // Step 1: 运动意图选择
  List<WorkoutIntent> _selectedIntents = [];

  // Step 2: 场景与器材选择
  Scenario? _selectedScenario;
  List<Equipment> _selectedEquipment = [];

  // Step 3: 目标部位选择
  List<TargetMuscle> _selectedTargetMuscles = [];

  // 预选数据（从首页传入）
  Map<String, dynamic>? _preSelectedData;

  // 当前步骤
  int _currentStep = 1;

  // 加载状态
  bool _isLoading = false;

  // 错误信息
  String? _error;

  // Getters
  List<WorkoutIntent> get selectedIntents => _selectedIntents;
  WorkoutIntent? get selectedIntent => _selectedIntents.isNotEmpty ? _selectedIntents.first : null;
  Scenario? get selectedScenario => _selectedScenario;
  List<Equipment> get selectedEquipment => _selectedEquipment;
  List<TargetMuscle> get selectedTargetMuscles => _selectedTargetMuscles;
  Map<String, dynamic>? get preSelectedData => _preSelectedData;
  int get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 验证各步骤是否完成
  bool get isStep1Valid => _selectedIntents.isNotEmpty;
  bool get canProceedToStep2 => isStep1Valid;
  bool get isStep2Valid => _selectedScenario != null && _selectedEquipment.isNotEmpty;
  bool get canProceedToStep3 => isStep2Valid;
  bool get isStep3Valid => _selectedTargetMuscles.isNotEmpty;
  bool get canGenerateWorkout => isStep1Valid && isStep2Valid && isStep3Valid; // ✅ 必须所有步骤都完成
  bool get isAllStepsValid => isStep1Valid && isStep2Valid && isStep3Valid;

  // Mock data getters for Step2 and Step3 pages
  bool get isLoadingScenarios => _isLoading;
  bool get isLoadingEquipment => _isLoading;
  bool get isLoadingTargetMuscles => _isLoading;
  bool get isGeneratingWorkout => _isLoading;

  List<String> get availableScenarios => ['office', 'home', 'park', 'gym'];
  List<String> get availableEquipment => ['chair', 'wall', 'hands_free', 'bottle'];
  List<TargetMuscle> get availableTargetMuscles => TargetMuscle.values;

  // Mock data generators for actual objects
  List<Scenario> get availableScenariosObjects => [
    Scenario(id: '1', code: 'office', name: '办公室'),
    Scenario(id: '2', code: 'home', name: '家里'),
    Scenario(id: '3', code: 'park', name: '公园'),
    Scenario(id: '4', code: 'gym', name: '健身房'),
  ];

  List<Equipment> get availableEquipmentObjects => [
    Equipment(id: '1', code: 'chair', name: '椅子', category: 'furniture'),
    Equipment(id: '2', code: 'wall', name: '墙面', category: 'wall'),
    Equipment(id: '3', code: 'hands_free', name: '空手', category: 'bodyweight'),
    Equipment(id: '4', code: 'bottle', name: '水瓶', category: 'carry'),
  ];

  /// 初始化引导页（从路由参数或重置）
  void initializeGuide({Map<String, dynamic>? preSelected}) {
    debugPrint('🎯 Initializing workout guide with preSelected: $preSelected');

    _preSelectedData = preSelected;
    _currentStep = 1;
    _error = null;

    // 处理预选数据
    if (preSelected != null) {
      // 处理预选器材（从首页物品选择进入）
      if (preSelected['preSelectedEquipment'] != null) {
        final equipmentCodes = List<String>.from(preSelected['preSelectedEquipment']);
        _selectedEquipment = availableEquipmentObjects
            .where((eq) => equipmentCodes.contains(eq.code))
            .toList();
        debugPrint('🔧 Pre-selected equipment: ${_selectedEquipment.map((e) => e.name)}');
      }

      // 处理预选场景（从首页场景选择进入）
      if (preSelected['preSelectedScenario'] != null) {
        final scenarioCode = preSelected['preSelectedScenario'];
        _selectedScenario = availableScenariosObjects
            .firstWhere((s) => s.code == scenarioCode,
                orElse: () => availableScenariosObjects.first);
        debugPrint('🏠 Pre-selected scenario: ${_selectedScenario?.name}');
      }

      // 处理预选意图
      if (preSelected['preSelectedIntent'] != null) {
        final intentCode = preSelected['preSelectedIntent'];
        _selectedIntents = [WorkoutIntent.fromCode(intentCode)];
        debugPrint('🎯 Pre-selected intent: $_selectedIntents');
      }
    } else {
      // 重置所有状态
      _selectedIntents = [];
      _selectedScenario = null;
      _selectedEquipment = [];
      _selectedTargetMuscles = [];
    }

    notifyListeners();
  }

  /// 初始化第一步 (Step 1 specific initialization)
  void initializeStep1() {
    debugPrint('🎯 Initializing step 1');
    _currentStep = 1;
    _error = null;
    notifyListeners();
  }

  /// 初始化第二步 (Step 2 specific initialization)
  void initializeStep2() {
    debugPrint('🏠 Initializing step 2');
    _currentStep = 2;
    _error = null;
    notifyListeners();
  }

  /// 初始化第三步 (Step 3 specific initialization)
  void initializeStep3() {
    debugPrint('💪 Initializing step 3');
    _currentStep = 3;
    _error = null;
    notifyListeners();
  }

  /// Step 1: 选择运动意图
  void selectIntent(WorkoutIntent intent) {
    debugPrint('🎯 Selecting workout intent: ${intent.displayName}');

    if (_selectedIntents.contains(intent)) {
      _selectedIntents.remove(intent);
    } else if (_selectedIntents.length < 2) {
      _selectedIntents.add(intent);
    } else {
      // 最多选择2个，替换第一个
      _selectedIntents[0] = intent;
    }

    _error = null;
    notifyListeners();
  }

  /// 清除所有意图选择
  void clearIntents() {
    _selectedIntents.clear();
    notifyListeners();
  }

  /// Step 2: 选择场景
  void selectScenario(Scenario scenario) {
    debugPrint('🏠 Selecting scenario: ${scenario.name}');

    _selectedScenario = scenario;

    // 场景改变时，更新推荐器材（可选实现）
    _updateRecommendedEquipmentForScenario(scenario.code);

    _error = null;
    notifyListeners();
  }

  /// Step 2: 选择场景 (by code for compatibility)
  void selectScenarioByCode(String scenarioCode) {
    final scenario = availableScenariosObjects
        .firstWhere((s) => s.code == scenarioCode,
            orElse: () => availableScenariosObjects.first);
    selectScenario(scenario);
  }

  /// 更新场景对应的推荐器材
  void _updateRecommendedEquipmentForScenario(String scenarioCode) {
    // 如果没有预选器材，则根据场景设置推荐器材
    if (_preSelectedData?['preSelectedEquipment'] == null) {
      switch (scenarioCode) {
        case 'office':
          // 办公室推荐：椅子、墙面、水瓶
          break;
        case 'home':
        case 'living_room':
          // 家里推荐：沙发、空手
          break;
        case 'park':
          // 公园推荐：长椅、空手
          break;
        case 'gym':
          // 健身房推荐：各种器材
          break;
      }
    }
  }

  /// Step 2: 选择器材
  void toggleEquipment(Equipment equipment) {
    debugPrint('🔧 Toggling equipment: ${equipment.name}');

    if (_selectedEquipment.contains(equipment)) {
      _selectedEquipment.remove(equipment);
    } else {
      _selectedEquipment.add(equipment);
    }

    _error = null;
    notifyListeners();
  }

  /// Step 2: 选择器材 (by code for compatibility)
  void toggleEquipmentByCode(String equipmentCode) {
    final equipment = availableEquipmentObjects
        .firstWhere((eq) => eq.code == equipmentCode,
            orElse: () => availableEquipmentObjects.first);
    toggleEquipment(equipment);
  }

  /// 清除所有器材选择
  void clearEquipment() {
    _selectedEquipment.clear();
    notifyListeners();
  }

  /// Step 3: 选择目标部位
  void selectTargetMuscle(TargetMuscle muscle) {
    debugPrint('💪 Selecting target muscle: ${muscle.displayName}');

    if (_selectedTargetMuscles.contains(muscle)) {
      _selectedTargetMuscles.remove(muscle);
    } else if (_selectedTargetMuscles.length < 2) {
      _selectedTargetMuscles.add(muscle);
    } else {
      // 最多选择2个，替换第一个
      _selectedTargetMuscles[0] = muscle;
    }

    _error = null;
    notifyListeners();
  }

  /// Step 3: 切换目标部位选择状态 (alias for compatibility)
  void toggleTargetMuscle(TargetMuscle muscle) {
    selectTargetMuscle(muscle);
  }

  /// 清除所有部位选择
  void clearTargetMuscles() {
    _selectedTargetMuscles.clear();
    notifyListeners();
  }

  /// 下一步
  void nextStep() {
    if (_currentStep < 3) {
      _currentStep++;
      debugPrint('➡️ Moving to step $_currentStep');
      notifyListeners();
    }
  }

  /// 上一步
  void previousStep() {
    if (_currentStep > 1) {
      _currentStep--;
      debugPrint('⬅️ Moving to step $_currentStep');
      notifyListeners();
    }
  }

  /// 跳转到指定步骤
  void goToStep(int step) {
    if (step >= 1 && step <= 3) {
      _currentStep = step;
      debugPrint('🎯 Jumping to step $_currentStep');
      notifyListeners();
    }
  }

  /// 获取当前引导数据（用于API调用）
  Map<String, dynamic> getCurrentGuideData() {
    final data = <String, dynamic>{
      'intents': _selectedIntents.map((intent) => intent.code).toList(),
      'scenario': _selectedScenario?.code,
      'equipment': _selectedEquipment.map((eq) => eq.code).toList(),
      'targetMuscles': _selectedTargetMuscles.map((muscle) => muscle.code).toList(),
      'currentStep': _currentStep,
    };

    debugPrint('📋 Current guide data: $data');
    return data;
  }

  /// 验证当前步骤数据
  bool validateCurrentStep() {
    switch (_currentStep) {
      case 1:
        return isStep1Valid;
      case 2:
        return isStep2Valid;
      case 3:
        return isStep3Valid;
      default:
        return false;
    }
  }

  /// 获取当前步骤验证错误信息
  String? getCurrentStepError() {
    switch (_currentStep) {
      case 1:
        if (_selectedIntents.isEmpty) {
          return '请选择至少一种运动意图';
        }
        break;
      case 2:
        if (_selectedScenario == null) {
          return '请选择一个训练场景';
        }
        if (_selectedEquipment.isEmpty) {
          return '请选择至少一种器材';
        }
        break;
      case 3:
        if (_selectedTargetMuscles.isEmpty) {
          return '请选择至少一个目标部位';
        }
        break;
    }
    return null;
  }

  /// 设置加载状态
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 设置错误信息
  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  /// 生成训练推荐 (Step 3 completion)
  Future<Map<String, dynamic>?> generateWorkoutRecommendation() async {
    debugPrint('🚀 Generating workout recommendation');

    // 详细验证每个步骤
    if (!isStep1Valid) {
      setError('请先在 Step 1 选择运动意图');
      return null;
    }

    if (!isStep2Valid) {
      if (_selectedScenario == null) {
        setError('请先在 Step 2 选择训练场景');
      } else if (_selectedEquipment.isEmpty) {
        setError('请先在 Step 2 选择至少一个器材');
      }
      return null;
    }

    if (!isStep3Valid) {
      setError('请至少选择一个目标部位');
      return null;
    }

    setLoading(true);

    try {
      // Get first selected intent (required)
      final selectedIntent = _selectedIntents.first;

      // Get equipment codes
      final equipmentCodes = _selectedEquipment.map((eq) => eq.code).toList();

      // Get scenario code (required) - 现在已经确保不为 null
      final scenarioCode = _selectedScenario!.code;

      debugPrint('📤 Request params: intent=${selectedIntent.code}, equipment=$equipmentCodes, scenario=$scenarioCode, muscles=${_selectedTargetMuscles.map((m) => m.code).toList()}');

      // Call backend API for quick recommendation
      final response = await _exerciseService.getQuickRecommendation(
        intent: selectedIntent,
        equipmentCodes: equipmentCodes,
        scenarioCode: scenarioCode,
        targetMuscles: _selectedTargetMuscles,
      );

      debugPrint('✅ Generated recommendation from backend: $response');

      // Transform API response to the format expected by WorkoutResult
      final recommendationParams = {
        // Original guide data
        'intents': _selectedIntents.map((intent) => intent.code).toList(),
        'scenario': _selectedScenario?.code,
        'equipment': equipmentCodes,
        'targetMuscles': _selectedTargetMuscles.map((muscle) => muscle.code).toList(),
        'currentStep': _currentStep,

        // Backend API response data
        'apiResponse': response,
        'exercises': response['exercises'] ?? [],
        'alternatives': response['alternatives'] ?? [],
        'intent': response['intent'] ?? selectedIntent.code,
        'totalDuration': response['totalDuration'] ?? 0,
        'difficulty': response['difficulty'] ?? 'GREEN',
      };

      return recommendationParams;
    } catch (e) {
      debugPrint('❌ Failed to generate workout recommendation: $e');

      // ✅ 使用统一的错误处理器
      String errorMessage;

      if (e is ErrorInfo) {
        // 如果是 ErrorInfo 对象，直接使用其 message
        errorMessage = e.message;
        debugPrint('📋 Error code: ${e.code}, category: ${e.category}');
        debugPrint('📋 Original message: ${e.originalMessage}');
      } else {
        // 其他未知错误
        errorMessage = '操作失败，请稍后重试';
        debugPrint('⚠️ Unknown error type: ${e.runtimeType}');
      }

      setError(errorMessage);
      return null;
    } finally {
      setLoading(false);
    }
  }

  /// 重置所有数据
  void reset() {
    debugPrint('🔄 Resetting workout guide');

    _selectedIntents = [];
    _selectedScenario = null;
    _selectedEquipment = [];
    _selectedTargetMuscles = [];
    _preSelectedData = null;
    _currentStep = 1;
    _isLoading = false;
    _error = null;

    notifyListeners();
  }

  /// Debug: 打印当前状态
  void debugPrintState() {
    debugPrint('=== Workout Guide State ===');
    debugPrint('Step: $_currentStep');
    debugPrint('Intents: ${_selectedIntents.map((i) => i.displayName)}');
    debugPrint('Scenario: $_selectedScenario');
    debugPrint('Equipment: $_selectedEquipment');
    debugPrint('Target Muscles: ${_selectedTargetMuscles.map((m) => m.displayName)}');
    debugPrint('Valid: Step1=$isStep1Valid, Step2=$isStep2Valid, Step3=$isStep3Valid');
    debugPrint('Loading: $_isLoading, Error: $_error');
    debugPrint('========================');
  }
}