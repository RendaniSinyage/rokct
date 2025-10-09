// lib/models/vision.dart
import 'pillar.dart';

class Vision {
  final String id;
  final String uuid;
  final String? shopId;
  final String statement;
  final DateTime effectiveDate;
  final DateTime? endDate;
  final bool isActive;
  final String createdBy;
  final List<Pillar> pillars;

  Vision({
    required this.id,
    required this.uuid,
    this.shopId,
    required this.statement,
    required this.effectiveDate,
    this.endDate,
    required this.isActive,
    required this.createdBy,
    required this.pillars,
  });

  factory Vision.fromJson(Map<String, dynamic> json) {
    List<Pillar> pillars = [];
    if (json['pillars'] != null) {
      pillars = List<Pillar>.from(
        json['pillars'].map((pillar) => Pillar.fromJson(pillar)),
      );
    }

    return Vision(
      id: json['id'].toString(),
      uuid: json['uuid'],
      shopId: json['shop_id']?.toString(),
      statement: json['statement'],
      effectiveDate: DateTime.parse(json['effective_date']),
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
      isActive: json['is_active'] ?? false,
      createdBy: json['created_by'].toString(),
      pillars: pillars,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'shop_id': shopId,
      'statement': statement,
      'effective_date': effectiveDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_active': isActive,
      'created_by': createdBy,
      'pillars': pillars.map((pillar) => pillar.toJson()).toList(),
    };
  }}


