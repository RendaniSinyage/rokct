// lib/models/strategic_objective.dart
import 'kpi.dart';

class StrategicObjective {
  final String id;
  final String uuid;
  final String? shopId;
  final String pillarId;
  final String title;
  final String? description;
  final bool is90DayPriority;
  final String timeHorizon;
  final String status;
  final DateTime? startDate;
  final DateTime? targetDate;
  final DateTime? completionDate;
  final List<Kpi> kpis;

  StrategicObjective({
    required this.id,
    required this.uuid,
    this.shopId,
    required this.pillarId,
    required this.title,
    this.description,
    required this.is90DayPriority,
    required this.timeHorizon,
    required this.status,
    this.startDate,
    this.targetDate,
    this.completionDate,
    required this.kpis,
  });

  factory StrategicObjective.fromJson(Map<String, dynamic> json) {
    List<Kpi> kpis = [];
    if (json['kpis'] != null) {
      kpis = List<Kpi>.from(
        json['kpis'].map((kpi) => Kpi.fromJson(kpi)),
      );
    }

    return StrategicObjective(
      id: json['id'].toString(),
      uuid: json['uuid'],
      shopId: json['shop_id']?.toString(),
      pillarId: json['pillar_id'].toString(),
      title: json['title'],
      description: json['description'],
      is90DayPriority: json['is_90_day_priority'] ?? false,
      timeHorizon: json['time_horizon'] ?? 'Short-term',
      status: json['status'] ?? 'Not Started',
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date']) : null,
      targetDate: json['target_date'] != null ? DateTime.parse(json['target_date']) : null,
      completionDate: json['completion_date'] != null ? DateTime.parse(json['completion_date']) : null,
      kpis: kpis,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'shop_id': shopId,
      'pillar_id': pillarId,
      'title': title,
      'description': description,
      'is_90_day_priority': is90DayPriority,
      'time_horizon': timeHorizon,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'target_date': targetDate?.toIso8601String(),
      'completion_date': completionDate?.toIso8601String(),
      'kpis': kpis.map((kpi) => kpi.toJson()).toList(),
    };
  }
}


