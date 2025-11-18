import 'package:json_annotation/json_annotation.dart';

part 'workout_intent.g.dart';

/// 运动意图类型枚举
/// 对应业务文档中的4种训练类型
enum WorkoutIntent {
  /// 放松 - 降紧张/舒缓神经
  @JsonValue('RELAX')
  relax('RELAX', '放松', '降紧张/舒缓神经', '🧘'),

  /// 舒展筋骨 - 拉伸与活动度
  @JsonValue('STRETCH')
  stretch('STRETCH', '舒展筋骨', '拉伸与活动度', '🤸'),

  /// 适当运动 - 轻汗/微心率
  @JsonValue('LIGHT_CARDIO')
  lightCardio('LIGHT_CARDIO', '适当运动', '轻汗/微心率', '🏃'),

  /// 主体锻炼 - 轻力量/稳定性
  @JsonValue('STRENGTH')
  strength('STRENGTH', '主体锻炼', '轻力量/稳定性', '💪');

  const WorkoutIntent(this.code, this.displayName, this.description, this.emoji);

  /// API传递的代码值
  final String code;

  /// 显示名称
  final String displayName;

  /// 描述文本
  final String description;

  /// 表情符号
  final String emoji;

  /// 从代码值获取枚举
  static WorkoutIntent fromCode(String code) {
    return WorkoutIntent.values.firstWhere(
      (intent) => intent.code == code,
      orElse: () => WorkoutIntent.stretch, // 默认值：舒展筋骨
    );
  }

  /// 获取背景颜色
  String get backgroundColor {
    switch (this) {
      case WorkoutIntent.relax:
        return '#9B59B6'; // 紫色
      case WorkoutIntent.stretch:
        return '#2ECC71'; // 绿色
      case WorkoutIntent.lightCardio:
        return '#F39C12'; // 橙色
      case WorkoutIntent.strength:
        return '#E74C3C'; // 红色
    }
  }

  /// 获取英文标题（用于UI Badge）
  String get englishName {
    switch (this) {
      case WorkoutIntent.relax:
        return 'Relaxation';
      case WorkoutIntent.stretch:
        return 'Flexibility';
      case WorkoutIntent.lightCardio:
        return 'Cardio';
      case WorkoutIntent.strength:
        return 'Power Training';
    }
  }

  /// 获取副标题描述
  String get subtitle {
    switch (this) {
      case WorkoutIntent.relax:
        return 'Reduce muscle tension\nGentle movements';
      case WorkoutIntent.stretch:
        return 'Improve mobility\nIncrease range of motion';
      case WorkoutIntent.lightCardio:
        return 'Light sweat session\nModerate heart rate';
      case WorkoutIntent.strength:
        return 'Build muscle strength\nResistance exercises';
    }
  }
}

/// 运动意图选择数据模型
@JsonSerializable()
class WorkoutIntentSelection {
  /// 选中的运动意图列表（最多2个）
  final List<WorkoutIntent> selectedIntents;

  /// 选择时间戳
  final DateTime selectedAt;

  WorkoutIntentSelection({
    required this.selectedIntents,
    DateTime? selectedAt,
  }) : selectedAt = selectedAt ?? DateTime.now() {
    if (selectedIntents.length > 2) {
      throw ArgumentError('最多只能选择2种运动意图');
    }
  }

  /// 获取主要运动意图
  WorkoutIntent get primaryIntent => selectedIntents.isNotEmpty
    ? selectedIntents.first
    : WorkoutIntent.stretch;

  /// 是否多选
  bool get isMultipleSelection => selectedIntents.length > 1;

  /// JSON序列化
  factory WorkoutIntentSelection.fromJson(Map<String, dynamic> json) =>
      _$WorkoutIntentSelectionFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutIntentSelectionToJson(this);

  /// 复制并修改
  WorkoutIntentSelection copyWith({
    List<WorkoutIntent>? selectedIntents,
    DateTime? selectedAt,
  }) {
    return WorkoutIntentSelection(
      selectedIntents: selectedIntents ?? this.selectedIntents,
      selectedAt: selectedAt ?? this.selectedAt,
    );
  }

  @override
  String toString() {
    return 'WorkoutIntentSelection(intents: ${selectedIntents.map((i) => i.displayName).join(", ")})';
  }
}