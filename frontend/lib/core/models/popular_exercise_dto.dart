/// 通用推荐动作DTO - 用于展示热门推荐动作（不依赖个人历史）
class PopularExerciseDto {
  /// 动作ID
  final String id;

  /// 动作代码
  final String code;

  /// 动作名称
  final String name;

  /// 动作描述
  final String description;

  /// 主要锻炼部位
  final String primaryMuscle;

  /// 次要锻炼部位
  final List<String> secondaryMuscles;

  /// 意图类型
  final String intentType;

  /// 难度等级
  final String difficulty;

  /// 持续时间（秒）
  final int durationSeconds;

  /// 组数
  final int sets;

  /// 时长类型
  final String durationType;

  /// 示例图片URL
  final String? demoImageUrl;

  /// 示例视频URL
  final String? demoVideoUrl;

  /// 缩略图URL
  final String? thumbnailUrl;

  /// 标签
  final List<String> tags;

  /// 关键要点
  final List<String> keyPoints;

  /// 动作步骤
  final List<String> steps;

  /// 安全警告
  final List<String> safetyWarnings;

  /// 热门程度评分
  final int popularityScore;

  const PopularExerciseDto({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.primaryMuscle,
    this.secondaryMuscles = const [],
    this.intentType = 'STRENGTH',
    required this.difficulty,
    required this.durationSeconds,
    this.sets = 3,
    this.durationType = 'REPS',
    this.demoImageUrl,
    this.demoVideoUrl,
    this.thumbnailUrl,
    this.tags = const [],
    this.keyPoints = const [],
    this.steps = const [],
    this.safetyWarnings = const [],
    required this.popularityScore,
  });

  /// 从JSON创建实例
  factory PopularExerciseDto.fromJson(Map<String, dynamic> json) {
    return PopularExerciseDto(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      primaryMuscle: json['primaryMuscle'] as String,
      secondaryMuscles: json['secondaryMuscles'] != null
          ? List<String>.from(json['secondaryMuscles'])
          : [],
      intentType: json['intentType'] as String? ?? 'STRENGTH',
      difficulty: json['difficulty'] as String,
      durationSeconds: json['durationSeconds'] as int,
      sets: json['sets'] as int? ?? 3,
      durationType: json['durationType'] as String? ?? 'REPS',
      demoImageUrl: json['demoImageUrl'] as String?,
      demoVideoUrl: json['demoVideoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      keyPoints: json['keyPoints'] != null
          ? List<String>.from(json['keyPoints'])
          : [],
      steps: json['steps'] != null ? List<String>.from(json['steps']) : [],
      safetyWarnings: json['safetyWarnings'] != null
          ? List<String>.from(json['safetyWarnings'])
          : [],
      popularityScore: json['popularityScore'] as int? ?? 0,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'primaryMuscle': primaryMuscle,
      'secondaryMuscles': secondaryMuscles,
      'intentType': intentType,
      'difficulty': difficulty,
      'durationSeconds': durationSeconds,
      'sets': sets,
      'durationType': durationType,
      'demoImageUrl': demoImageUrl,
      'demoVideoUrl': demoVideoUrl,
      'thumbnailUrl': thumbnailUrl,
      'tags': tags,
      'keyPoints': keyPoints,
      'steps': steps,
      'safetyWarnings': safetyWarnings,
      'popularityScore': popularityScore,
    };
  }

  /// 获取难度显示文本
  String get difficultyText {
    switch (difficulty.toUpperCase()) {
      case 'BEGINNER':
      case 'GREEN':
        return 'Beginner';
      case 'INTERMEDIATE':
      case 'BLUE':
        return 'Intermediate';
      case 'ADVANCED':
      case 'RED':
        return 'Advanced';
      case 'EXPERT':
        return 'Expert';
      default:
        return 'Unknown';
    }
  }

  /// 获取难度颜色
  String get difficultyColor {
    switch (difficulty.toUpperCase()) {
      case 'BEGINNER':
      case 'GREEN':
        return '#4CAF50';
      case 'INTERMEDIATE':
      case 'BLUE':
        return '#FF9800';
      case 'ADVANCED':
      case 'RED':
        return '#FF5722';
      case 'EXPERT':
        return '#F44336';
      default:
        return '#757575';
    }
  }

  /// 获取部位显示名称
  String get muscleDisplayName {
    switch (primaryMuscle.toLowerCase()) {
      case 'chest':
        return 'Chest';
      case 'back':
        return 'Back';
      case 'legs':
        return 'Legs';
      case 'glutes':
        return 'Glutes';
      case 'shoulders':
        return 'Shoulders';
      case 'arms':
        return 'Arms';
      case 'core':
        return 'Core';
      case 'full_body':
        return 'Full Body';
      case 'neck_shoulder':
        return 'Neck & Shoulders';
      default:
        return primaryMuscle.toUpperCase();
    }
  }

  /// 获取热门程度显示文本
  String get popularityText {
    if (popularityScore >= 90) return 'Trending';
    if (popularityScore >= 70) return 'Popular';
    if (popularityScore >= 50) return 'Recommended';
    return 'Featured';
  }

  /// 获取持续时间显示文本
  String get durationText {
    return '${durationSeconds}s';
  }

  /// 生成benefits文本（从keyPoints提取）
  String get benefits {
    if (keyPoints.isEmpty) {
      return 'Improves physical fitness, enhances overall strength, increases flexibility, and promotes better body awareness';
    }
    return keyPoints.join('. ');
  }
}
