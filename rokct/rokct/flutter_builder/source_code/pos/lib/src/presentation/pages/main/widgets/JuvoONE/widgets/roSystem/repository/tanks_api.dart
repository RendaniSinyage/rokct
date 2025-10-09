import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../../core/utils/utils.dart';
import '../models/data/tank_models.dart';

class TankApiService {
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

  static Future<List<Tank>> getTanks() async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();
      final shopId = await _getShopId();

      final response = await http.get(
        Uri.parse('$_baseUrl/tanks?shop_id=$shopId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((item) => Tank.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load tanks');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tanks: $e');
      }
      rethrow;
    }
  }

  static Future<Tank> createTank(Tank tank) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();
      final tankJson = tank.toJson();

      if (tank.status == TankStatus.full) {
        tankJson['last_full'] = DateTime.now().toIso8601String();
      }

      final response = await http.post(
        Uri.parse('$_baseUrl/tanks'),
        headers: headers,
        body: json.encode(tankJson),
      );

      if (response.statusCode == 201) {
        return Tank.fromJson(json.decode(response.body)['data']);
      } else {
        if (kDebugMode) {
          print('Failed to create tank. Response: ${response.body}');
        }
        throw Exception('Failed to create tank');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating tank: $e');
      }
      rethrow;
    }
  }

  static Future<List<Tank>> getTanksByShopId(int shopId) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();

      final response = await http.get(
        Uri.parse('$_baseUrl/tanks?shop_id=$shopId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body)['data'];
        return data.map((item) => Tank.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load tanks for shop $shopId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tanks for shop $shopId: $e');
      }
      rethrow;
    }
  }

  static Future<Tank> updateTank(Tank tank) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();
      final tankJson = tank.toJson();

      final response = await http.put(
        Uri.parse('$_baseUrl/tanks/${tank.id}'),
        headers: headers,
        body: json.encode(tankJson),
      );

      if (response.statusCode == 200) {
        return Tank.fromJson(json.decode(response.body)['data']);
      } else {
        if (kDebugMode) {
          print('Failed to update tank. Response: ${response.body}');
        }
        throw Exception('Failed to update tank');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating tank: $e');
      }
      rethrow;
    }
  }

  static Future<void> deleteTank(int id) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$_baseUrl/tanks/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete tank');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting tank: $e');
      }
      rethrow;
    }
  }

  static Future<void> updateTankStatus(int id, TankStatus status) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> payload = {
        'status': status.toString().split('.').last,
      };

      if (status == TankStatus.full) {
        payload['last_full'] = DateTime.now().toIso8601String();
      }

      final response = await http.patch(
        Uri.parse('$_baseUrl/tanks/$id/status'),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update tank status');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating tank status: $e');
      }
      rethrow;
    }
  }

  static Future<void> updatePumpStatus(int id, bool isOn, double currentFlowRate) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> payload = {
        'pump_status': {
          'isOn': isOn,
          'flowRate': isOn ? currentFlowRate : 0.0
        }
      };

      if (kDebugMode) {
        print('Updating pump status with payload: $payload');
      }

      final response = await http.patch(
        Uri.parse('$_baseUrl/tanks/$id/pump'),
        headers: headers,
        body: json.encode(payload),
      );

      if (kDebugMode) {
        print('Response status code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to update pump status: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating pump status: $e');
      }
      rethrow;
    }
  }

  static Future<void> updatePumpOnlyStatus(int id, bool isOn) async {
    if (!await _checkConnectivity()) {
      throw Exception('No internet connection');
    }

    try {
      final headers = await _getHeaders();
      final Map<String, dynamic> payload = {
        'pump_status': {
          'isOn': isOn,
          // Not including flowRate in payload so it won't be updated
        }
      };

      if (kDebugMode) {
        print('Updating pump status with payload: $payload');
      }

      final response = await http.patch(
        Uri.parse('$_baseUrl/tanks/$id/pump'),
        headers: headers,
        body: json.encode(payload),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update pump status: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating pump status: $e');
      }
      rethrow;
    }
  }


}
