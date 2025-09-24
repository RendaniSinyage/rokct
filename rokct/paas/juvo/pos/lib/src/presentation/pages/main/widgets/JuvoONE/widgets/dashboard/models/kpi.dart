// lib/models/kpi.dart
class Kpi {
  final String id;
  final String uuid;
  final String? shopId;
  final String objectiveId;
  final String metric;
  final String? targetValue;
  final String? currentValue;
  final String? unit;
  final DateTime dueDate;
  final String status;
  final DateTime? completionDate;

  Kpi({
    required this.id,
    required this.uuid,
    this.shopId,
    required this.objectiveId,
    required this.metric,
    this.targetValue,
    this.currentValue,
    this.unit,
    required this.dueDate,
    required this.status,
    this.completionDate,
  });

  factory Kpi.fromJson(Map<String, dynamic> json) {
    return Kpi(
      id: json['id'].toString(),
      uuid: json['uuid'],
      shopId: json['shop_id']?.toString(),
      objectiveId: json['objective_id'].toString(),
      metric: json['metric'],
      targetValue: json['target_value'],
      currentValue: json['current_value'],
      unit: json['unit'],
      dueDate: DateTime.parse(json['due_date']),
      status: json['status'] ?? 'Not Started',
      completionDate: json['completion_date'] != null ? DateTime.parse(json['completion_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'shop_id': shopId,
      'objective_id': objectiveId,
      'metric': metric,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'completion_date': completionDate?.toIso8601String(),
    };
  }
}


