// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Exercise _$ExerciseFromJson(Map<String, dynamic> json) => Exercise(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      primaryMuscle: _targetMuscleFromJson(json['primaryMuscle'] as String),
      secondaryMuscles:
          _targetMuscleListFromJson(json['secondaryMuscles'] as List),
      intentType: _workoutIntentFromJson(json['intentType'] as String),
      difficulty: _difficultyFromJson(json['difficulty'] as String),
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      sets: (json['sets'] as num).toInt(),
      repetitions: (json['repetitions'] as num?)?.toInt(),
      demoImageUrl: json['demoImageUrl'] as String?,
      demoVideoUrl: json['demoVideoUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      keyPoints:
          (json['keyPoints'] as List<dynamic>).map((e) => e as String).toList(),
      safetyWarnings: (json['safetyWarnings'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      benefits: json['benefits'] as String,
      tags: _tagsFromJson(json['tags'] as List),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$ExerciseToJson(Exercise instance) => <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'name': instance.name,
      'description': instance.description,
      'primaryMuscle': _targetMuscleToJson(instance.primaryMuscle),
      'secondaryMuscles': _targetMuscleListToJson(instance.secondaryMuscles),
      'intentType': _workoutIntentToJson(instance.intentType),
      'difficulty': _difficultyToJson(instance.difficulty),
      'durationSeconds': instance.durationSeconds,
      'sets': instance.sets,
      'repetitions': instance.repetitions,
      'demoImageUrl': instance.demoImageUrl,
      'demoVideoUrl': instance.demoVideoUrl,
      'thumbnailUrl': instance.thumbnailUrl,
      'keyPoints': instance.keyPoints,
      'safetyWarnings': instance.safetyWarnings,
      'benefits': instance.benefits,
      'tags': _tagsToJson(instance.tags),
      'isActive': instance.isActive,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
