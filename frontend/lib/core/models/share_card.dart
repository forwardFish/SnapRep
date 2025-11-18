import 'package:json_annotation/json_annotation.dart';

part 'share_card.g.dart';

/// 卡片稀有度等级
enum RarityLevel {
  @JsonValue('COMMON')
  common('COMMON', '常见', '🟦', '#90A4AE', 0.4),

  @JsonValue('UNCOMMON')
  uncommon('UNCOMMON', '进阶', '🟩', '#4CAF50', 0.15),

  @JsonValue('RARE')
  rare('RARE', '稀有', '🟨', '#FF9800', 0.05),

  @JsonValue('EPIC')
  epic('EPIC', '史诗', '🟪', '#9C27B0', 0.01),

  @JsonValue('LEGENDARY')
  legendary('LEGENDARY', '传奇', '🟥', '#F44336', 0.001);

  const RarityLevel(
    this.code,
    this.displayName,
    this.emoji,
    this.color,
    this.threshold,
  );

  final String code;
  final String displayName;
  final String emoji;
  final String color;
  final double threshold; // 频次阈值

  static RarityLevel fromCode(String code) {
    return RarityLevel.values.firstWhere(
      (rarity) => rarity.code == code,
      orElse: () => RarityLevel.common,
    );
  }

  /// 根据频次分数计算稀有度
  static RarityLevel fromScore(double score) {
    if (score <= RarityLevel.legendary.threshold) return RarityLevel.legendary;
    if (score <= RarityLevel.epic.threshold) return RarityLevel.epic;
    if (score <= RarityLevel.rare.threshold) return RarityLevel.rare;
    if (score <= RarityLevel.uncommon.threshold) return RarityLevel.uncommon;
    return RarityLevel.common;
  }
}

/// 器材系列类型
enum EquipmentSeries {
  furniture('furniture', '家具系', '🪑'),
  wall('wall', '墙面系', '🏠'),
  bottle('bottle', '瓶罐系', '💧'),
  carry('carry', '背包携行', '🎒'),
  stairs('stairs', '台阶座椅', '📐'),
  bodyweight('bodyweight', '徒手系', '💪'),
  outdoor('outdoor', '户外系', '🌳'),
  office('office', '办公系', '💼'),
  travel('travel', '旅行系', '✈️'),
  unknown('unknown', '其他', '❓');

  const EquipmentSeries(this.code, this.displayName, this.emoji);

  final String code;
  final String displayName;
  final String emoji;

  static EquipmentSeries fromCode(String code) {
    return EquipmentSeries.values.firstWhere(
      (series) => series.code == code,
      orElse: () => EquipmentSeries.unknown,
    );
  }

  /// 根据器材代码自动判断系列
  static EquipmentSeries fromEquipmentCode(String equipmentCode) {
    switch (equipmentCode) {
      case 'chair':
      case 'sofa':
      case 'bench':
        return EquipmentSeries.furniture;
      case 'wall':
        return EquipmentSeries.wall;
      case 'bottle':
        return EquipmentSeries.bottle;
      case 'backpack':
        return EquipmentSeries.carry;
      case 'stairs':
        return EquipmentSeries.stairs;
      case 'hands_free':
        return EquipmentSeries.bodyweight;
      default:
        return EquipmentSeries.unknown;
    }
  }
}

/// 卡片稀有度详情
@JsonSerializable()
class CardRarity {
  /// 稀有度等级
  @JsonKey(fromJson: _rarityFromJson, toJson: _rarityToJson)
  final RarityLevel level;

  /// 稀有度分数（0-1）
  final double score;

  /// 器材系列
  @JsonKey(fromJson: _seriesFromJson, toJson: _seriesToJson)
  final EquipmentSeries equipmentSeries;

  /// 特殊标签
  final List<String> specialTags;

  /// 城市限定版本（可选）
  final String? cityEdition;

  /// 全球排名（可选）
  final int? globalRank;

  /// 7日使用次数
  final int? weeklyUsage;

  const CardRarity({
    required this.level,
    required this.score,
    required this.equipmentSeries,
    required this.specialTags,
    this.cityEdition,
    this.globalRank,
    this.weeklyUsage,
  });

  /// 获取稀有度描述
  String get description {
    final parts = <String>[level.displayName];

    if (globalRank != null && globalRank! <= 100) {
      parts.add('Top ${globalRank}%');
    }

    if (specialTags.isNotEmpty) {
      parts.addAll(specialTags);
    }

    if (cityEdition != null) {
      parts.add('$cityEdition限定');
    }

    return parts.join(' · ');
  }

  /// JSON序列化
  factory CardRarity.fromJson(Map<String, dynamic> json) =>
      _$CardRarityFromJson(json);

  Map<String, dynamic> toJson() => _$CardRarityToJson(this);
}

