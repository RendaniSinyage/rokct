import 'package:admin_desktop/src/presentation/pages/main/widgets/parcels/riverpod/create_parcel_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PickupPointSelectionView extends ConsumerStatefulWidget {
  const PickupPointSelectionView({super.key});

  @override
  ConsumerState<PickupPointSelectionView> createState() =>
      _PickupPointSelectionViewState();
}

class _PickupPointSelectionViewState
    extends ConsumerState<PickupPointSelectionView> {
  @override
  void initState() {
    super.initState();
    // Assuming the shop's location is available from a provider.
    // For now, using a default location.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createParcelProvider.notifier).fetchDeliveryPoints(
            context,
            latitude: 41.0082, // Default latitude
            longitude: 28.9784, // Default longitude
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createParcelProvider);
    final notifier = ref.read(createParcelProvider.notifier);

    return state.isFetchingPoints
        ? const Center(child: CircularProgressIndicator())
        : GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(41.0082, 28.9784), // Default center
              zoom: 12,
            ),
            markers: state.deliveryPoints.map((point) {
              return Marker(
                markerId: MarkerId(point.id ?? UniqueKey().toString()),
                position: LatLng(
                  point.latitude ?? 0,
                  point.longitude ?? 0,
                ),
                infoWindow: InfoWindow(title: point.name),
                onTap: () => notifier.selectPickupPoint(point),
              );
            }).toSet(),
          );
  }
}