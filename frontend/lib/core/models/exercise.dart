import 'package:json_annotation/json_annotation.dart';
import 'target_muscle.dart';
import 'workout_intent.dart';

part 'exercise.g.dart';

/// 动作难度等级
enum ExerciseDifficulty {
  @JsonValue('BEGINNER')
  beginner('BEGINNER', 'Beginner', '🟢', '#4CAF50'), // 初级

  @JsonValue('INTERMEDIATE')
  intermediate('INTERMEDIATE', 'Intermediate', '🟡', '#FF9800'), // 中级

  @JsonValue('ADVANCED')
  advanced('ADVANCED', 'Advanced', '🟠', '#FF5722'), // 高级

  @JsonValue('EXPERT')
  expert('EXPERT', 'Expert', '🔴', '#F44336'); // 专家

  const ExerciseDifficulty(this.code, this.displayName, this.emoji, this.color);

  final String code;
  final String displayName;
  final String emoji;
  final String color;

  static ExerciseDifficulty fromCode(String code) {
    return ExerciseDifficulty.values.firstWhere(
      (difficulty) => difficulty.code == code,
      orElse: () => ExerciseDifficulty.beginner,
    );
  }
}

/// 动作标签类型
enum ExerciseTag {
  standing('standing', 'Standing'), // 站立
  sitting('sitting', 'Sitting'), // 坐姿
  lying('lying', 'Lying'), // 平躺
  wall('wall', 'Wall'), // 靠墙
  chair('chair', 'Chair'), // 椅子
  bottle('bottle', 'Bottle'), // 水瓶
  handsFreee('hands_free', 'Hands Free'), // 空手
  stretch('stretch', 'Stretch'), // 拉伸
  strength('strength', 'Strength'), // 力量
  cardio('cardio', 'Cardio'), // 有氧
  silent('silent', 'Silent'), // 静音
  smallSpace('small_space', 'Small Space'), // 小空间
  balance('balance', 'Balance'); // 平衡

  const ExerciseTag(this.code, this.displayName);

  final String code;
  final String displayName;

  static ExerciseTag fromCode(String code) {
    return ExerciseTag.values.firstWhere(
      (tag) => tag.code == code,
      orElse: () => ExerciseTag.handsFreee,
    );
  }
}

/// 锻炼动作模型
@JsonSerializable()
class Exercise {
  /// 动作ID
  final String id;

  /// 动作代码
  final String code;

  /// 动作名称
  final String name;

  /// 动作描述
  final String description;

  /// 主要锻炼部位
  @JsonKey(fromJson: _targetMuscleFromJson, toJson: _targetMuscleToJson)
  final TargetMuscle primaryMuscle;

  /// 次要锻炼部位
  @JsonKey(fromJson: _targetMuscleListFromJson, toJson: _targetMuscleListToJson)
  final List<TargetMuscle> secondaryMuscles;

  /// 适合的运动意图
  @JsonKey(fromJson: _workoutIntentFromJson, toJson: _workoutIntentToJson)
  final WorkoutIntent intentType;

  /// 难度等级
  @JsonKey(fromJson: _difficultyFromJson, toJson: _difficultyToJson)
  final ExerciseDifficulty difficulty;

  /// 持续时间（秒）
  final int durationSeconds;

  /// 组数
  final int sets;

  /// 重复次数（可为空，表示按时间进行）
  final int? repetitions;

  /// 示例图片URL
  final String? demoImageUrl;

  /// 示例视频URL
  final String? demoVideoUrl;

  /// 缩略图URL
  final String? thumbnailUrl;

  /// 动作要领
  final List<String> keyPoints;

  /// 安全提示/警告
  final List<String> safetyWarnings;

  /// 动作好处/作用
  final String benefits;

  /// 标签
  @JsonKey(fromJson: _tagsFromJson, toJson: _tagsToJson)
  final List<ExerciseTag> tags;

  /// 是否启用
  final bool isActive;

  /// 创建时间
  final DateTime? createdAt;

  /// 更新时间
  final DateTime? updatedAt;

