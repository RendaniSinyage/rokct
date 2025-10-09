import 'package:admin_desktop/src/models/data/delivery_point_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'send_to_pickup_state.freezed.dart';

@freezed
class SendToPickupState with _$SendToPickupState {
  const factory SendToPickupState({
    @Default(false) bool isLoading,
    @Default([]) List<DeliveryPointData> deliveryPoints,
    DeliveryPointData? selectedPoint,
  }) = _SendToPickupState;
}