/// 分享卡片模型
@JsonSerializable()
class ShareCard {
  /// 卡片ID
  final String id;

  /// 用户ID
  final String userId;

  /// 关联的训练会话ID
  final String workoutSessionId;

  /// 卡片图片URL
  final String imageUrl;

  /// 卡片稀有度
  final CardRarity rarity;

  /// 卡片模板风格
  final String template;

  /// 分享文案
  final String shareText;

  /// DeepLink链接
  final String deepLink;

  /// 训练元数据
  final Map<String, dynamic> metadata;

  /// 是否为公开卡片
  final bool isPublic;

  /// 分享次数
  final int shareCount;

  /// 收藏次数
  final int favoriteCount;

  /// 生成时间
  final DateTime generatedAt;

  /// 创建时间
  final DateTime createdAt;

  /// 过期时间（可选）
  final DateTime? expiresAt;

  /// 渲染耗时（毫秒）
  final int? renderTime;

  const ShareCard({
    required this.id,
    required this.userId,
    required this.workoutSessionId,
    required this.imageUrl,
    required this.rarity,
    required this.template,
    required this.shareText,
    required this.deepLink,
    required this.metadata,
    this.isPublic = false,
    this.shareCount = 0,
    this.favoriteCount = 0,
    required this.generatedAt,
    required this.createdAt,
    this.expiresAt,
    this.renderTime,
  });

  /// 是否已过期
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// 获取训练总时长
  int? get totalDuration {
    return metadata['totalDuration'] as int?;
  }

  /// 获取完成的动作数
  int? get exercisesCompleted {
    return metadata['exercisesCompleted'] as int?;
  }

  /// 获取连击天数
  int? get streak {
    return metadata['streak'] as int?;
  }

  /// 获取使用的器材
  List<String>? get equipmentUsed {
    final equipment = metadata['equipmentUsed'];
    if (equipment is List) {
      return equipment.cast<String>();
    }
    return null;
  }

  /// 获取训练场景
  String? get scenario {
    return metadata['scenario'] as String?;
  }

  /// 获取训练难度
  String? get difficulty {
    return metadata['difficulty'] as String?;
  }

  /// 获取作用效果列表
  List<String>? get benefits {
    final benefits = metadata['benefits'];
    if (benefits is List) {
      return benefits.cast<String>();
    }
    return null;
  }

  /// 生成分享标题
  String get shareTitle {
    final duration = totalDuration != null ? '${(totalDuration! / 60).round()}分钟' : '';
    final equipment = equipmentUsed?.join('、') ?? '';
    final rarityText = rarity.level.displayName;

    return '我刚完成了$duration$equipment训练，获得了$rarityText卡片！';
  }

  /// 获取卡片显示摘要
  String get displaySummary {
    final parts = <String>[];

    if (scenario != null) {
      parts.add(scenario!);
    }

    if (totalDuration != null) {
      parts.add('${(totalDuration! / 60).round()}分钟');
    }

    if (equipmentUsed != null && equipmentUsed!.isNotEmpty) {
      parts.add(equipmentUsed!.join('、'));
    }

    return parts.join(' · ');
  }

  /// JSON序列化
  factory ShareCard.fromJson(Map<String, dynamic> json) =>
      _$ShareCardFromJson(json);

  Map<String, dynamic> toJson() => _$ShareCardToJson(this);

  /// 复制并修改
  ShareCard copyWith({
    String? id,
    String? userId,
    String? workoutSessionId,
    String? imageUrl,
    CardRarity? rarity,
    String? template,
    String? shareText,
    String? deepLink,
    Map<String, dynamic>? metadata,
    bool? isPublic,
    int? shareCount,
    int? favoriteCount,
    DateTime? generatedAt,
    DateTime? createdAt,
    DateTime? expiresAt,
    int? renderTime,
  }) {
    return ShareCard(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      workoutSessionId: workoutSessionId ?? this.workoutSessionId,
      imageUrl: imageUrl ?? this.imageUrl,
      rarity: rarity ?? this.rarity,
      template: template ?? this.template,
      shareText: shareText ?? this.shareText,
      deepLink: deepLink ?? this.deepLink,
      metadata: metadata ?? this.metadata,
      isPublic: isPublic ?? this.isPublic,
      shareCount: shareCount ?? this.shareCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      generatedAt: generatedAt ?? this.generatedAt,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      renderTime: renderTime ?? this.renderTime,
    );
  }

  @override
  String toString() {
    return 'ShareCard(id: $id, rarity: ${rarity.level.displayName}, template: $template)';
  }
}

// JSON序列化辅助方法
RarityLevel _rarityFromJson(String code) => RarityLevel.fromCode(code);
String _rarityToJson(RarityLevel rarity) => rarity.code;

EquipmentSeries _seriesFromJson(String code) => EquipmentSeries.fromCode(code);
String _seriesToJson(EquipmentSeries series) => series.code;