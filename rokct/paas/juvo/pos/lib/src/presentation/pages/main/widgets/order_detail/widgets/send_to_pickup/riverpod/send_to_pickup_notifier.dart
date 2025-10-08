import 'package:admin_desktop/src/core/models/models.dart';
import 'package:admin_desktop/src/repository/delivery_points_repository.dart';
import 'package:admin_desktop/src/repository/parcel_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'send_to_pickup_state.dart';

class SendToPickupNotifier extends StateNotifier<SendToPickupState> {
  final DeliveryPointsRepository _deliveryPointsRepository;
  final ParcelRepository _parcelRepository;

  SendToPickupNotifier(this._deliveryPointsRepository, this._parcelRepository)
      : super(const SendToPickupState());

  Future<void> fetchDeliveryPoints(BuildContext context, {
    required double latitude,
    required double longitude,
  }) async {
    state = state.copyWith(isLoading: true);
    final response = await _deliveryPointsRepository.getDeliveryPoints(
      latitude: latitude,
      longitude: longitude,
    );
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false, deliveryPoints: data.data ?? []);
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false);
        debugPrint('==> fetch delivery points failure: $failure');
      },
    );
  }

  void selectPoint(DeliveryPointData point) {
    state = state.copyWith(selectedPoint: point);
  }

  Future<void> createParcelOrder(BuildContext context, {
    required OrderData order,
    required VoidCallback onSuccess,
  }) async {
    if (state.selectedPoint == null) {
      // Should not happen as button is disabled, but as a safeguard.
      return;
    }

    state = state.copyWith(isLoading: true);

    final items = order.details?.map((detail) {
      return {
        "item_code": detail.stock?.product?.id,
        "item_name": detail.stock?.product?.translation?.title,
        "quantity": detail.quantity,
        "sales_order_item": detail.id
      };
    }).toList() ?? [];

    final body = {
      "sales_order_id": order.id,
      "delivery_point_id": state.selectedPoint?.id,
      "items": items,
      "destination_type": "delivery_point",
      "address_to": state.selectedPoint?.address,
      "username_to": "Pickup Point: ${state.selectedPoint?.name}",
      // You can add other fields from the order if needed, e.g.,
      // "phone_to": order.user?.phone,
    };

    final response = await _parcelRepository.createParcelOrder(body: body);

    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false);
        onSuccess();
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false);
        debugPrint('==> create parcel order failure: $failure');
      },
    );
  }
}