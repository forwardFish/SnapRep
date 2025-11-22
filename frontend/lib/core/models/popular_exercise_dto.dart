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

  /// 难度等级
  final String difficulty;

  /// 持续时间（秒）
  final int durationSeconds;

  /// 示例图片URL
  final String? demoImageUrl;

  /// 缩略图URL
  final String? thumbnailUrl;

  /// 热门程度评分
  final int popularityScore;

  const PopularExerciseDto({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.primaryMuscle,
    required this.difficulty,
    required this.durationSeconds,
    this.demoImageUrl,
    this.thumbnailUrl,
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
      difficulty: json['difficulty'] as String,
      durationSeconds: json['durationSeconds'] as int,
      demoImageUrl: json['demoImageUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
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
      'difficulty': difficulty,
      'durationSeconds': durationSeconds,
      'demoImageUrl': demoImageUrl,
      'thumbnailUrl': thumbnailUrl,
      'popularityScore': popularityScore,
    };
  }

  /// 获取难度显示文本
  String get difficultyText {
    switch (difficulty.toUpperCase()) {
      case 'BEGINNER':
        return 'Beginner';
      case 'INTERMEDIATE':
        return 'Intermediate';
      case 'ADVANCED':
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
        return '#4CAF50';
      case 'INTERMEDIATE':
        return '#FF9800';
      case 'ADVANCED':
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
}