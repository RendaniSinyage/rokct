import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import '../notifier/login_notifier.dart';
import '../state/login_state.dart';

final loginProvider =
    StateNotifierProvider.autoDispose<LoginNotifier, LoginState>(
  (ref) => LoginNotifier(authRepository, currenciesRepository,usersRepository),
);