  const Exercise({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.primaryMuscle,
    required this.secondaryMuscles,
    required this.intentType,
    required this.difficulty,
    required this.durationSeconds,
    required this.sets,
    this.repetitions,
    this.demoImageUrl,
    this.demoVideoUrl,
    this.thumbnailUrl,
    required this.keyPoints,
    required this.safetyWarnings,
    required this.benefits,
    required this.tags,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  /// 获取预计总时长（包括组间休息）
  int get totalDurationSeconds {
    if (sets <= 1) return durationSeconds;

    // 假设组间休息10秒
    final restTime = (sets - 1) * 10;
    return durationSeconds * sets + restTime;
  }

  /// 是否为静音动作
  bool get isSilent => tags.contains(ExerciseTag.silent);

  /// 是否适合小空间
  bool get isSmallSpace => tags.contains(ExerciseTag.smallSpace);

  /// 是否需要器材
  bool get requiresEquipment => !tags.contains(ExerciseTag.handsFreee);

  /// 获取器材需求描述
  String get equipmentDescription {
    final equipmentTags = tags.where((tag) => [
      ExerciseTag.chair,
      ExerciseTag.bottle,
      ExerciseTag.wall,
    ].contains(tag)).toList();

    if (equipmentTags.isEmpty) return 'No equipment needed'; // 无需器材
    return equipmentTags.map((tag) => tag.displayName).join(', ');
  }

  /// 获取动作类型描述
  String get typeDescription {
    final typeTags = tags.where((tag) => [
      ExerciseTag.stretch,
      ExerciseTag.strength,
      ExerciseTag.cardio,
      ExerciseTag.balance,
    ].contains(tag)).toList();

    if (typeTags.isEmpty) return 'General Training'; // 综合训练
    return typeTags.map((tag) => tag.displayName).join(', ');
  }

  /// 获取姿势描述
  String get postureDescription {
    final postureTags = tags.where((tag) => [
      ExerciseTag.standing,
      ExerciseTag.sitting,
      ExerciseTag.lying,
    ].contains(tag)).toList();

    if (postureTags.isEmpty) return '';
    return postureTags.map((tag) => tag.displayName).join(', ');
  }

  /// JSON序列化方法
  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);

  Map<String, dynamic> toJson() => _$ExerciseToJson(this);

  /// 复制并修改
  Exercise copyWith({
    String? id,
    String? code,
    String? name,
    String? description,
    TargetMuscle? primaryMuscle,
    List<TargetMuscle>? secondaryMuscles,
    WorkoutIntent? intentType,
    ExerciseDifficulty? difficulty,
    int? durationSeconds,
    int? sets,
    int? repetitions,
    String? demoImageUrl,
    String? demoVideoUrl,
    String? thumbnailUrl,
    List<String>? keyPoints,
    List<String>? safetyWarnings,
    String? benefits,
    List<ExerciseTag>? tags,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exercise(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      primaryMuscle: primaryMuscle ?? this.primaryMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      intentType: intentType ?? this.intentType,
      difficulty: difficulty ?? this.difficulty,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      sets: sets ?? this.sets,
      repetitions: repetitions ?? this.repetitions,
      demoImageUrl: demoImageUrl ?? this.demoImageUrl,
      demoVideoUrl: demoVideoUrl ?? this.demoVideoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      keyPoints: keyPoints ?? this.keyPoints,
      safetyWarnings: safetyWarnings ?? this.safetyWarnings,
      benefits: benefits ?? this.benefits,
      tags: tags ?? this.tags,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, difficulty: ${difficulty.displayName}, duration: ${durationSeconds}s)';
  }
}

// JSON序列化辅助方法
TargetMuscle _targetMuscleFromJson(String code) => TargetMuscle.fromCode(code);
String _targetMuscleToJson(TargetMuscle muscle) => muscle.code;

List<TargetMuscle> _targetMuscleListFromJson(List<dynamic> codes) =>
    codes.map((code) => TargetMuscle.fromCode(code.toString())).toList();
List<String> _targetMuscleListToJson(List<TargetMuscle> muscles) =>
    muscles.map((muscle) => muscle.code).toList();

WorkoutIntent _workoutIntentFromJson(String code) => WorkoutIntent.fromCode(code);
String _workoutIntentToJson(WorkoutIntent intent) => intent.code;

ExerciseDifficulty _difficultyFromJson(String code) => ExerciseDifficulty.fromCode(code);
String _difficultyToJson(ExerciseDifficulty difficulty) => difficulty.code;

List<ExerciseTag> _tagsFromJson(List<dynamic> codes) =>
    codes.map((code) => ExerciseTag.fromCode(code.toString())).toList();
List<String> _tagsToJson(List<ExerciseTag> tags) =>
    tags.map((tag) => tag.code).toList();