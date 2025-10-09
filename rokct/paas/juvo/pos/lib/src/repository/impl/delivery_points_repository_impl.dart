import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/core/models/models.dart';
import 'package:admin_desktop/src/core/models/response/response.dart';
import 'package:admin_desktop/src/models/data/delivery_point_data.dart';
import 'package:admin_desktop/src/repository/delivery_points_repository.dart';

class DeliveryPointsRepositoryImpl implements DeliveryPointsRepository {
  @override
  Future<SingleResponse<List<DeliveryPointData>>> getDeliveryPoints({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final data = {
        'latitude': latitude,
        'longitude': longitude,
      };
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.doctype.delivery_point.delivery_point.get_nearest_delivery_points',
        queryParameters: data,
      );
      return SingleResponse.fromJson(response.data, (data) {
        if (data == null) {
          return [];
        }
        return (data as List)
            .map((e) => DeliveryPointData.fromJson(e))
            .toList();
      });
    } catch (e) {
      return SingleResponse(
        statusCode: 1,
        error: NetworkExceptions.getDioException(e),
      );
    }
  }
}