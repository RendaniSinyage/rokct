import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import '../notifier/main_notifier.dart';
import '../state/main_state.dart';

final mainProvider = StateNotifierProvider<MainNotifier, MainState>(
  (ref) => MainNotifier(
    productsRepository,
    categoriesRepository,
    brandsRepository,
    usersRepository,
  ),
);

