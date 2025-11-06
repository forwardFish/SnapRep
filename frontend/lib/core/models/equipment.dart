import 'package:json_annotation/json_annotation.dart';

part 'equipment.g.dart';

@JsonSerializable()
class Equipment {
  final String id;
  final String code;
  final String name;
  final String category;
  @JsonKey(name: 'icon_url')
  final String? iconUrl;
  @JsonKey(name: 'is_active')
  final bool? isActive;
  @JsonKey(name: 'display_order')
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

  factory Equipment.fromJson(Map<String, dynamic> json) => _$EquipmentFromJson(json);
  Map<String, dynamic> toJson() => _$EquipmentToJson(this);
}