import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'edit_discount_notifier.dart';
import 'edit_discount_state.dart';

final editDiscountProvider =
    StateNotifierProvider<EditDiscountNotifier, EditDiscountState>(
  (ref) => EditDiscountNotifier(discountRepository, galleryRepository),
);

