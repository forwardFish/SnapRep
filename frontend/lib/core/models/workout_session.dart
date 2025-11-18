import 'package:json_annotation/json_annotation.dart';
import 'exercise.dart';
import 'workout_intent.dart';
import 'target_muscle.dart';

part 'workout_session.g.dart';

/// 训练会话状态
enum WorkoutSessionStatus {
  @JsonValue('PENDING')
  pending('PENDING', '准备中'),

  @JsonValue('IN_PROGRESS')
  inProgress('IN_PROGRESS', '进行中'),

  @JsonValue('COMPLETED')
  completed('COMPLETED', '已完成'),

  @JsonValue('CANCELLED')
  cancelled('CANCELLED', '已取消'),

  @JsonValue('FAILED')
  failed('FAILED', '失败');

  const WorkoutSessionStatus(this.code, this.displayName);

  final String code;
  final String displayName;

  static WorkoutSessionStatus fromCode(String code) {
    return WorkoutSessionStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => WorkoutSessionStatus.pending,
    );
  }
}

/// 训练会话模型
@JsonSerializable()
class WorkoutSession {
  /// 会话ID
  final String id;

  /// 用户ID
  final String userId;

  /// 会话状态
  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  final WorkoutSessionStatus status;

  /// 运动意图
  @JsonKey(fromJson: _workoutIntentFromJson, toJson: _workoutIntentToJson)
  final WorkoutIntent intent;

  /// 场景
  final String? scenarioCode;

  /// 使用的器材代码列表
  final List<String> equipmentCodes;

  /// 目标肌肉群
  @JsonKey(fromJson: _targetMuscleListFromJson, toJson: _targetMuscleListToJson)
  final List<TargetMuscle> targetMuscles;

  /// 推荐的动作列表
  final List<Exercise> exercises;

  /// 替换候选动作列表
  final List<Exercise>? alternatives;

  /// 计划总时长（秒）
  final int plannedDurationSec;

  /// 实际完成时长（秒）
  final int? actualDurationSec;

  /// 完成的动作数量
  final int? completedExerciseCount;

  /// 跳过的动作数量
  final int? skippedExerciseCount;

  /// 预计消耗卡路里
  final int? estimatedCalories;

  /// 实际消耗卡路里
  final int? actualCalories;

  /// 创建时间
  final DateTime createdAt;

  /// 开始时间
  final DateTime? startedAt;

  /// 完成时间
  final DateTime? completedAt;

  /// 取消时间
  final DateTime? cancelledAt;

  /// 备注信息
  final String? notes;

  /// 是否为主题周训练
  final bool? isThemeWeek;

  /// 主题周ID
  final String? themeWeekId;

  const WorkoutSession({
    required this.id,
    required this.userId,
    required this.status,
    required this.intent,
    this.scenarioCode,
    required this.equipmentCodes,
    required this.targetMuscles,
    required this.exercises,
    this.alternatives,
    required this.plannedDurationSec,
    this.actualDurationSec,
    this.completedExerciseCount,
    this.skippedExerciseCount,
    this.estimatedCalories,
    this.actualCalories,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    this.cancelledAt,
    this.notes,
    this.isThemeWeek,
    this.themeWeekId,
  });

  /// 是否已开始
  bool get hasStarted =>
    status == WorkoutSessionStatus.inProgress ||
    status == WorkoutSessionStatus.completed;

  /// 是否已完成
  bool get isCompleted => status == WorkoutSessionStatus.completed;

  /// 是否进行中
  bool get isInProgress => status == WorkoutSessionStatus.inProgress;

  /// 是否可以开始
  bool get canStart => status == WorkoutSessionStatus.pending;

  /// 完成进度（0.0 - 1.0）
  double get completionProgress {
    if (!hasStarted || exercises.isEmpty) return 0.0;
    if (isCompleted) return 1.0;

    final completed = completedExerciseCount ?? 0;
    return completed / exercises.length;
  }

  /// 获取动作总数
  int get totalExerciseCount => exercises.length;

  /// 获取场景显示名称
  String get scenarioDisplayName {
    if (scenarioCode == null) return '自由训练';

    switch (scenarioCode) {
      case 'office':
        return '办公室';
      case 'home':
      case 'living_room':
        return '家里';
      case 'gym':
        return '健身房';
      case 'travel':
        return '旅途';
      case 'park':
        return '公园';
      default:
        return scenarioCode ?? '未知';
    }
  }

  /// 获取器材显示名称
  String get equipmentDisplayNames {
    if (equipmentCodes.isEmpty) return '无器材';

    final names = equipmentCodes.map((code) {
      switch (code) {
        case 'hands_free':
          return '空手';
        case 'chair':
          return '椅子';
        case 'wall':
          return '墙面';
        case 'bottle':
          return '水瓶';
        case 'backpack':
          return '背包';
        case 'sofa':
          return '沙发';
        case 'stairs':
          return '台阶';
        case 'bench':
          return '长椅';
        default:
          return code;
      }
    }).toList();

    return names.join('、');
  }

