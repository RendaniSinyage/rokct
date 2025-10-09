import 'package:flutter/material.dart';
import 'package:foodyman/domain/di/dependency_manager.dart';
import 'package:foodyman/domain/handlers/api_result.dart';
import 'package:foodyman/domain/handlers/network_exceptions.dart';
import 'package:foodyman/domain/interface/delivery_points.dart';
import 'package:foodyman/infrastructure/models/data/delivery_point_data.dart';
import 'package:foodyman/infrastructure/services/app_helpers.dart';

class DeliveryPointsRepository implements DeliveryPointsRepositoryFacade {
  @override
  Future<ApiResult<List<DeliveryPointData>>> getDeliveryPoints({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/v1/method/rokct.paas.doctype.delivery_point.delivery_point.get_nearest_delivery_points',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      final List<dynamic> data = response.data['message'];
      final List<DeliveryPointData> deliveryPoints =
          data.map((e) => DeliveryPointData.fromJson(e)).toList();
      return ApiResult.success(data: deliveryPoints);
    } catch (e) {
      debugPrint('==> get delivery points failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }
}