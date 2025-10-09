import 'package:flutter/foundation.dart';

import '../../../../../../../../../core/constants/constants.dart';

class ROSystem {
  final int id;
  final List<Vessel> vessels;
  final List<Filter> filters;
  final int membraneCount;
  final DateTime membraneInstallationDate;

  ROSystem({
    this.id = 0,
    required this.vessels,
    required this.filters,
    required this.membraneCount,
    required this.membraneInstallationDate,
  });

  factory ROSystem.fromJson(Map<String, dynamic> json) {
    return ROSystem(
      id: json['id'] as int? ?? 0,
      vessels: (json['vessels'] as List<dynamic>?)?.map((vesselJson) {
            return Vessel.fromJson(vesselJson as Map<String, dynamic>);
          }).toList() ??
          [],
      filters: (json['filters'] as List<dynamic>?)?.map((filterJson) {
            return Filter.fromJson(filterJson as Map<String, dynamic>);
          }).toList() ??
          [],
      membraneCount: json['membrane_count'] as int? ?? 0,
      membraneInstallationDate: json['membrane_installation_date'] != null
          ? DateTime.parse(json['membrane_installation_date'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vessels': vessels.map((v) => v.toJson()).toList(),
      'filters': filters.map((f) => f.toJson()).toList(),
      'membrane_count': membraneCount,
      'membrane_installation_date': membraneInstallationDate.toIso8601String(),
    };
  }
}

// Updated Vessel model
class Vessel {
  final String id;
  final String type;
  final DateTime installationDate;
  DateTime? lastMaintenanceDate;
  MaintenanceStage? currentStage;
  DateTime? maintenanceStartTime;

  Vessel({
    required this.id,
    required this.type,
    required this.installationDate,
    this.lastMaintenanceDate,
    this.currentStage,
    this.maintenanceStartTime,
  });

  factory Vessel.fromJson(Map<String, dynamic> json) {
    return Vessel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      installationDate: json['installation_date'] != null
          ? DateTime.parse(json['installation_date'] as String)
          : DateTime.now(),
      lastMaintenanceDate: json['last_maintenance_date'] != null
          ? DateTime.parse(json['last_maintenance_date'] as String)
          : null,
      currentStage: _parseMaintenanceStage(json['current_stage'] as String?),
      maintenanceStartTime: json['maintenance_start_time'] != null
          ? DateTime.parse(json['maintenance_start_time'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'installation_date': installationDate.toIso8601String(),
      if (lastMaintenanceDate != null)
        'last_maintenance_date': lastMaintenanceDate!.toIso8601String(),
      if (currentStage != null)
        'current_stage': currentStage.toString().split('.').last,
      if (maintenanceStartTime != null)
        'maintenance_start_time': maintenanceStartTime!.toIso8601String(),
    };
  }

  static MaintenanceStage? _parseMaintenanceStage(String? stage) {
    if (stage == null) return null;

    try {
      return MaintenanceStage.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() == stage.toLowerCase(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing maintenance stage: $e');
      }
      return null;
    }
  }
}



// Updated Filter model
class Filter {
  final String id;
  final FilterType type;
  final FilterLocation location;
  final DateTime installationDate;

  Filter({
    required this.id,
    required this.type,
    required this.location,
    required this.installationDate,
  });

  // Add copyWith method
  Filter copyWith({
    String? id,
    FilterType? type,
    FilterLocation? location,
    DateTime? installationDate,
  }) {
    return Filter(
      id: id ?? this.id,
      type: type ?? this.type,
      location: location ?? this.location,
      installationDate: installationDate ?? this.installationDate,
    );
  }

  factory Filter.fromJson(Map<String, dynamic> json) {
    return Filter(
      id: json['id'] as String? ?? '',
      type: _parseFilterType(json['type'] as String?),
      location: _parseFilterLocation(json['location'] as String?),
      installationDate: json['installation_date'] != null
          ? DateTime.parse(json['installation_date'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'location': location.toString().split('.').last,
      'installation_date': installationDate.toIso8601String(),
    };
  }

  static FilterType _parseFilterType(String? type) {
    switch (type?.toLowerCase()) {
      case 'sediment':
        return FilterType.sediment;
      case 'carbonblock':
        return FilterType.carbonBlock;
      case 'birm':
        return FilterType.birm;
      default:
        return FilterType.sediment; // Default value
    }
  }

  static FilterLocation _parseFilterLocation(String? location) {
    switch (location?.toLowerCase()) {
      case 'pre':
        return FilterLocation.pre;
      case 'ro':
        return FilterLocation.ro;
      case 'post':
        return FilterLocation.post;
      default:
        return FilterLocation.pre; // Default value
    }
  }
}

