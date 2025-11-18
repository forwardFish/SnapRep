import 'package:json_annotation/json_annotation.dart';

part 'reward_card.g.dart';

@JsonSerializable()
class RewardCard {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String cardType; // 'completion', 'achievement', 'milestone'
  final int points;
  final DateTime earnedAt;
  final Map<String, dynamic> metadata;

  const RewardCard({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.cardType,
    required this.points,
    required this.earnedAt,
    this.metadata = const {},
  });

  factory RewardCard.fromJson(Map<String, dynamic> json) =>
      _$RewardCardFromJson(json);

  Map<String, dynamic> toJson() => _$RewardCardToJson(this);

  // 工厂方法创建不同类型的奖励卡片
  factory RewardCard.workoutCompletion({
    required String exerciseName,
    required int setsCompleted,
    required Duration totalTime,
  }) {
    return RewardCard(
      id: 'workout_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Workout Champion!',
      description: 'Completed $exerciseName with $setsCompleted sets in ${totalTime.inMinutes}m ${totalTime.inSeconds % 60}s',
      imageUrl: 'assets/images/cards/workout_completion.png',
      cardType: 'completion',
      points: setsCompleted * 10,
      earnedAt: DateTime.now(),
      metadata: {
        'exerciseName': exerciseName,
        'setsCompleted': setsCompleted,
        'totalTime': totalTime.inSeconds,
      },
    );
  }

  factory RewardCard.streakAchievement({
    required int streakDays,
  }) {
    return RewardCard(
      id: 'streak_${DateTime.now().millisecondsSinceEpoch}',
      title: '${streakDays} Day Streak!',
      description: 'Amazing dedication! You\'ve worked out for $streakDays consecutive days.',
      imageUrl: 'assets/images/cards/streak_achievement.png',
      cardType: 'achievement',
      points: streakDays * 20,
      earnedAt: DateTime.now(),
      metadata: {
        'streakDays': streakDays,
      },
    );
  }

  factory RewardCard.milestone({
    required String milestone,
    required int totalWorkouts,
  }) {
    return RewardCard(
      id: 'milestone_${DateTime.now().millisecondsSinceEpoch}',
      title: milestone,
      description: 'Congratulations! You\'ve completed $totalWorkouts total workouts.',
      imageUrl: 'assets/images/cards/milestone_achievement.png',
      cardType: 'milestone',
      points: totalWorkouts * 5,
      earnedAt: DateTime.now(),
      metadata: {
        'milestone': milestone,
        'totalWorkouts': totalWorkouts,
      },
    );
  }
}