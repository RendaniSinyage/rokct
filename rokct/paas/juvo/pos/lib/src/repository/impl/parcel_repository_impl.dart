import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/core/models/models.dart';
import 'package:admin_desktop/src/core/models/response/response.dart';
import 'package:admin_desktop/src/repository/parcel_repository.dart';

class ParcelRepositoryImpl implements ParcelRepository {
  @override
  Future<SingleResponse> createParcelOrder({
    required int salesOrderId,
    required String deliveryPointId,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final data = {
        "order_data": {
          "sales_order_id": salesOrderId,
          "delivery_point_id": deliveryPointId,
          "items": items,
          // Other necessary parcel fields can be added here if needed
        }
      };
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/v1/method/rokct.paas.api.parcel.create_parcel_order',
        data: data,
      );
      return SingleResponse.fromJson(response.data, (data) => data);
    } catch (e) {
      return SingleResponse(
        statusCode: 1,
        error: NetworkExceptions.getDioException(e),
      );
    }
  }
}