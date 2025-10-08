import 'package:admin_desktop/src/core/models/models.dart';
import 'package:admin_desktop/src/core/models/response/response.dart';

abstract class ParcelRepository {
  Future<SingleResponse> createParcelOrder({
    required int salesOrderId,
    required String deliveryPointId,
    required List<Map<String, dynamic>> items,
  });
}