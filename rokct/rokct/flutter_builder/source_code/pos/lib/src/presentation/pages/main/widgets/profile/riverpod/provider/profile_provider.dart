import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import '../notifier/profile_notifier.dart';
import '../state/profile_state.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>(
  (ref) =>
      ProfileNotifier(usersRepository, galleryRepository, shopsRepository),
);

