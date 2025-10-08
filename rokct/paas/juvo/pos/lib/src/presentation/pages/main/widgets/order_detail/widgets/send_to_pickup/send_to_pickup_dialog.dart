import 'package:admin_desktop/src/core/models/models.dart';
import 'package:admin_desktop/src/presentation/components/buttons/confirm_button.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/order_detail/widgets/send_to_pickup/riverpod/send_to_pickup_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SendToPickupDialog extends ConsumerStatefulWidget {
  final OrderData? order;

  const SendToPickupDialog({super.key, this.order});

  @override
  ConsumerState<SendToPickupDialog> createState() => _SendToPickupDialogState();
}

class _SendToPickupDialogState extends ConsumerState<SendToPickupDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final shopLocation = widget.order?.shop?.location;
      if (shopLocation?.latitude != null && shopLocation?.longitude != null) {
        ref.read(sendToPickupProvider.notifier).fetchDeliveryPoints(
              context,
              latitude: shopLocation!.latitude!,
              longitude: shopLocation.longitude!,
            );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sendToPickupProvider);
    final notifier = ref.read(sendToPickupProvider.notifier);
    final shopLocation = widget.order?.shop?.location;

    return AlertDialog(
      title: const Text("Send to Pickup Point"),
      content: SizedBox(
        width: 600,
        height: 500,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          shopLocation?.latitude ?? 0,
                          shopLocation?.longitude ?? 0,
                        ),
                        zoom: 12,
                      ),
                      markers: state.deliveryPoints.map((point) {
                        return Marker(
                          markerId: MarkerId(point.id ?? ''),
                          position: LatLng(
                            point.latitude ?? 0,
                            point.longitude ?? 0,
                          ),
                          infoWindow: InfoWindow(title: point.name),
                          onTap: () => notifier.selectPoint(point),
                        );
                      }).toSet(),
                    ),
                  ),
                  if (state.selectedPoint != null)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("Selected: ${state.selectedPoint?.name}"),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ConfirmButton(
          title: "Confirm",
          onTap: state.selectedPoint == null
              ? null
              : () {
                  notifier.createParcelOrder(
                    context,
                    order: widget.order!,
                    onSuccess: () {
                      Navigator.of(context).pop();
                      // TODO: Show success message
                    },
                  );
                },
        ),
      ],
    );
  }
}