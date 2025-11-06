import 'package:json_annotation/json_annotation.dart';

part 'theme_week.g.dart';

@JsonSerializable()
class ThemeWeek {
  final String id;
  final String code;
  final String title;
  final String description;
  @JsonKey(name: 'equipment_code')
  final String equipmentCode;
  @JsonKey(name: 'start_date')
  final String startDate;
  @JsonKey(name: 'end_date')
  final String endDate;
  @JsonKey(name: 'target_exercise_count')
  final int targetExerciseCount;
  final ThemeWeekParticipation? participation;
  @JsonKey(name: 'global_stats')
  final GlobalStats? globalStats;

  ThemeWeek({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.equipmentCode,
    required this.startDate,
    required this.endDate,
    required this.targetExerciseCount,
    this.participation,
    this.globalStats,
  });

  factory ThemeWeek.fromJson(Map<String, dynamic> json) => _$ThemeWeekFromJson(json);
  Map<String, dynamic> toJson() => _$ThemeWeekToJson(this);
}

@JsonSerializable()
class ThemeWeekParticipation {
  @JsonKey(name: 'is_joined')
  final bool isJoined;
  final Progress progress;
  @JsonKey(name: 'time_left')
  final String timeLeft;

  ThemeWeekParticipation({
    required this.isJoined,
    required this.progress,
    required this.timeLeft,
  });

  factory ThemeWeekParticipation.fromJson(Map<String, dynamic> json) => _$ThemeWeekParticipationFromJson(json);
  Map<String, dynamic> toJson() => _$ThemeWeekParticipationToJson(this);
}

@JsonSerializable()
class Progress {
  final int completed;
  final int target;
  final double percentage;

  Progress({
    required this.completed,
    required this.target,
    required this.percentage,
  });

  factory Progress.fromJson(Map<String, dynamic> json) => _$ProgressFromJson(json);
  Map<String, dynamic> toJson() => _$ProgressToJson(this);
}

@JsonSerializable()
class GlobalStats {
  @JsonKey(name: 'total_participants')
  final int totalParticipants;
  @JsonKey(name: 'completion_rate')
  final double completionRate;

  GlobalStats({
    required this.totalParticipants,
    required this.completionRate,
  });

  factory GlobalStats.fromJson(Map<String, dynamic> json) => _$GlobalStatsFromJson(json);
  Map<String, dynamic> toJson() => _$GlobalStatsToJson(this);
}