  /// 获取训练摘要
  String get trainingDescription {
    final parts = <String>[];

    if (scenarioCode != null) {
      parts.add(scenarioDisplayName);
    }

    parts.add(intent.displayName);

    if (equipmentCodes.isNotEmpty) {
      parts.add(equipmentDisplayNames);
    }

    if (actualDurationSec != null) {
      final minutes = (actualDurationSec! / 60).round();
      parts.add('${minutes}分钟');
    } else {
      final minutes = (plannedDurationSec / 60).round();
      parts.add('约${minutes}分钟');
    }

    return parts.join(' · ');
  }

  /// 获取难度等级
  ExerciseDifficulty get overallDifficulty {
    if (exercises.isEmpty) return ExerciseDifficulty.beginner;

    // 计算平均难度
    final difficultyValues = exercises.map((ex) {
      switch (ex.difficulty) {
        case ExerciseDifficulty.beginner:
          return 1;
        case ExerciseDifficulty.intermediate:
          return 2;
        case ExerciseDifficulty.advanced:
          return 3;
        case ExerciseDifficulty.expert:
          return 4;
      }
    }).toList();

    final avgDifficulty = difficultyValues.reduce((a, b) => a + b) / difficultyValues.length;

    if (avgDifficulty <= 1.5) return ExerciseDifficulty.beginner;
    if (avgDifficulty <= 2.5) return ExerciseDifficulty.intermediate;
    if (avgDifficulty <= 3.5) return ExerciseDifficulty.advanced;
    return ExerciseDifficulty.expert;
  }

  /// 是否包含静音动作
  bool get hasSilentExercises {
    return exercises.any((ex) => ex.isSilent);
  }

  /// 获取主要作用部位描述
  String get primaryMuscleDescription {
    if (targetMuscles.isEmpty) return '综合训练';
    if (targetMuscles.length == 1) return targetMuscles.first.displayName;
    return targetMuscles.map((m) => m.displayName).join('、');
  }

  /// JSON序列化方法
  factory WorkoutSession.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionFromJson(json);

  Map<String, dynamic> toJson() => _$WorkoutSessionToJson(this);

  /// 复制并修改
  WorkoutSession copyWith({
    String? id,
    String? userId,
    WorkoutSessionStatus? status,
    WorkoutIntent? intent,
    String? scenarioCode,
    List<String>? equipmentCodes,
    List<TargetMuscle>? targetMuscles,
    List<Exercise>? exercises,
    List<Exercise>? alternatives,
    int? plannedDurationSec,
    int? actualDurationSec,
    int? completedExerciseCount,
    int? skippedExerciseCount,
    int? estimatedCalories,
    int? actualCalories,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
    DateTime? cancelledAt,
    String? notes,
    bool? isThemeWeek,
    String? themeWeekId,
  }) {
    return WorkoutSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      intent: intent ?? this.intent,
      scenarioCode: scenarioCode ?? this.scenarioCode,
      equipmentCodes: equipmentCodes ?? this.equipmentCodes,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      exercises: exercises ?? this.exercises,
      alternatives: alternatives ?? this.alternatives,
      plannedDurationSec: plannedDurationSec ?? this.plannedDurationSec,
      actualDurationSec: actualDurationSec ?? this.actualDurationSec,
      completedExerciseCount: completedExerciseCount ?? this.completedExerciseCount,
      skippedExerciseCount: skippedExerciseCount ?? this.skippedExerciseCount,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      actualCalories: actualCalories ?? this.actualCalories,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      notes: notes ?? this.notes,
      isThemeWeek: isThemeWeek ?? this.isThemeWeek,
      themeWeekId: themeWeekId ?? this.themeWeekId,
    );
  }

  @override
  String toString() {
    return 'WorkoutSession(id: $id, status: ${status.displayName}, exercises: ${exercises.length})';
  }
}

// JSON序列化辅助方法
WorkoutSessionStatus _statusFromJson(String code) => WorkoutSessionStatus.fromCode(code);
String _statusToJson(WorkoutSessionStatus status) => status.code;

WorkoutIntent _workoutIntentFromJson(String code) => WorkoutIntent.fromCode(code);
String _workoutIntentToJson(WorkoutIntent intent) => intent.code;

List<TargetMuscle> _targetMuscleListFromJson(List<dynamic> codes) =>
    codes.map((code) => TargetMuscle.fromCode(code.toString())).toList();
List<String> _targetMuscleListToJson(List<TargetMuscle> muscles) =>
    muscles.map((muscle) => muscle.code).toList();