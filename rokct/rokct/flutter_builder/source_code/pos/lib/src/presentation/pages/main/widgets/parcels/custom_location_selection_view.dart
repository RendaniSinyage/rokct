import 'package:admin_desktop/src/presentation/pages/main/widgets/parcels/riverpod/create_parcel_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomLocationSelectionView extends ConsumerWidget {
  const CustomLocationSelectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createParcelProvider);
    final notifier = ref.read(createParcelProvider.notifier);

    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(41.0082, 28.9784), // Default center
        zoom: 12,
      ),
      onTap: (LatLng location) {
        notifier.selectCustomLocation(location);
      },
      markers: state.selectedCustomLocation == null
          ? {}
          : {
              Marker(
                markerId: const MarkerId("selectedLocation"),
                position: state.selectedCustomLocation!,
              ),
            },
    );
  }
}