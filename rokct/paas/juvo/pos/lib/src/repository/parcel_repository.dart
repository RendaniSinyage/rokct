import 'package:admin_desktop/src/core/models/models.dart';
import 'package:admin_desktop/src/core/models/response/response.dart';
import 'package:admin_desktop/src/models/data/parcel_order_list_data.dart';

abstract class ParcelRepository {
  Future<SingleResponse> createParcelOrder({
    required Map<String, dynamic> body,
  });

  Future<SingleResponse<List<ParcelOrderListData>>> getParcelOrders();

  Future<SingleResponse> updateParcelStatus({
    required String parcelOrderId,
    required String status,
  });
}