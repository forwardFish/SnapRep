import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';
import '../utils/image_url_helper.dart';

part 'scenario.g.dart';

@JsonSerializable()
class Scenario {
  final String id;
  final String code;
  final String name;
  final String? description;
  @JsonKey(name: 'iconUrl')  // 改为驼峰命名，匹配后端
  final String? iconUrl;
  @JsonKey(name: 'isActive')  // 改为驼峰命名，匹配后端
  final bool? isActive;

  Scenario({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.iconUrl,
    this.isActive,
  });

  /// 获取完整的图标 URL（从后端 API 加载）
  String? get fullIconUrl {
    debugPrint('🔍 Scenario.fullIconUrl called for: $name');
    debugPrint('   📁 Original iconUrl: $iconUrl');

    if (iconUrl == null || iconUrl!.isEmpty) {
      debugPrint('   ❌ iconUrl is null or empty, returning null');
      return null;
    }

    final fullUrl = ImageUrlHelper.getScenarioImage(iconUrl);
    debugPrint('   ✅ Converted to: $fullUrl');
    return fullUrl;
  }

  factory Scenario.fromJson(Map<String, dynamic> json) => _$ScenarioFromJson(json);
  Map<String, dynamic> toJson() => _$ScenarioToJson(this);
}
