import 'package:flutter/foundation.dart';

import '../../../../../../../core/constants/constants.dart';
import 'repository/ro_system_api.dart';

class ROSystemEfficiency {
  static Future<double> calculateSystemEfficiency() async {
    final system = await MaintenanceApiService.getROSystem();
    if (system == null) return 0.0;

    double totalEfficiency = 0.0;
    int componentCount = 0;

    // Get maintenance records for efficiency calculations
    final vesselRecords = await MaintenanceApiService.getMaintenanceRecords(type: 'vessel');
    final membraneRecords = await MaintenanceApiService.getMaintenanceRecords(type: 'membrane');

    // Calculate vessel efficiencies
    for (final vessel in system.vessels) {
      final lastMaintenance = vesselRecords
          .where((record) => record.referenceId == vessel.id)
          .fold<DateTime?>(
          null,
              (latest, record) => latest == null || record.maintenanceDate.isAfter(latest)
              ? record.maintenanceDate
              : latest);

      totalEfficiency += calculateComponentEfficiency(
        installationDate: vessel.installationDate,
        lastMaintenanceDate: lastMaintenance,
      );
      componentCount++;
    }

    // Calculate filter efficiencies
    for (final filter in system.filters) {
      totalEfficiency += calculateComponentEfficiency(
        installationDate: filter.installationDate,
        replacementLifespan: getFilterLifespan(filter.location),
      );
      componentCount++;
    }

    // Calculate membrane efficiency
    if (system.membraneInstallationDate != null) {
      final lastMembraneMaintenance = membraneRecords.isNotEmpty
          ? membraneRecords
          .map((record) => record.maintenanceDate)
          .reduce((a, b) => a.isAfter(b) ? a : b)
          : null;

      totalEfficiency += calculateComponentEfficiency(
        installationDate: system.membraneInstallationDate,
        lastMaintenanceDate: lastMembraneMaintenance,
        replacementLifespan: AppConstants.roMembraneReplaceDays,
      );
      componentCount++;
    }

    return componentCount > 0 ? (totalEfficiency / componentCount) : 0.0;
  }

  static double calculateComponentEfficiency({
    required DateTime installationDate,
    DateTime? lastMaintenanceDate,
    int? replacementLifespan,
  }) {
    final now = DateTime.now();
    final daysSinceInstallation = now.difference(installationDate).inDays;

    if (replacementLifespan != null) {
      // For components that need replacement (filters, membranes)
      return 100.0 * (1 - (daysSinceInstallation / replacementLifespan)).clamp(0.0, 1.0);
    } else {
      // For components that need maintenance (vessels)
      final daysSinceLastMaintenance = lastMaintenanceDate != null
          ? now.difference(lastMaintenanceDate).inDays
          : daysSinceInstallation;

      // Efficiency drops after maintenance interval
      return 100.0 *
          (1 - (daysSinceLastMaintenance / AppConstants.maintenanceCheckDays)).clamp(0.0, 1.0);
    }
  }

  static int getFilterLifespan(FilterLocation location) {
    switch (location) {
      case FilterLocation.pre:
        return AppConstants.preFilterReplaceDays;
      case FilterLocation.ro:
        return AppConstants.roFilterReplaceDays;
      case FilterLocation.post:
        return AppConstants.postFilterReplaceDays;
    }
  }

  static Future<double> calculateSystemEfficiencyForShop(int shopId) async {
    try {
      final system = await MaintenanceApiService.getROSystemByShopId(shopId);
      if (system == null) return 0.0;

      double totalEfficiency = 0.0;
      int componentCount = 0;

      // Get maintenance records for efficiency calculations
      final vesselRecords = await MaintenanceApiService.getMaintenanceRecordsByShopId(shopId, type: 'vessel');
      final membraneRecords = await MaintenanceApiService.getMaintenanceRecordsByShopId(shopId, type: 'membrane');

      // Calculate vessel efficiencies
      for (final vessel in system.vessels) {
        final lastMaintenance = vesselRecords
            .where((record) => record.referenceId == vessel.id)
            .fold<DateTime?>(
            null,
                (latest, record) => latest == null || record.maintenanceDate.isAfter(latest)
                ? record.maintenanceDate
                : latest);

        totalEfficiency += calculateComponentEfficiency(
          installationDate: vessel.installationDate,
          lastMaintenanceDate: lastMaintenance,
        );
        componentCount++;
      }

      // Calculate filter efficiencies
      for (final filter in system.filters) {
        totalEfficiency += calculateComponentEfficiency(
          installationDate: filter.installationDate,
          replacementLifespan: getFilterLifespan(filter.location),
        );
        componentCount++;
      }

      // Calculate membrane efficiency
      if (system.membraneInstallationDate != null) {
        final lastMembraneMaintenance = membraneRecords.isNotEmpty
            ? membraneRecords
            .map((record) => record.maintenanceDate)
            .reduce((a, b) => a.isAfter(b) ? a : b)
            : null;

        totalEfficiency += calculateComponentEfficiency(
          installationDate: system.membraneInstallationDate,
          lastMaintenanceDate: lastMembraneMaintenance,
          replacementLifespan: AppConstants.roMembraneReplaceDays,
        );
        componentCount++;
      }

      return componentCount > 0 ? (totalEfficiency / componentCount) : 0.0;
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating system efficiency for shop $shopId: $e');
      }
      return 0.0;
    }
  }
}
