import 'package:json_annotation/json_annotation.dart';

part 'scenario.g.dart';

@JsonSerializable()
class Scenario {
  final String id;
  final String code;
  final String name;
  final String? description;
  @JsonKey(name: 'icon_url')
  final String? iconUrl;
  @JsonKey(name: 'is_active')
  final bool? isActive;

  Scenario({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    this.iconUrl,
    this.isActive,
  });

  factory Scenario.fromJson(Map<String, dynamic> json) => _$ScenarioFromJson(json);
  Map<String, dynamic> toJson() => _$ScenarioToJson(this);
}
