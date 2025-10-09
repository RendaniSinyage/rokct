import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../../core/utils/utils.dart';
import '../maintenance/maintenance_item.dart';
import '../maintenance/maintenance_progress.dart';
import '../models/data/maintenance_record.dart';
import '../models/data/ro_system_model.dart';


class MaintenanceApiService {
  static const String _baseUrl = '${AppConstants.baseUrl}api/v1/rest/resources';

  static Future<bool> _checkConnectivity() async {
    return await AppConnectivity.connectivity();
  }

  static Future<Map<String, String>> _getHeaders() async {
    final token = await LocalStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  static Future<int?> _getShopId() async {
    final userData = await LocalStorage.getUser();
    if (userData?.shop?.id == null) {
      throw Exception('Shop data not found');
    }
    return userData?.shop?.id;
  }

  static Future<ROSystem?> getROSystem() async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();
      final shopId = await _getShopId();

      final response = await http.get(
        Uri.parse('$_baseUrl/ro-systems/$shopId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null || data['data'] == null) {
          return null;
        }

        try {
          return ROSystem.fromJson(data['data'] as Map<String, dynamic>);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing RO system: $e');
          }
          return null;
        }
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load RO system: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching RO system: $e');
      }
      rethrow;
    }
  }

  static Future<ROSystem> saveROSystem(ROSystem system) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();
      final shopId = await _getShopId();

      final validatedFilters = system.filters.map((filter) => Filter(
        id: filter.id,
        type: filter.type,
        location: filter.location,
        installationDate: _validateInstallationDate(filter.installationDate),
      )).toList();

      final validatedVessels = system.vessels.map((vessel) => Vessel(
        id: vessel.id,
        type: vessel.type,
        installationDate: _validateInstallationDate(vessel.installationDate),
        lastMaintenanceDate: vessel.lastMaintenanceDate != null
            ? _validateInstallationDate(vessel.lastMaintenanceDate!)
            : null,
        currentStage: vessel.currentStage,
        maintenanceStartTime: vessel.maintenanceStartTime,
      )).toList();

      final payload = {
        'shop_id': shopId,
        'filters': validatedFilters.map((f) => f.toJson()).toList(),
        'vessels': validatedVessels.map((v) => v.toJson()).toList(),
        'membrane_count': system.membraneCount,
        'membrane_installation_date': _validateInstallationDate(system.membraneInstallationDate).toIso8601String(),
      };

      if (kDebugMode) {
        print('Save RO System Payload:');
      }
      if (kDebugMode) {
        print('Shop ID: $shopId');
      }
      if (kDebugMode) {
        print('Validated Payload: ${json.encode(payload)}');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/ro-systems'),
        headers: headers,
        body: json.encode(payload),
      );

      if (kDebugMode) {
        print('RO System Save Response:');
      }
      if (kDebugMode) {
        print('Status Code: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Response Body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ROSystem.fromJson(data['data'] as Map<String, dynamic>);
      } else {
        final errorResponse = json.decode(response.body);
        if (kDebugMode) {
          print('Error Response Details:');
        }
        if (kDebugMode) {
          print('Error: ${errorResponse['message'] ?? 'Unknown error'}');
        }
        if (kDebugMode) {
          print('Validation Errors: ${errorResponse['errors'] ?? 'No specific errors'}');
        }

        throw Exception('Failed to save RO system: ${response.statusCode}\nError: ${errorResponse['message'] ?? errorResponse}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error saving RO system:');
      }
      if (kDebugMode) {
        print('Exception: $e');
      }
      if (kDebugMode) {
        print('Stacktrace: $stackTrace');
      }
      rethrow;
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

  static Future<void> updateMembrane(int systemId, {
    required int membraneCount,
    required DateTime installationDate,
  }) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();
      final shopId = await _getShopId();

      final response = await http.patch(
        Uri.parse('$_baseUrl/ro-systems/$systemId/membrane'),
        headers: headers,
        body: json.encode({
          'membrane_count': membraneCount,
          'membrane_installation_date': installationDate.toIso8601String(),
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update membrane settings: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating membrane settings: $e');
      }
      rethrow;
    }
  }

  static Future<void> updateMaintenanceDate({
    required String type,
    required String referenceId,
    required DateTime date,
  }) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    // Validate type before making the request
    if (!['vessel', 'membrane', 'filter'].contains(type)) {
      throw Exception('Invalid maintenance record type: $type');
    }

    try {
      final headers = await _getHeaders();
      final shopId = await _getShopId();

      if (kDebugMode) {
        print('Maintenance Record Payload:');
      }
      if (kDebugMode) {
        print('Shop ID: $shopId');
      }
      if (kDebugMode) {
        print('Type: $type');
      }
      if (kDebugMode) {
        print('Reference ID: $referenceId');
      }
      if (kDebugMode) {
        print('Maintenance Date: ${date.toIso8601String()}');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/maintenance-records'),
        headers: headers,
        body: json.encode({
          'shop_id': shopId,
          'type': type,
          'reference_id': referenceId,
          'maintenance_date': date.toIso8601String(),
        }),
      );

      if (kDebugMode) {
        print('Maintenance Record Response:');
      }
      if (kDebugMode) {
        print('Status Code: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Response Body: ${response.body}');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        final errorBody = json.decode(response.body);
        if (kDebugMode) {
          print('Error Details: $errorBody');
        }
        throw Exception('Failed to update maintenance date: ${response.statusCode}\n${errorBody['message'] ?? ''}');
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error updating maintenance date: $e');
      }
      if (kDebugMode) {
        print('Stacktrace: $stackTrace');
      }
      rethrow;
    }
  }


  // Update these methods to use http instead of dio
  static Future<void> updateVesselStage(String vesselId, MaintenanceStage stage) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();
      final shopId = await _getShopId();

      final response = await http.patch(
        Uri.parse('$_baseUrl/ro-systems/vessels/$vesselId/stage'),
        headers: headers,
        body: json.encode({
          'shop_id': shopId,
          'stage': stage.name,
          'start_time': DateTime.now().toIso8601String()
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update vessel stage: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating vessel stage: $e');
      }
      rethrow;
    }
  }

  static Future<List<MaintenanceRecord>> getVesselHistory(String vesselId) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();
      final shopId = await _getShopId();

      final response = await http.get(
        Uri.parse('$_baseUrl/maintenance-records'),
        headers: headers,
        // Using query parameters
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null || data['data'] == null) {
          return [];
        }

        final List<dynamic> records = data['data'] as List<dynamic>;
        return records
            .where((record) =>
        record['type'] == 'vessel' &&
            record['reference_id'] == vesselId)
            .map((record) => MaintenanceRecord.fromJson(record as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load vessel history: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching vessel history: $e');
      }
      rethrow;
    }
  }


  static Future<List<MaintenanceRecord>> getMaintenanceRecords({
    required String type,
  }) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();
      final shopId = await _getShopId();

      // Don't include type in query if requesting all records
      final queryString = type == 'all'
          ? 'shop_id=$shopId'
          : 'shop_id=$shopId&type=$type';

      final response = await http.get(
        Uri.parse('$_baseUrl/maintenance-records?$queryString'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null || data['data'] == null) {
          return [];
        }

        final List<dynamic> records = data['data'] as List<dynamic>;
        return records.map((record) => MaintenanceRecord.fromJson(record as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load maintenance records: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching maintenance records: $e');
      }
      rethrow;
    }
  }
  static DateTime _validateInstallationDate(DateTime date) {
    final now = DateTime.now();
    // If date is in the past, set it to 30 days from now
    if (date.isBefore(now)) {
      return now.add(const Duration(days: 30));
    }
    return date;
  }

  static Future<List<MaintenanceItem>> getMaintenanceItems() async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      // Get RO system first to validate setup
      final system = await getROSystem();
      if (system == null) {
        return [];
      }

      // Get all maintenance records
      final records = await getMaintenanceRecords(type: 'all');
      final now = DateTime.now();
      final items = <MaintenanceItem>[];

      // Process vessel maintenance
      for (final vessel in system.vessels) {
        final vesselRecords = records.where(
              (r) => r.type == 'vessel' && r.referenceId == vessel.id,
        ).toList();

        if (vesselRecords.isNotEmpty) {
          // Get the earliest future maintenance date
          final futureDates = vesselRecords
              .map((r) => r.maintenanceDate)
              .where((date) => date.isAfter(now))
              .toList();

          if (futureDates.isNotEmpty) {
            final nextMaintenance = futureDates.reduce((a, b) => a.isBefore(b) ? a : b);
            if (nextMaintenance.isBefore(now.add(const Duration(days: 7)))) {
              items.add(MaintenanceItem(
                type: vessel.type,
                id: vessel.id,
                maintenanceType: 'maintenance',
              ));
            }
          }
        }
      }

      // Process filter maintenance
      for (final filter in system.filters) {
        final filterRecords = records.where(
              (r) => r.type == 'filter' && r.referenceId == filter.id,
        ).toList();

        if (filterRecords.isNotEmpty) {
          // Get the earliest future replacement date
          final futureDates = filterRecords
              .map((r) => r.maintenanceDate)
              .where((date) => date.isAfter(now))
              .toList();

          if (futureDates.isNotEmpty) {
            final nextReplacement = futureDates.reduce((a, b) => a.isBefore(b) ? a : b);
            if (nextReplacement.isBefore(now.add(const Duration(days: 7)))) {
              items.add(MaintenanceItem(
                type: 'filter',
                id: filter.id,
                maintenanceType: 'replacement',
                filterLocation: filter.location,
                filterType: filter.type,
              ));
            }
          }
        }
      }

      // Process membrane maintenance similarly
      final membraneRecords = records.where((r) => r.type == 'membrane').toList();
      if (membraneRecords.isNotEmpty) {
        final futureDates = membraneRecords
            .map((r) => r.maintenanceDate)
            .where((date) => date.isAfter(now))
            .toList();

        if (futureDates.isNotEmpty) {
          final nextMembraneMaintenance = futureDates.reduce((a, b) => a.isBefore(b) ? a : b);
          if (nextMembraneMaintenance.isBefore(now.add(const Duration(days: 7)))) {
            items.add(MaintenanceItem(
              type: 'membrane',
              id: 'membrane_${system.id}',
              maintenanceType: 'replacement',
              membraneCount: system.membraneCount,
            ));
          }
        }
      }

      return items;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating maintenance items: $e');
      }
      rethrow;
    }
  }

  static Future<ROSystem?> getROSystemByShopId(int shopId) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/ro-systems/$shopId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null || data['data'] == null) {
          return null;
        }

        try {
          return ROSystem.fromJson(data['data'] as Map<String, dynamic>);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing RO system: $e');
          }
          return null;
        }
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load RO system: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching RO system: $e');
      }
      rethrow;
    }
  }

  static Future<List<MaintenanceRecord>> getMaintenanceRecordsByShopId(int shopId, {String? type}) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();

      // Build query parameters
      final queryParams = {'shop_id': shopId.toString()};
      if (type != null) {
        queryParams['type'] = type;
      }

      final uri = Uri.parse('$_baseUrl/maintenance-records').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null || data['data'] == null) {
          return [];
        }

        final List<dynamic> records = data['data'] as List<dynamic>;
        return records.map((record) => MaintenanceRecord.fromJson(record as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to load maintenance records: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching maintenance records: $e');
      }
      rethrow;
    }
  }
}
