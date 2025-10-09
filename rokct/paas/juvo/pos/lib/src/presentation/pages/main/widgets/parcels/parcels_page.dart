import 'package:admin_desktop/src/models/data/parcel_order_list_data.dart';
import 'package:admin_desktop/src/presentation/components/buttons/confirm_button.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/parcels/riverpod/parcels_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'create_parcel_dialog.dart';

class ParcelsPage extends ConsumerStatefulWidget {
  const ParcelsPage({super.key});

  @override
  ConsumerState<ParcelsPage> createState() => _ParcelsPageState();
}

class _ParcelsPageState extends ConsumerState<ParcelsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(parcelsProvider.notifier).fetchParcels(context);
    });
  }

  void _showStatusDialog(ParcelOrderListData parcel) {
    showDialog(
      context: context,
      builder: (context) {
        return StatusUpdateDialog(parcel: parcel);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(parcelsProvider);
    final notifier = ref.read(parcelsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Parcel Orders"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => notifier.fetchParcels(context),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: state.parcelOrders.length,
              itemBuilder: (context, index) {
                final parcel = state.parcelOrders[index];
                return ListTile(
                  title: Text("Parcel #${parcel.name}"),
                  subtitle: Text("To: ${parcel.addressTo ?? 'N/A'}"),
                  trailing: Text(parcel.status ?? "Unknown"),
                  onTap: () => _showStatusDialog(parcel),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return const CreateParcelDialog();
            },
          );
        },
        label: const Text("Create New Parcel"),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class StatusUpdateDialog extends ConsumerStatefulWidget {
  final ParcelOrderListData parcel;

  const StatusUpdateDialog({super.key, required this.parcel});

  @override
  ConsumerState<StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends ConsumerState<StatusUpdateDialog> {
  late String _selectedStatus;
  final List<String> _statuses = [
    "New",
    "Pending",
    "Accepted",
    "Ready",
    "On A Way",
    "Delivered",
    "Canceled"
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.parcel.status ?? "New";
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(parcelsProvider.notifier);
    return AlertDialog(
      title: Text("Update Status for Parcel #${widget.parcel.name}"),
      content: DropdownButton<String>(
        value: _selectedStatus,
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedStatus = newValue;
            });
          }
        },
        items: _statuses.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ConfirmButton(
          title: "Update",
          onTap: () {
            notifier.updateParcelStatus(
              context,
              parcelOrderId: widget.parcel.name!,
              status: _selectedStatus,
            );
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}