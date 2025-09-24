import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../../../../../core/utils/utils.dart';
import '../models/data/energy_data.dart';
import '../../../../../../../../core/constants/constants.dart';

class EnergyService {
  // Use the same base URL as other working APIs
  static const String baseUrl = '${AppConstants.baseUrl}api/v1/rest/resources';

  // Use your app's standard headers
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Authorization': 'Bearer ${LocalStorage.getToken()}',
  };

  static Future<int?> _getShopId() async {
    final userData = LocalStorage.getUser();
    if (userData?.shop?.id == null) {
      throw Exception('Shop data not found');
    }
    return userData?.shop?.id;
  }

  Future<EnergyConsumptionData> fetchEnergyConsumption([int? shopId]) async {
    try {
      // Use provided shopId or try to get from current user
      final int? targetShopId = shopId ?? await _getShopId();

      if (targetShopId == null) {
        throw Exception('Shop ID is not available');
      }

      final uri = Uri.parse('$baseUrl/energy-consumption/$targetShopId');

      final response = await http.get(
        uri,
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return EnergyConsumptionData.fromJson(data['data']);
        }
        throw Exception(data['message'] ?? 'Failed to load energy consumption data');
      }
      throw Exception('Failed to load energy consumption data. Status: ${response.statusCode}');
    } catch (e) {
      if (kDebugMode) {
        print('Error in fetchEnergyConsumption: $e');
      }
      throw Exception('Error fetching energy consumption: ${e.toString()}');
    }
  }
}
