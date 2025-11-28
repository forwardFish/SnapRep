import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'target_muscle.g.dart';

/// 目标肌肉群枚举
/// 对应业务文档中的部位选择
enum TargetMuscle {
  /// 全身
  @JsonValue('FULL_BODY')
  fullBody('FULL_BODY', 'Full Body', 'Comprehensive training', '🏃'),

  /// 颈肩
  @JsonValue('NECK_SHOULDER')
  neckShoulder('NECK_SHOULDER', 'Neck & Shoulders', 'Relieve office stress', '💆'),

  /// 胸背
  @JsonValue('CHEST_BACK')
  chestBack('CHEST_BACK', 'Chest & Back', 'Improve posture', '🤸'),

  /// 核心
  @JsonValue('CORE')
  core('CORE', 'Core', 'Strengthen body center', '⚡'),

  /// 大腿
  @JsonValue('LEGS')
  legs('LEGS', 'Legs', 'Build lower body power', '🦵'),

  /// 臀部
  @JsonValue('GLUTES')
  glutes('GLUTES', 'Glutes', 'Shape and tighten', '🍑'),

  /// 小腿
  @JsonValue('CALVES')
  calves('CALVES', 'Calves', 'Define leg lines', '🦶'),

  /// 手臂
  @JsonValue('ARMS')
  arms('ARMS', 'Arms', 'Sculpt arm definition', '💪');

  const TargetMuscle(this.code, this.displayName, this.description, this.emoji);

  /// API传递的代码值
  final String code;

  /// 显示名称
  final String displayName;

  /// 描述文本
  final String description;

  /// 表情符号
  final String emoji;

  /// 从代码值获取枚举
  static TargetMuscle fromCode(String code) {
    return TargetMuscle.values.firstWhere(
      (muscle) => muscle.code == code,
      orElse: () => TargetMuscle.fullBody, // 默认值：全身
    );
  }

  /// 获取背景颜色
  String get backgroundColor {
    switch (this) {
      case TargetMuscle.fullBody:
        return '#3498DB'; // 蓝色
      case TargetMuscle.neckShoulder:
        return '#9B59B6'; // 紫色
      case TargetMuscle.chestBack:
        return '#E67E22'; // 橙色
      case TargetMuscle.core:
        return '#27AE60'; // 绿色
      case TargetMuscle.legs:
        return '#F39C12'; // 金色
      case TargetMuscle.glutes:
        return '#E74C3C'; // 红色
      case TargetMuscle.calves:
        return '#34495E'; // 深灰色
      case TargetMuscle.arms:
        return '#8E44AD'; // 深紫色
    }
  }

  /// 获取背景图片URL (从后端API获取)
  /// 图片命名规则: {muscle_code}_background.jpg
  /// 例如: FULL_BODY -> full_body_background.jpg
  String getBackgroundImageUrl(String apiBaseUrl) {
    final imageCode = code.toLowerCase();
    return '$apiBaseUrl/api/v1/assets/images/${imageCode}_background.jpg';
  }

  /// 获取Flutter Color对象
  Color get color {
    switch (this) {
      case TargetMuscle.fullBody:
        return const Color(0xFF3498DB);
      case TargetMuscle.neckShoulder:
        return const Color(0xFF9B59B6);
      case TargetMuscle.chestBack:
        return const Color(0xFFE67E22);
      case TargetMuscle.core:
        return const Color(0xFF27AE60);
      case TargetMuscle.legs:
        return const Color(0xFFF39C12);
      case TargetMuscle.glutes:
        return const Color(0xFFE74C3C);
      case TargetMuscle.calves:
        return const Color(0xFF34495E);
      case TargetMuscle.arms:
        return const Color(0xFF8E44AD);
    }
  }

  /// 是否为上半身
  bool get isUpperBody {
    return [
      TargetMuscle.neckShoulder,
      TargetMuscle.chestBack,
      TargetMuscle.arms
    ].contains(this);
  }

  /// 是否为下半身
  bool get isLowerBody {
    return [
      TargetMuscle.legs,
      TargetMuscle.glutes,
      TargetMuscle.calves
    ].contains(this);
  }

  /// 是否为核心部位
  bool get isCoreArea {
    return this == TargetMuscle.core;
  }

  /// 是否为推荐部位（用于UI显示）
  /// 注意：这是静态推荐，实际应该基于用户数据和意图动态计算
  bool get isRecommended {
    // 默认推荐：全身、颈肩、核心（最常见的训练需求）
    return [
      TargetMuscle.fullBody,
      TargetMuscle.neckShoulder,
      TargetMuscle.core,
    ].contains(this);
  }
}

/// 目标部位选择数据模型
@JsonSerializable()
class TargetMuscleSelection {
  /// 选中的目标部位列表（最多2个）
  final List<TargetMuscle> selectedMuscles;

  /// 选择时间戳
  final DateTime selectedAt;

  TargetMuscleSelection({
    required this.selectedMuscles,
    DateTime? selectedAt,
  }) : selectedAt = selectedAt ?? DateTime.now() {
    if (selectedMuscles.length > 2) {
      throw ArgumentError('Maximum 2 target muscles allowed');
    }
  }

  /// 获取主要目标部位
  TargetMuscle get primaryMuscle => selectedMuscles.isNotEmpty
    ? selectedMuscles.first
    : TargetMuscle.fullBody;

  /// 是否多选
  bool get isMultipleSelection => selectedMuscles.length > 1;

  /// 是否包含全身训练
  bool get includesFullBody => selectedMuscles.contains(TargetMuscle.fullBody);

  /// Get workout focus type
  String get focusType {
    if (includesFullBody || selectedMuscles.length > 1) {
      return 'Comprehensive Training';
    }

    final muscle = primaryMuscle;
    if (muscle.isUpperBody) {
      return 'Upper Body Focus';
    } else if (muscle.isLowerBody) {
      return 'Lower Body Focus';
    } else if (muscle.isCoreArea) {
      return 'Core Strengthening';
    } else {
      return 'General Training';
    }
  }

  /// JSON序列化
  factory TargetMuscleSelection.fromJson(Map<String, dynamic> json) =>
      _$TargetMuscleSelectionFromJson(json);

  Map<String, dynamic> toJson() => _$TargetMuscleSelectionToJson(this);

  /// 复制并修改
  TargetMuscleSelection copyWith({
    List<TargetMuscle>? selectedMuscles,
    DateTime? selectedAt,
  }) {
    return TargetMuscleSelection(
      selectedMuscles: selectedMuscles ?? this.selectedMuscles,
      selectedAt: selectedAt ?? this.selectedAt,
    );
  }

  @override
  String toString() {
    return 'TargetMuscleSelection(muscles: ${selectedMuscles.map((m) => m.displayName).join(", ")})';
  }
}