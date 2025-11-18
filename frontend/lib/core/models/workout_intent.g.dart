// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_intent.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WorkoutIntentSelection _$WorkoutIntentSelectionFromJson(
        Map<String, dynamic> json) =>
    WorkoutIntentSelection(
      selectedIntents: (json['selectedIntents'] as List<dynamic>)
          .map((e) => $enumDecode(_$WorkoutIntentEnumMap, e))
          .toList(),
      selectedAt: json['selectedAt'] == null
          ? null
          : DateTime.parse(json['selectedAt'] as String),
    );

Map<String, dynamic> _$WorkoutIntentSelectionToJson(
        WorkoutIntentSelection instance) =>
    <String, dynamic>{
      'selectedIntents': instance.selectedIntents
          .map((e) => _$WorkoutIntentEnumMap[e]!)
          .toList(),
      'selectedAt': instance.selectedAt.toIso8601String(),
    };

const _$WorkoutIntentEnumMap = {
  WorkoutIntent.relax: 'RELAX',
  WorkoutIntent.stretch: 'STRETCH',
  WorkoutIntent.lightCardio: 'LIGHT_CARDIO',
  WorkoutIntent.strength: 'STRENGTH',
};
