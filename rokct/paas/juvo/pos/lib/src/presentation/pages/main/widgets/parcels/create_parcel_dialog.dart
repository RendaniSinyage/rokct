import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/core/utils/tr_keys.dart';
import 'package:admin_desktop/src/models/data/parcel_option_data.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/parcels/customer_selection_view.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/parcels/custom_location_selection_view.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/parcels/pickup_point_selection_view.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/parcels/riverpod/create_parcel_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/parcels/riverpod/create_parcel_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateParcelDialog extends ConsumerStatefulWidget {
  const CreateParcelDialog({super.key});

  @override
  ConsumerState<CreateParcelDialog> createState() => _CreateParcelDialogState();
}

class _CreateParcelDialogState extends ConsumerState<CreateParcelDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      final notifier = ref.read(createParcelProvider.notifier);
      switch (_tabController.index) {
        case 0:
          notifier.setDestinationType(DestinationType.customer);
          break;
        case 1:
          notifier.setDestinationType(DestinationType.pickupPoint);
          break;
        case 2:
          notifier.setDestinationType(DestinationType.customLocation);
          break;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(createParcelProvider.notifier).getParcelOptions(context);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(createParcelProvider.notifier);
    final state = ref.watch(createParcelProvider);

    return AlertDialog(
      title: const Text("Create New Parcel"),
      content: SizedBox(
        width: 600,
        height: 600,
        child: Column(
          children: [
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Parcel Description",
                hintText: "e.g., Box of documents",
              ),
              onChanged: notifier.setDescription,
            ),
            const SizedBox(height: 20),
            if (state.isFetchingOptions)
              const CircularProgressIndicator()
            else
              DropdownButton<ParcelOptionData>(
                value: state.selectedParcelOption,
                hint: const Text("Select Parcel Type"),
                isExpanded: true,
                onChanged: (ParcelOptionData? newValue) {
                  if (newValue != null) {
                    notifier.selectParcelOption(newValue);
                  }
                },
                items: state.parcelOptions
                    .map<DropdownMenuItem<ParcelOptionData>>(
                        (ParcelOptionData value) {
                  return DropdownMenuItem<ParcelOptionData>(
                    value: value,
                    child: Text(
                        "${value.title ?? ''} (${AppHelpers.numberFormat(number: value.price)})"),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: AppHelpers.getTranslation(TrKeys.customer)),
                const Tab(text: "Pickup Point"),
                Tab(text: AppHelpers.getTranslation(TrKeys.address)),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [
                  CustomerSelectionView(),
                  PickupPointSelectionView(),
                  CustomLocationSelectionView(),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: state.isCreating
              ? null
              : () {
                  notifier.createParcel(context, () {
                    Navigator.of(context).pop();
                  });
                },
          child: state.isCreating
              ? const CircularProgressIndicator()
              : const Text("Create"),
        ),
      ],
    );
  }
}