import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:foodyman/infrastructure/models/data/delivery_point_data.dart';

part 'delivery_points_state.freezed.dart';

@freezed
class DeliveryPointsState with _$DeliveryPointsState {
  const factory DeliveryPointsState({
    @Default(false) bool isLoading,
    @Default([]) List<DeliveryPointData> deliveryPoints,
  }) = _DeliveryPointsState;

  const DeliveryPointsState._();
}