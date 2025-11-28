import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../models/scenario.dart';

/// 训练配置状态管理
/// 管理整个训练流程的选择状态和数据传递
class WorkoutConfigProvider extends ChangeNotifier {
  // 选择状态
  String? _selectedScenario;
  List<Equipment> _selectedEquipment = [];
  String? _selectedIntent;
  Set<String> _targetMuscles = {};
  int _targetDuration = 60; // 默认60秒
  String _difficulty = 'GREEN';

  // 流程状态
  bool _isLoading = false;
  String? _error;

  // Getters
  String? get selectedScenario => _selectedScenario;
  List<Equipment> get selectedEquipment => List.from(_selectedEquipment);
  String? get selectedIntent => _selectedIntent;
  Set<String> get targetMuscles => Set.from(_targetMuscles);
  int get targetDuration => _targetDuration;
  String get difficulty => _difficulty;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // 流程完成度检查
  bool get canProceedToStep2 => _selectedEquipment.isNotEmpty;
  bool get canProceedToStep3 => _selectedIntent != null;
  bool get canGenerateWorkout => _targetMuscles.isNotEmpty;

  /// 设置场景
  void setScenario(String? scenario) {
    _selectedScenario = scenario;
    notifyListeners();
  }

  /// 切换器材选择状态
  void toggleEquipment(Equipment equipment) {
    if (_selectedEquipment.any((e) => e.id == equipment.id)) {
      _selectedEquipment.removeWhere((e) => e.id == equipment.id);
    } else {
      _selectedEquipment.add(equipment);
    }
    notifyListeners();
  }

  /// 批量设置器材
  void setEquipment(List<Equipment> equipment) {
    _selectedEquipment = List.from(equipment);
    notifyListeners();
  }

  /// 移除特定器材
  void removeEquipment(Equipment equipment) {
    _selectedEquipment.removeWhere((e) => e.id == equipment.id);
    notifyListeners();
  }

  /// 设置运动意图
  void setIntent(String? intent) {
    _selectedIntent = intent;
    notifyListeners();
  }

  /// 切换目标肌群
  void toggleMuscle(String muscle) {
    if (_targetMuscles.contains(muscle)) {
      _targetMuscles.remove(muscle);
    } else {
      _targetMuscles.add(muscle);
    }
    notifyListeners();
  }

  /// 设置目标时长
  void setTargetDuration(int duration) {
    _targetDuration = duration;
    notifyListeners();
  }

  /// 设置难度
  void setDifficulty(String difficulty) {
    _difficulty = difficulty;
    notifyListeners();
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

  /// 生成推荐请求参数
  Map<String, dynamic> generateRequest() {
    return {
      'intentType': _selectedIntent ?? 'MODERATE',
      'equipmentCodes': _selectedEquipment.map((e) => e.code).toList(),
      'scenarioCode': _selectedScenario,
      'targetMuscles': _targetMuscles.toList(),
      'totalDuration': _targetDuration,
      'difficulty': _difficulty,
      'count': 3,
    };
  }

  /// 从预设数据设置状态（用于快速选择流程）
  void setFromPreset(Map<String, dynamic> preset) {
    if (preset['scenario'] != null) {
      _selectedScenario = preset['scenario'];
    }
    if (preset['intent'] != null) {
      _selectedIntent = preset['intent'];
    }
    if (preset['equipment'] != null && preset['equipment'] is List) {
      // Note: 这里需要根据code查找Equipment对象
      // 实际实现中可能需要通过服务获取Equipment详情
    }
    if (preset['targetMuscles'] != null && preset['targetMuscles'] is List) {
      _targetMuscles = Set.from(preset['targetMuscles']);
    }
    if (preset['duration'] != null) {
      _targetDuration = preset['duration'];
    }
    notifyListeners();
  }

  /// 重置所有状态
  void reset() {
    _selectedScenario = null;
    _selectedEquipment.clear();
    _selectedIntent = null;
    _targetMuscles.clear();
    _targetDuration = 60;
    _difficulty = 'GREEN';
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  /// 获取当前步骤（用于进度指示器）
  int getCurrentStep() {
    if (_selectedEquipment.isEmpty) return 1; // 场景&器材选择
    if (_selectedIntent == null) return 2; // 运动意图选择
    if (_targetMuscles.isEmpty) return 3; // 重点部位选择
    return 4; // 完成
  }

  /// 获取流程进度百分比
  double getProgressPercentage() {
    int completedSteps = 0;
    const int totalSteps = 3;

    if (_selectedEquipment.isNotEmpty) completedSteps++;
    if (_selectedIntent != null) completedSteps++;
    if (_targetMuscles.isNotEmpty) completedSteps++;

    return completedSteps / totalSteps;
  }

  /// 获取当前选择的摘要文本
  String getSelectionSummary() {
    List<String> summary = [];

    if (_selectedScenario != null) {
      summary.add('场景: $_selectedScenario');
    }

    if (_selectedEquipment.isNotEmpty) {
      summary.add('器材: ${_selectedEquipment.map((e) => e.name).join(', ')}');
    }

    if (_selectedIntent != null) {
      summary.add('意图: $_selectedIntent');
    }

    if (_targetMuscles.isNotEmpty) {
      summary.add('部位: ${_targetMuscles.join(', ')}');
    }

    return summary.isEmpty ? 'No selection' : summary.join(' · ');
  }

  /// Validate current configuration
  bool validateConfiguration() {
    if (_selectedEquipment.isEmpty) {
      setError('Please select at least one equipment');
      return false;
    }

    if (_selectedIntent == null) {
      setError('Please select workout intent');
      return false;
    }

    if (_targetMuscles.isEmpty) {
      setError('Please select at least one target muscle');
      return false;
    }

    setError(null);
    return true;
  }

  /// 调试信息输出
  void debugPrint() {
    print('=== Workout Config Debug ===');
    print('Scenario: $_selectedScenario');
    print('Equipment: ${_selectedEquipment.map((e) => e.name).toList()}');
    print('Intent: $_selectedIntent');
    print('Muscles: $_targetMuscles');
    print('Duration: $_targetDuration');
    print('Difficulty: $_difficulty');
    print('Step: ${getCurrentStep()}/3');
    print('Progress: ${(getProgressPercentage() * 100).toInt()}%');
    print('===========================');
  }
}