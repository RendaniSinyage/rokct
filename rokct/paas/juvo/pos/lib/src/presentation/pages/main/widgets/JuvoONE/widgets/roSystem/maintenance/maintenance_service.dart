import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../../core/utils/local_storage.dart';
import '../models/data/ro_system_model.dart';
import '../repository/ro_system_api.dart';
import 'maintenance_progress.dart';
import 'maintenance_item.dart';

class MaintenanceService {
  // RO System management
  static Future<void> saveROSystem(ROSystem system) async {
    await MaintenanceApiService.saveROSystem(system);
  }

  static Future<ROSystem?> getROSystem() async {
    return await MaintenanceApiService.getROSystem();
  }

  static Future<void> updateMaintenanceDate({
    required String type,
    required String referenceId,
    required DateTime date,
  }) async {
    await MaintenanceApiService.updateMaintenanceDate(
      type: type,
      referenceId: referenceId,
      date: date,
    );
  }

  static Future<ROSystem?> getROSystemByShopId(int shopId) async {
    try {
      return await MaintenanceApiService.getROSystemByShopId(shopId);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting RO system for shop $shopId: $e');
      }
      return null;
    }
  }

  // System completeness checks
  static bool _hasRequiredVessels(ROSystem system) {
    final hasMegaChar = system.vessels.any((v) => v.type == 'megaChar');
    final hasSoftener = system.vessels.any((v) => v.type == 'softener');
    return hasMegaChar && hasSoftener;
  }

  static bool _hasRequiredFilters(ROSystem system) {
    final hasPreFilter = system.filters.any((f) => f.location == FilterLocation.pre);
    final hasRoFilter = system.filters.any((f) => f.location == FilterLocation.ro);
    final hasPostFilter = system.filters.any((f) => f.location == FilterLocation.post);
    return hasPreFilter && hasRoFilter && hasPostFilter;
  }

  // Maintenance items management
  static Future<List<MaintenanceItem>> getMaintenanceItems() async {
    // First try to get maintenance items from API
    try {
      return await MaintenanceApiService.getMaintenanceItems();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching maintenance items from API: $e');
      }

      // Fallback to generating items based on system state
      final system = await getROSystem();
      if (system == null) {
        return [MaintenanceItem(type: 'setup')];
      }

      if (!_hasRequiredVessels(system)) {
        return [MaintenanceItem(type: 'vessel_setup')];
      }

      if (!_hasRequiredFilters(system)) {
        return [MaintenanceItem(type: 'filter_setup')];
      }

      if (system.membraneCount <= 0) {
        return [MaintenanceItem(type: 'membrane_setup')];
      }

      final items = <MaintenanceItem>[];
      final now = DateTime.now();

      // Get maintenance records from API
      final vesselRecords = await MaintenanceApiService.getMaintenanceRecords(type: 'vessel');
      final membraneRecords = await MaintenanceApiService.getMaintenanceRecords(type: 'membrane');

      // Vessel maintenance check
      for (final vessel in system.vessels) {
        final lastMaintenance = vesselRecords
            .where((record) => record.referenceId == vessel.id)
            .fold<DateTime?>(
            null,
                (latest, record) => latest == null || record.maintenanceDate.isAfter(latest)
                ? record.maintenanceDate
                : latest);

        if (lastMaintenance == null ||
            now.difference(lastMaintenance).inDays >= AppConstants.maintenanceCheckDays) {
          items.add(MaintenanceItem(
              type: vessel.type,
              id: vessel.id,
              maintenanceType: 'maintenance'
          ));
        }
      }

      // Filter checks
      for (final filter in system.filters) {
        final daysToReplace = _getFilterReplacementDays(filter.location);

        if (now.difference(filter.installationDate).inDays >= daysToReplace) {
          items.add(MaintenanceItem(
              type: 'filter',
              id: filter.id,
              maintenanceType: 'replacement',
              filterLocation: filter.location,
              filterType: filter.type
          ));
        }
      }

      // Membrane check
      final lastMembraneMaintenance = membraneRecords.isNotEmpty
          ? membraneRecords
          .map((record) => record.maintenanceDate)
          .reduce((a, b) => a.isAfter(b) ? a : b)
          : null;

      if (lastMembraneMaintenance == null ||
          now.difference(system.membraneInstallationDate).inDays >= AppConstants.roMembraneReplaceDays) {
        items.add(MaintenanceItem(
            type: 'membrane',
            maintenanceType: 'replacement',
            membraneCount: system.membraneCount
        ));
      }

      return items;
    }
  }

  static Future<void> saveMaintenanceProgress({
    required String vesselId,
    required MaintenanceStage stage,
    required DateTime stageStartTime,
  }) async {
    final progress = MaintenanceProgress(
      vesselId: vesselId,
      currentStage: stage.toString(),
      stageStartTime: stageStartTime,
    );

    await LocalStorage.setItem(
      'maintenance_progress_$vesselId',
      jsonEncode(progress.toJson()),
    );
  }

  static Future<MaintenanceProgress?> getMaintenanceProgress(String vesselId) async {
    final savedProgress = await LocalStorage.getItem('maintenance_progress_$vesselId');
    if (savedProgress != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(savedProgress);
        return MaintenanceProgress.fromJson(json);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing saved maintenance progress: $e');
        }
      }
    }
    return null;
  }

  static Future<void> clearMaintenanceProgress(String vesselId) async {
    await LocalStorage.removeItem('maintenance_progress_$vesselId');
  }


  static int _getFilterReplacementDays(FilterLocation location) {
    switch (location) {
      case FilterLocation.pre:
        return AppConstants.preFilterReplaceDays;
      case FilterLocation.ro:
        return AppConstants.roFilterReplaceDays;
      case FilterLocation.post:
        return AppConstants.postFilterReplaceDays;
    }
  }

  // Maintenance durations
  static Duration getMaintenanceDuration(String type, MaintenanceStage stage) {
    final durations = type == 'megaChar'
        ? AppConstants.megaCharMaintenanceDurations
        : AppConstants.softenerMaintenanceDurations;

    final minutes = durations[stage.toString().split('.').last] ?? 0;
    return Duration(minutes: minutes);
  }

}

