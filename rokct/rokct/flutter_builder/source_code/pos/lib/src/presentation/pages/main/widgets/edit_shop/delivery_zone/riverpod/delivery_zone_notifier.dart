import 'dart:collection';

import 'package:admin_desktop/src/repository/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


import '../../../../../../theme/theme.dart';
import 'delivery_zone_state.dart';

class DeliveryZoneNotifier extends StateNotifier<DeliveryZoneState> {
  final UsersRepository _usersRepository;

  DeliveryZoneNotifier(this._usersRepository)
      : super(const DeliveryZoneState());

  Future<void> updateDeliveryZone({VoidCallback? updateSuccess}) async {
    state = state.copyWith(isSaving: true);
    final response =
        await _usersRepository.updateDeliveryZones(points: state.tappedPoints);
    response.when(
      success: (data) {
        state = state.copyWith(isSaving: false);
      },
      failure: (fail) {
        state = state.copyWith(isSaving: false);
        debugPrint('===> update delivery zone failed $fail');
      },
    );
  }

  void addTappedPoint(LatLng point) {
    List<LatLng> points = List.from(state.tappedPoints);
    points.add(point);
    final Set<Polygon> polygon = HashSet<Polygon>();
    if (points.isNotEmpty) {
      polygon.add(
        Polygon(
          polygonId: const PolygonId('1'),
          points: points,
          fillColor: AppStyle.primary.withOpacity(0.3),
          strokeColor: AppStyle.primary,
          geodesic: false,
          strokeWidth: 4,
        ),
      );
    }
    state = state.copyWith(tappedPoints: points, polygon: polygon);
  }

  Future<void> fetchDeliveryZone() async {
    state = state.copyWith(isLoading: true, tappedPoints: []);
    final response = await _usersRepository.getDeliveryZone();
    response.when(
      success: (data) {
        if (data.data != null) {
          final Set<Polygon> polygon = HashSet<Polygon>();
          final List<List<double>> addresses = data.data?.address ?? [];
          List<LatLng> points = [];
          for (final address in addresses) {
            final latLng = LatLng(address[0], address[1]);
            points.add(latLng);
          }
          polygon.add(
            Polygon(
              polygonId: const PolygonId('1'),
              points: points,
              fillColor: AppStyle.primary.withOpacity(0.3),
              strokeColor: AppStyle.primary,
              geodesic: false,
              strokeWidth: 4,
            ),
          );
          state = state.copyWith(
            deliveryZones: addresses,
            polygon: polygon,
            isLoading: false,
          );
        }
      },
      failure: (failure) {
        state = state.copyWith(isLoading: false);
        debugPrint('==> error with fetching delivery zone $failure');
      },
    );
  }
}

