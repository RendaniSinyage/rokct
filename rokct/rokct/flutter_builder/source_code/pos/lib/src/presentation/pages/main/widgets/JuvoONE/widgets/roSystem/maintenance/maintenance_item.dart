// maintenance_item.dart
import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../../core/utils/utils.dart';

class MaintenanceItem {
  final String type;
  final String? id;
  final String maintenanceType;
  final FilterLocation? filterLocation;
  final FilterType? filterType;
  final int? membraneCount;

  MaintenanceItem({
    required this.type,
    this.id,
    this.maintenanceType = 'maintenance',
    this.filterLocation,
    this.filterType,
    this.membraneCount,
  });

  factory MaintenanceItem.fromJson(Map<String, dynamic> json) {
    return MaintenanceItem(
      type: json['type'] as String,
      id: json['id'] as String?,
      maintenanceType: json['maintenance_type'] as String? ?? 'maintenance',
      filterLocation: json['filter_location'] != null
          ? FilterLocation.values.firstWhere(
              (e) => e.toString().split('.').last == json['filter_location'],
          orElse: () => FilterLocation.pre)
          : null,
      filterType: json['filter_type'] != null
          ? FilterType.values.firstWhere(
              (e) => e.toString().split('.').last == json['filter_type'],
          orElse: () => FilterType.sediment)
          : null,
      membraneCount: json['membrane_count'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'id': id,
      'maintenance_type': maintenanceType,
      'filter_location': filterLocation?.toString().split('.').last,
      'filter_type': filterType?.toString().split('.').last,
      'membrane_count': membraneCount,
    };
  }

  String get message {
    if (type == 'setup') {
      return AppHelpers.getTranslation(TrKeys.setupRequired);
    }

    if (type == 'filter' && filterLocation != null) {
      final locationName = switch (filterLocation!) {
        FilterLocation.pre => AppHelpers.getTranslation(TrKeys.preFilter),
        FilterLocation.ro => AppHelpers.getTranslation(TrKeys.roFilter),
        FilterLocation.post => AppHelpers.getTranslation(TrKeys.postFilter),
      };

      final maintenanceText = maintenanceType == 'maintenance'
          ? AppHelpers.getTranslation(TrKeys.maintenanceRequired)
          : AppHelpers.getTranslation(TrKeys.replacementRequired);

      return '$locationName $maintenanceText';
    }

    if (type == 'membrane') {
      return '${AppHelpers.getTranslation(TrKeys.roMembrane)} ${AppHelpers.getTranslation(TrKeys.replacementRequired)}';
    }

    final maintenanceText = maintenanceType == 'maintenance'
        ? AppHelpers.getTranslation(TrKeys.maintenanceRequired)
        : AppHelpers.getTranslation(TrKeys.replacementRequired);

    return '${AppConstants.maintenanceTypes[type]} $maintenanceText';
  }
}
