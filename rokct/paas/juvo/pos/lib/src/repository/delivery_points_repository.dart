import 'package:admin_desktop/src/core/models/models.dart';
import 'package:admin_desktop/src/core/models/response/response.dart';
import 'package:admin_desktop/src/models/data/delivery_point_data.dart';

abstract class DeliveryPointsRepository {
  Future<SingleResponse<List<DeliveryPointData>>> getDeliveryPoints({
    required double latitude,
    required double longitude,
  });
}