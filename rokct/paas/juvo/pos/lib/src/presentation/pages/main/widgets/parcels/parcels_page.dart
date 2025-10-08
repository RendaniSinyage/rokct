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