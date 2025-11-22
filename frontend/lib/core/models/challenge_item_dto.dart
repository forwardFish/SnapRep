/// DTO for Challenge Item from API
/// Maps to ChallengeItemDto in backend
class ChallengeItemDto {
  final String id;
  final String code;
  final String name;
  final String emoji;
  final int difficulty;
  final String baseRarity;
  final int exerciseCount;
  final int estimatedMinutes;
  final String? description;
  final String? iconUrl;
  final String? imageUrl;
  final int totalParticipants;
  final int totalCompletions;
  final double completionRate;
  final bool isPopular;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChallengeItemDto({
    required this.id,
    required this.code,
    required this.name,
    required this.emoji,
    required this.difficulty,
    required this.baseRarity,
    required this.exerciseCount,
    required this.estimatedMinutes,
    this.description,
    this.iconUrl,
    this.imageUrl,
    required this.totalParticipants,
    required this.totalCompletions,
    required this.completionRate,
    required this.isPopular,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChallengeItemDto.fromJson(Map<String, dynamic> json) {
    return ChallengeItemDto(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '🏆',
      difficulty: json['difficulty'] as int? ?? 3,
      baseRarity: json['baseRarity'] as String? ?? 'COMMON',
      exerciseCount: json['exerciseCount'] as int? ?? 3,
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 10,
      description: json['description'] as String?,
      iconUrl: json['iconUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      totalParticipants: json['totalParticipants'] as int? ?? 0,
      totalCompletions: json['totalCompletions'] as int? ?? 0,
      completionRate: (json['completionRate'] as num?)?.toDouble() ?? 0.0,
      isPopular: json['isPopular'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'emoji': emoji,
      'difficulty': difficulty,
      'baseRarity': baseRarity,
      'exerciseCount': exerciseCount,
      'estimatedMinutes': estimatedMinutes,
      'description': description,
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
      'totalParticipants': totalParticipants,
      'totalCompletions': totalCompletions,
      'completionRate': completionRate,
      'isPopular': isPopular,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper methods for UI display
  String get displayName => name;

  String get estimatedTimeText => '$estimatedMinutes min';

  String get targetText => '$exerciseCount exercises';

  String get difficultyStars => '⭐' * difficulty;

  String get rarityColor {
    switch (baseRarity.toUpperCase()) {
      case 'LEGENDARY':
        return '#FFA500'; // Orange
      case 'EPIC':
        return '#9B59B6'; // Purple
      case 'RARE':
        return '#3498DB'; // Blue
      case 'COMMON':
      default:
        return '#95A5A6'; // Gray
    }
  }

  String get participationText {
    if (totalParticipants == 0) return 'Be the first!';
    return '$totalParticipants participants';
  }

  String get completionRateText {
    if (totalParticipants == 0) return 'No data';
    final percentage = (completionRate * 100).toStringAsFixed(0);
    return '$percentage% completion';
  }
}
