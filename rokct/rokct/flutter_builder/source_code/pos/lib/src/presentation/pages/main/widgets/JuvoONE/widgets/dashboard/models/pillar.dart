// lib/models/pillar.dart
import 'strategic_objective.dart';

class Pillar {
  final String id;
  final String uuid;
  final String? shopId;
  final String visionId;
  final String name;
  final String? description;
  final String? icon;
  final String? color;
  final int displayOrder;
  final List<StrategicObjective> strategicObjectives;

  Pillar({
    required this.id,
    required this.uuid,
    this.shopId,
    required this.visionId,
    required this.name,
    this.description,
    this.icon,
    this.color,
    required this.displayOrder,
    required this.strategicObjectives,
  });

  factory Pillar.fromJson(Map<String, dynamic> json) {
    List<StrategicObjective> objectives = [];
    if (json['strategic_objectives'] != null) {
      objectives = List<StrategicObjective>.from(
        json['strategic_objectives'].map((objective) => StrategicObjective.fromJson(objective)),
      );
    }

    return Pillar(
      id: json['id'].toString(),
      uuid: json['uuid'],
      shopId: json['shop_id']?.toString(),
      visionId: json['vision_id'].toString(),
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      color: json['color'],
      displayOrder: json['display_order'] ?? 0,
      strategicObjectives: objectives,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'shop_id': shopId,
      'vision_id': visionId,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'display_order': displayOrder,
      'strategic_objectives': strategicObjectives.map((objective) => objective.toJson()).toList(),
    };
  }
}


