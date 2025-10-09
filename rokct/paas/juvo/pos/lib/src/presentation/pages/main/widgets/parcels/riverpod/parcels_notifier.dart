import 'package:admin_desktop/src/repository/parcel_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'parcels_state.dart';

class ParcelsNotifier extends StateNotifier<ParcelsState> {
  final ParcelRepository _parcelRepository;

  ParcelsNotifier(this._parcelRepository) : super(const ParcelsState());

  Future<void> fetchParcels(BuildContext context) async {
    state = state.copyWith(isLoading: true);
    final response = await _parcelRepository.getParcelOrders(); // Assuming getParcelOrders is in the repo
    response.when(
      success: (data) {
        state = state.copyWith(isLoading: false, parcelOrders: data.data ?? []);
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false);
        debugPrint('==> fetch parcel orders failure: $failure');
      },
    );
  }

  Future<void> updateParcelStatus(BuildContext context, {
    required String parcelOrderId,
    required String status,
  }) async {
    state = state.copyWith(isLoading: true);
    final response = await _parcelRepository.updateParcelStatus(
      parcelOrderId: parcelOrderId,
      status: status,
    );
    response.when(
      success: (data) {
        fetchParcels(context);
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false);
        debugPrint('==> update parcel status failure: $failure');
      },
    );
  }
}