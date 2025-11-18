// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'target_muscle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TargetMuscleSelection _$TargetMuscleSelectionFromJson(
        Map<String, dynamic> json) =>
    TargetMuscleSelection(
      selectedMuscles: (json['selectedMuscles'] as List<dynamic>)
          .map((e) => $enumDecode(_$TargetMuscleEnumMap, e))
          .toList(),
      selectedAt: json['selectedAt'] == null
          ? null
          : DateTime.parse(json['selectedAt'] as String),
    );

Map<String, dynamic> _$TargetMuscleSelectionToJson(
        TargetMuscleSelection instance) =>
    <String, dynamic>{
      'selectedMuscles': instance.selectedMuscles
          .map((e) => _$TargetMuscleEnumMap[e]!)
          .toList(),
      'selectedAt': instance.selectedAt.toIso8601String(),
    };

const _$TargetMuscleEnumMap = {
  TargetMuscle.fullBody: 'FULL_BODY',
  TargetMuscle.neckShoulder: 'NECK_SHOULDER',
  TargetMuscle.chestBack: 'CHEST_BACK',
  TargetMuscle.core: 'CORE',
  TargetMuscle.legs: 'LEGS',
  TargetMuscle.glutes: 'GLUTES',
  TargetMuscle.calves: 'CALVES',
  TargetMuscle.arms: 'ARMS',
};
