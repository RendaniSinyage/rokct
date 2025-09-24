import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'delivery_zone_state.freezed.dart';

@freezed
class DeliveryZoneState with _$DeliveryZoneState {
  const factory DeliveryZoneState({
    @Default(false) bool isLoading,
    @Default(false) bool isSaving,
    @Default([]) List<List<double>> deliveryZones,
    @Default([]) List<LatLng> tappedPoints,
    @Default({}) Set<Polygon> polygon,
  }) = _DeliveryZoneState;

  const DeliveryZoneState._();
}

