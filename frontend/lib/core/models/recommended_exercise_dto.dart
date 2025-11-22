/// 推荐动作DTO - 用于展示用户最常训练的动作
class RecommendedExerciseDto {
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

  /// 训练次数
  final int trainedCount;

  /// 最后训练时间
  final DateTime? lastTrainedAt;

  const RecommendedExerciseDto({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.primaryMuscle,
    required this.difficulty,
    required this.durationSeconds,
    this.demoImageUrl,
    this.thumbnailUrl,
    required this.trainedCount,
    this.lastTrainedAt,
  });

  /// 从JSON创建实例
  factory RecommendedExerciseDto.fromJson(Map<String, dynamic> json) {
    return RecommendedExerciseDto(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      primaryMuscle: json['primaryMuscle'] as String,
      difficulty: json['difficulty'] as String,
      durationSeconds: json['durationSeconds'] as int,
      demoImageUrl: json['demoImageUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      trainedCount: json['trainedCount'] as int,
      lastTrainedAt: json['lastTrainedAt'] != null
          ? DateTime.parse(json['lastTrainedAt'] as String)
          : null,
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
      'trainedCount': trainedCount,
      'lastTrainedAt': lastTrainedAt?.toIso8601String(),
    };
  }

  /// 获取难度显示文本
  String get difficultyText {
    switch (difficulty.toUpperCase()) {
      case 'BEGINNER':
        return '初级';
      case 'INTERMEDIATE':
        return '中级';
      case 'ADVANCED':
        return '高级';
      case 'EXPERT':
        return '专家';
      default:
        return '未知';
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
        return '胸部';
      case 'back':
        return '背部';
      case 'legs':
        return '腿部';
      case 'glutes':
        return '臀部';
      case 'shoulders':
        return '肩部';
      case 'arms':
        return '手臂';
      case 'core':
        return '核心';
      case 'full_body':
        return '全身';
      case 'neck_shoulder':
        return '颈肩';
      default:
        return primaryMuscle.toUpperCase();
    }
  }

  /// 获取训练次数显示文本
  String get trainedCountText {
    return '已训练 $trainedCount 次';
  }

  /// 获取最后训练时间显示文本
  String get lastTrainedText {
    if (lastTrainedAt == null) return '暂无记录';

    final now = DateTime.now();
    final diff = now.difference(lastTrainedAt!);

    if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }
}