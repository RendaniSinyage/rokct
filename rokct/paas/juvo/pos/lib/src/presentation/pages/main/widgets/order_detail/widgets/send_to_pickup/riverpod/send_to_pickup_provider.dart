import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/order_detail/widgets/send_to_pickup/riverpod/send_to_pickup_notifier.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/order_detail/widgets/send_to_pickup/riverpod/send_to_pickup_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sendToPickupProvider =
    StateNotifierProvider<SendToPickupNotifier, SendToPickupState>(
  (ref) => SendToPickupNotifier(deliveryPointsRepository),
);