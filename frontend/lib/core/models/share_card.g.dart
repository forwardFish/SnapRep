// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'share_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardRarity _$CardRarityFromJson(Map<String, dynamic> json) => CardRarity(
      level: _rarityFromJson(json['level'] as String),
      score: (json['score'] as num).toDouble(),
      equipmentSeries: _seriesFromJson(json['equipmentSeries'] as String),
      specialTags: (json['specialTags'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      cityEdition: json['cityEdition'] as String?,
      globalRank: (json['globalRank'] as num?)?.toInt(),
      weeklyUsage: (json['weeklyUsage'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CardRarityToJson(CardRarity instance) =>
    <String, dynamic>{
      'level': _rarityToJson(instance.level),
      'score': instance.score,
      'equipmentSeries': _seriesToJson(instance.equipmentSeries),
      'specialTags': instance.specialTags,
      'cityEdition': instance.cityEdition,
      'globalRank': instance.globalRank,
      'weeklyUsage': instance.weeklyUsage,
    };

ShareCard _$ShareCardFromJson(Map<String, dynamic> json) => ShareCard(
      id: json['id'] as String,
      userId: json['userId'] as String,
      workoutSessionId: json['workoutSessionId'] as String,
      imageUrl: json['imageUrl'] as String,
      rarity: CardRarity.fromJson(json['rarity'] as Map<String, dynamic>),
      template: json['template'] as String,
      shareText: json['shareText'] as String,
      deepLink: json['deepLink'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
      isPublic: json['isPublic'] as bool? ?? false,
      shareCount: (json['shareCount'] as num?)?.toInt() ?? 0,
      favoriteCount: (json['favoriteCount'] as num?)?.toInt() ?? 0,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      renderTime: (json['renderTime'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ShareCardToJson(ShareCard instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'workoutSessionId': instance.workoutSessionId,
      'imageUrl': instance.imageUrl,
      'rarity': instance.rarity,
      'template': instance.template,
      'shareText': instance.shareText,
      'deepLink': instance.deepLink,
      'metadata': instance.metadata,
      'isPublic': instance.isPublic,
      'shareCount': instance.shareCount,
      'favoriteCount': instance.favoriteCount,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'renderTime': instance.renderTime,
    };
