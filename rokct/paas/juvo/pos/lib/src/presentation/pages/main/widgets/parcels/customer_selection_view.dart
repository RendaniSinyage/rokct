import 'package:admin_desktop/src/presentation/pages/main/widgets/parcels/riverpod/create_parcel_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomerSelectionView extends ConsumerWidget {
  const CustomerSelectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createParcelProvider);
    final notifier = ref.read(createParcelProvider.notifier);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextFormField(
            decoration: const InputDecoration(
              labelText: "Search Customer",
              hintText: "Enter name or phone number",
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) {
              notifier.searchUsers(context, value);
            },
          ),
        ),
        if (state.isSearchingCustomers)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: state.searchedCustomers.length,
            itemBuilder: (context, index) {
              final user = state.searchedCustomers[index];
              return ListTile(
                title: Text("${user.firstname ?? ''} ${user.lastname ?? ''}"),
                subtitle: Text(user.email ?? user.phone?.toString() ?? 'No contact info'),
                onTap: () => notifier.selectCustomer(user),
                selected: state.selectedCustomer?.id == user.id,
              );
            },
          ),
        ),
      ],
    );
  }
}