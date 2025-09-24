import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'delivery_zone_state.dart';
import 'delivery_zone_notifier.dart';

final deliveryZoneProvider =
    StateNotifierProvider<DeliveryZoneNotifier, DeliveryZoneState>(
  (ref) => DeliveryZoneNotifier(usersRepository),
);

