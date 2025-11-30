import 'package:json_annotation/json_annotation.dart';
import 'package:flutter/foundation.dart';
import '../utils/image_url_helper.dart';

part 'equipment.g.dart';

@JsonSerializable()
class Equipment {
  final String id;
  final String code;
  final String name;
  final String category;
  @JsonKey(name: 'iconUrl')  // 改为驼峰命名，匹配后端
  final String? iconUrl;
  @JsonKey(name: 'isActive')  // 改为驼峰命名，匹配后端
  final bool? isActive;
  @JsonKey(name: 'displayOrder')  // 改为驼峰命名，匹配后端
  final int? displayOrder;

  Equipment({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    this.iconUrl,
    this.isActive,
    this.displayOrder,
  });

  /// 获取完整的图标 URL（从后端 API 加载）
  String? get fullIconUrl {
    debugPrint('🔍 Equipment.fullIconUrl called for: $name');
    debugPrint('   📁 Original iconUrl: $iconUrl');

    if (iconUrl == null || iconUrl!.isEmpty) {
      debugPrint('   ❌ iconUrl is null or empty, returning null');
      return null;
    }

    final fullUrl = ImageUrlHelper.getImageUrl(iconUrl);
    debugPrint('   ✅ Converted to: $fullUrl');
    return fullUrl;
  }

  /// Factory constructor with safe null handling
  factory Equipment.fromJsonSafe(Map<String, dynamic> json) {
    return Equipment(
      id: json['id']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown Equipment',
      category: json['category']?.toString() ?? 'Equipment',
      iconUrl: json['iconUrl']?.toString(),  // 改为驼峰命名
      isActive: json['isActive'] as bool?,   // 改为驼峰命名
      displayOrder: json['displayOrder'] as int?,  // 改为驼峰命名
    );
  }

  factory Equipment.fromJson(Map<String, dynamic> json) => _$EquipmentFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentToJson(this);
}