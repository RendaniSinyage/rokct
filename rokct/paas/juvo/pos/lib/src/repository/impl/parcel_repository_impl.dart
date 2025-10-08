import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/core/models/models.dart';
import 'package:admin_desktop/src/core/models/response/response.dart';
import 'package:admin_desktop/src/models/data/parcel_order_list_data.dart';
import 'package:admin_desktop/src/repository/parcel_repository.dart';

class ParcelRepositoryImpl implements ParcelRepository {
  @override
  Future<SingleResponse> createParcelOrder({
    required Map<String, dynamic> body,
  }) async {
    try {
      final data = {"order_data": body};
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

  @override
  Future<SingleResponse<List<ParcelOrderListData>>> getParcelOrders() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.parcel.get_parcel_orders',
      );
      return SingleResponse.fromJson(response.data, (data) {
        if (data == null) {
          return [];
        }
        return (data as List).map((e) => ParcelOrderListData.fromJson(e)).toList();
      });
    } catch (e) {
      return SingleResponse(
        statusCode: 1,
        error: NetworkExceptions.getDioException(e),
      );
    }
  }
}