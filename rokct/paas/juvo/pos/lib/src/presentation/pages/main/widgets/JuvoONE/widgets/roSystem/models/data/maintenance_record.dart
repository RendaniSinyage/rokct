class MaintenanceRecord {
  final int id;
  final int shopId;
  final String type;
  final String referenceId;
  final DateTime maintenanceDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceRecord({
    required this.id,
    required this.shopId,
    required this.type,
    required this.referenceId,
    required this.maintenanceDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as int? ?? 0,
      shopId: json['shop_id'] as int? ?? 0,
      type: json['type'] as String? ?? '',
      referenceId: json['reference_id'] as String? ?? '',
      maintenanceDate: json['maintenance_date'] != null
          ? DateTime.parse(json['maintenance_date'] as String)
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shop_id': shopId,
      'type': type,
      'reference_id': referenceId,
      'maintenance_date': maintenanceDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
