// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutSession _$WorkoutSessionFromJson(Map<String, dynamic> json) =>
    WorkoutSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      status: _statusFromJson(json['status'] as String),
      intent: _workoutIntentFromJson(json['intent'] as String),
      scenarioCode: json['scenarioCode'] as String?,
      equipmentCodes: (json['equipmentCodes'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      targetMuscles: _targetMuscleListFromJson(json['targetMuscles'] as List),
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      alternatives: (json['alternatives'] as List<dynamic>?)
          ?.map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      plannedDurationSec: (json['plannedDurationSec'] as num).toInt(),
      actualDurationSec: (json['actualDurationSec'] as num?)?.toInt(),
      completedExerciseCount: (json['completedExerciseCount'] as num?)?.toInt(),
      skippedExerciseCount: (json['skippedExerciseCount'] as num?)?.toInt(),
      estimatedCalories: (json['estimatedCalories'] as num?)?.toInt(),
      actualCalories: (json['actualCalories'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      cancelledAt: json['cancelledAt'] == null
          ? null
          : DateTime.parse(json['cancelledAt'] as String),
      notes: json['notes'] as String?,
      isThemeWeek: json['isThemeWeek'] as bool?,
      themeWeekId: json['themeWeekId'] as String?,
    );

Map<String, dynamic> _$WorkoutSessionToJson(WorkoutSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'status': _statusToJson(instance.status),
      'intent': _workoutIntentToJson(instance.intent),
      'scenarioCode': instance.scenarioCode,
      'equipmentCodes': instance.equipmentCodes,
      'targetMuscles': _targetMuscleListToJson(instance.targetMuscles),
      'exercises': instance.exercises,
      'alternatives': instance.alternatives,
      'plannedDurationSec': instance.plannedDurationSec,
      'actualDurationSec': instance.actualDurationSec,
      'completedExerciseCount': instance.completedExerciseCount,
      'skippedExerciseCount': instance.skippedExerciseCount,
      'estimatedCalories': instance.estimatedCalories,
      'actualCalories': instance.actualCalories,
      'createdAt': instance.createdAt.toIso8601String(),
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'cancelledAt': instance.cancelledAt?.toIso8601String(),
      'notes': instance.notes,
      'isThemeWeek': instance.isThemeWeek,
      'themeWeekId': instance.themeWeekId,
    };
