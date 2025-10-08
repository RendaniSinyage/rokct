import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/parcels/riverpod/parcels_notifier.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/parcels/riverpod/parcels_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final parcelsProvider =
    StateNotifierProvider<ParcelsNotifier, ParcelsState>(
  (ref) => ParcelsNotifier(parcelRepository),
);