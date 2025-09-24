import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifier/stories_notifier.dart';
import '../state/stories_state.dart';

final storiesProvider = StateNotifierProvider<StoriesNotifier, StoriesState>(
  (ref) => StoriesNotifier(storiesRepository),
);

