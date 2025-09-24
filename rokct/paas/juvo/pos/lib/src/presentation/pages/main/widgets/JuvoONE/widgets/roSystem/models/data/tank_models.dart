

import '../../../../../../../../../core/constants/constants.dart';

class Tank {
  final int? id;
  final int? shopId;
  final String number;
  final TankType type;
  final double capacity;
  final TankStatus status;
  final Map<String, dynamic> pumpStatus;
  final Map<String, dynamic> waterQuality;
  late final DateTime? lastFull;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tank({
    this.id,
    this.shopId,
    required this.number,
    required this.type,
    required this.capacity,
    required this.status,
    required this.pumpStatus,
    required this.waterQuality,
    this.lastFull,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory Tank.fromJson(Map<String, dynamic> json) {
    final status = TankStatus.values.firstWhere(
      (e) => e.toString().split('.').last == json['status'],
      orElse: () => TankStatus.empty,
    );

    return Tank(
      id: json['id'],
      shopId: json['shop_id'] is String
          ? int.tryParse(json['shop_id'])
          : json['shop_id'],
      number: json['number'],
      type: TankType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => TankType.raw,
      ),
      capacity: json['capacity'] is String
          ? double.tryParse(json['capacity']) ?? 0.0
          : (json['capacity'] as num).toDouble(),
      status: status,
      pumpStatus: json['pump_status'] ?? {'isOn': false, 'flowRate': 0.0},
      waterQuality: json['water_quality'] ??
          {
            'ph': 7.0,
            'tds': 0,
            'temperature': 25.0,
            'hardness': 0,
          },
      // If last_full is null and status is full, use createdAt as the starting point
      lastFull: json['last_full'] != null
          ? DateTime.parse(json['last_full'])
          : (status == TankStatus.full
              ? DateTime.parse(json['created_at'])
              : null),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'shop_id': shopId,
      'number': number,
      'type': type.toString().split('.').last,
      'capacity': capacity,
      'status': status.toString().split('.').last,
      'pump_status': pumpStatus,
      'water_quality': waterQuality,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    // Include last_full if it exists
    if (lastFull != null) {
      json['last_full'] = lastFull!.toIso8601String();
    }

    return json;
  }
}

