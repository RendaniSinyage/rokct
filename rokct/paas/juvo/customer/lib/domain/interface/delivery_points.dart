import 'package:foodyman/domain/handlers/api_result.dart';
import 'package:foodyman/infrastructure/models/data/delivery_point_data.dart';

abstract class DeliveryPointsRepositoryFacade {
  Future<ApiResult<List<DeliveryPointData>>> getDeliveryPoints({
    required double latitude,
    required double longitude,
  });
}