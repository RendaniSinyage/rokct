import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import '../notifier/edit_stories_notifier.dart';
import '../state/edit_stories_state.dart';

final editStoriesProvider =
    StateNotifierProvider<EditStoriesNotifier, EditStoriesState>(
  (ref) => EditStoriesNotifier(storiesRepository, galleryRepository),
);

