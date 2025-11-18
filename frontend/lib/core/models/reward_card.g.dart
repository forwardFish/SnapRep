// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reward_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RewardCard _$RewardCardFromJson(Map<String, dynamic> json) => RewardCard(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      cardType: json['cardType'] as String,
      points: (json['points'] as num).toInt(),
      earnedAt: DateTime.parse(json['earnedAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$RewardCardToJson(RewardCard instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'cardType': instance.cardType,
      'points': instance.points,
      'earnedAt': instance.earnedAt.toIso8601String(),
      'metadata': instance.metadata,
    };
