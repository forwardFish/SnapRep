// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_week.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ThemeWeek _$ThemeWeekFromJson(Map<String, dynamic> json) => ThemeWeek(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      equipmentCode: json['equipment_code'] as String,
      startDate: json['start_date'] as String,
      endDate: json['end_date'] as String,
      targetExerciseCount: (json['target_exercise_count'] as num).toInt(),
      participation: json['participation'] == null
          ? null
          : ThemeWeekParticipation.fromJson(
              json['participation'] as Map<String, dynamic>),
      globalStats: json['global_stats'] == null
          ? null
          : GlobalStats.fromJson(json['global_stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ThemeWeekToJson(ThemeWeek instance) => <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'title': instance.title,
      'description': instance.description,
      'equipment_code': instance.equipmentCode,
      'start_date': instance.startDate,
      'end_date': instance.endDate,
      'target_exercise_count': instance.targetExerciseCount,
      'participation': instance.participation,
      'global_stats': instance.globalStats,
    };

ThemeWeekParticipation _$ThemeWeekParticipationFromJson(
        Map<String, dynamic> json) =>
    ThemeWeekParticipation(
      isJoined: json['is_joined'] as bool,
      progress: Progress.fromJson(json['progress'] as Map<String, dynamic>),
      timeLeft: json['time_left'] as String,
    );

Map<String, dynamic> _$ThemeWeekParticipationToJson(
        ThemeWeekParticipation instance) =>
    <String, dynamic>{
      'is_joined': instance.isJoined,
      'progress': instance.progress,
      'time_left': instance.timeLeft,
    };

Progress _$ProgressFromJson(Map<String, dynamic> json) => Progress(
      completed: (json['completed'] as num).toInt(),
      target: (json['target'] as num).toInt(),
      percentage: (json['percentage'] as num).toDouble(),
    );

Map<String, dynamic> _$ProgressToJson(Progress instance) => <String, dynamic>{
      'completed': instance.completed,
      'target': instance.target,
      'percentage': instance.percentage,
    };

GlobalStats _$GlobalStatsFromJson(Map<String, dynamic> json) => GlobalStats(
      totalParticipants: (json['total_participants'] as num).toInt(),
      completionRate: (json['completion_rate'] as num).toDouble(),
    );

Map<String, dynamic> _$GlobalStatsToJson(GlobalStats instance) =>
    <String, dynamic>{
      'total_participants': instance.totalParticipants,
      'completion_rate': instance.completionRate,
    };
