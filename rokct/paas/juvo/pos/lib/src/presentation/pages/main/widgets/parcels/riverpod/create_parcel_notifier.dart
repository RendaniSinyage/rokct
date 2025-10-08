import 'package:admin_desktop/src/models/data/customer_model.dart';
import 'package:admin_desktop/src/models/data/delivery_point_data.dart';
import 'package:admin_desktop/src/repository/delivery_points_repository.dart';
import 'package:admin_desktop/src/repository/parcel_repository.dart';
import 'package:admin_desktop/src/repository/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'create_parcel_state.dart';

class CreateParcelNotifier extends StateNotifier<CreateParcelState> {
  final ParcelRepository _parcelRepository;
  final DeliveryPointsRepository _deliveryPointsRepository;
  final UsersRepository _usersRepository;

  CreateParcelNotifier(
    this._parcelRepository,
    this._deliveryPointsRepository,
    this._usersRepository,
  ) : super(const CreateParcelState());

  void setDestinationType(DestinationType type) {
    state = state.copyWith(destinationType: type);
  }

  void setDescription(String description) {
    state = state.copyWith(description: description);
  }

  void selectCustomer(CustomerModel customer) {
    state = state.copyWith(selectedCustomer: customer);
  }

  void selectPickupPoint(DeliveryPointData point) {
    state = state.copyWith(selectedPickupPoint: point);
  }

  void selectCustomLocation(LatLng location) {
    state = state.copyWith(selectedCustomLocation: location);
  }

  Future<void> fetchDeliveryPoints(BuildContext context,
      {required double latitude, required double longitude}) async {
    state = state.copyWith(isFetchingPoints: true);
    final response = await _deliveryPointsRepository.getDeliveryPoints(
      latitude: latitude,
      longitude: longitude,
    );
    response.when(
      success: (data) {
        state = state.copyWith(
            isFetchingPoints: false, deliveryPoints: data.data ?? []);
      },
      failure: (failure) {
        state = state.copyWith(isFetchingPoints: false);
        debugPrint('==> fetch delivery points failure: $failure');
      },
    );
  }

  Future<void> searchUsers(BuildContext context, String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchedCustomers: [], isSearchingCustomers: false);
      return;
    }
    state = state.copyWith(isSearchingCustomers: true);
    final response = await _usersRepository.searchUsers(query: query);
    response.when(
      success: (data) {
        state = state.copyWith(
            isSearchingCustomers: false, searchedCustomers: data.data ?? []);
      },
      failure: (failure) {
        state = state.copyWith(isSearchingCustomers: false);
        debugPrint('==> search users failure: $failure');
      },
    );
  }

  Future<void> createParcel(BuildContext context, VoidCallback onSuccess) async {
    state = state.copyWith(isCreating: true);

    Map<String, dynamic> body = {
      "note": state.description,
      // Add other common fields here
    };

    switch (state.destinationType) {
      case DestinationType.customer:
        if (state.selectedCustomer == null) {
          state = state.copyWith(isCreating: false);
          // TODO: Show error
          return;
        }
        body.addAll({
          "destination_type": "customer",
          "customer_id": state.selectedCustomer?.id,
          "address_to": (state.selectedCustomer?.addresses?.isNotEmpty ?? false)
              ? state.selectedCustomer?.addresses?.first.address
              : "N/A",
        });
        break;
      case DestinationType.pickupPoint:
        if (state.selectedPickupPoint == null) {
          state = state.copyWith(isCreating: false);
          // TODO: Show error
          return;
        }
        body.addAll({
          "destination_type": "delivery_point",
          "delivery_point_id": state.selectedPickupPoint?.id,
        });
        break;
      case DestinationType.customLocation:
        if (state.selectedCustomLocation == null) {
          state = state.copyWith(isCreating: false);
          // TODO: Show error
          return;
        }
        body.addAll({
          "destination_type": "custom_location",
          "address_to": {
            "latitude": state.selectedCustomLocation?.latitude,
            "longitude": state.selectedCustomLocation?.longitude,
          }
        });
        break;
    }

    final response = await _parcelRepository.createParcelOrder(body: body);

    response.when(
      success: (data) {
        state = state.copyWith(isCreating: false);
        onSuccess();
      },
      failure: (failure) {
        state = state.copyWith(isCreating: false);
        debugPrint('==> create parcel order failure: $failure');
        // TODO: Show failure message
      },
    );
  }
}