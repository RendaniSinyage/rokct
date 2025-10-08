import 'package:admin_desktop/src/models/data/customer_model.dart';
import 'package:admin_desktop/src/models/data/delivery_point_data.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

part 'create_parcel_state.freezed.dart';

enum DestinationType { customer, pickupPoint, customLocation }

@freezed
class CreateParcelState with _$CreateParcelState {
  const factory CreateParcelState({
    // Loading indicators
    @Default(false) bool isCreating,
    @Default(false) bool isFetchingPoints,
    @Default(false) bool isSearchingCustomers,

    // Data lists
    @Default([]) List<DeliveryPointData> deliveryPoints,
    @Default([]) List<CustomerModel> searchedCustomers,

    // User selections
    @Default(DestinationType.customer) DestinationType destinationType,
    String? description,
    CustomerModel? selectedCustomer,
    DeliveryPointData? selectedPickupPoint,
    LatLng? selectedCustomLocation,
  }) = _CreateParcelState;
}