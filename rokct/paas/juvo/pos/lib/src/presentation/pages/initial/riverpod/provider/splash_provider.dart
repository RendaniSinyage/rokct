import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import '../notifier/splash_notifier.dart';
import '../state/splash_state.dart';

final splashProvider = StateNotifierProvider<SplashNotifier, SplashState>(
  (ref) => SplashNotifier(settingsRepository),
);

