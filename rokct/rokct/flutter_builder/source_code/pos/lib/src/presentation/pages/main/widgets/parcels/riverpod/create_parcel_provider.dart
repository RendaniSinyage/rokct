import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/parcels/riverpod/create_parcel_notifier.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/parcels/riverpod/create_parcel_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final createParcelProvider =
    StateNotifierProvider<CreateParcelNotifier, CreateParcelState>(
  (ref) => CreateParcelNotifier(
    parcelRepository,
    deliveryPointsRepository,
    usersRepository,
  ),
);