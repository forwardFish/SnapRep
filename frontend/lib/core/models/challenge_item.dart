class ChallengeItem {
  final String id;
  final String code;
  final String title;
  final String equipmentId;
  final int? timeLimit;
  final int targetCount;
  final String description;
  final String? instructions;
  final bool isPopular;
  final double trendingScore;
  final bool isActive;
  final int displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChallengeItem({
    required this.id,
    required this.code,
    required this.title,
    required this.equipmentId,
    this.timeLimit,
    required this.targetCount,
    required this.description,
    this.instructions,
    required this.isPopular,
    required this.trendingScore,
    required this.isActive,
    required this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChallengeItem.fromJson(Map<String, dynamic> json) {
    return ChallengeItem(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      equipmentId: json['equipment_id'] as String,
      timeLimit: json['time_limit'] as int?,
      targetCount: json['target_count'] as int? ?? 3,
      description: json['description'] as String,
      instructions: json['instructions'] as String?,
      isPopular: json['is_popular'] as bool? ?? false,
      trendingScore: (json['trending_score'] as num?)?.toDouble() ?? 0.0,
      isActive: json['is_active'] as bool? ?? true,
      displayOrder: json['display_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'equipment_id': equipmentId,
      'time_limit': timeLimit,
      'target_count': targetCount,
      'description': description,
      'instructions': instructions,
      'is_popular': isPopular,
      'trending_score': trendingScore,
      'is_active': isActive,
      'display_order': displayOrder,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for UI display
  String get displayName => title;

  String get estimatedTimeText {
    if (timeLimit == null) {
      return 'No time limit';
    }
    return '${timeLimit!} min';
  }

  String get targetText => '$targetCount exercises';
}