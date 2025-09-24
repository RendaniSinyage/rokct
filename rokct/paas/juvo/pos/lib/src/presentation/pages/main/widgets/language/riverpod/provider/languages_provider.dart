import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import '../notifier/languages_notifier.dart';
import '../state/languages_state.dart';

final languagesProvider =
    StateNotifierProvider<LanguagesNotifier, LanguagesState>(
  (ref) => LanguagesNotifier(settingsRepository),
);

