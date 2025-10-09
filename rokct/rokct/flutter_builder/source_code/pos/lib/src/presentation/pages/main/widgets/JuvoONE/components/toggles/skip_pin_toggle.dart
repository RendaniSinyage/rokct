import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../../../core/constants/constants.dart';
import '../../../../../../theme/app_style.dart';

final skipPINToggleProvider = StateNotifierProvider<SkipPINToggleNotifier, bool>((ref) => SkipPINToggleNotifier());

class SkipPINToggleNotifier extends StateNotifier<bool> {
  SkipPINToggleNotifier() : super(false) {
    _loadState();
  }

  static const String _key = 'skipPin';

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
    AppConstants.skipPin = state;
  }

  Future<void> toggle(bool value) async {
    state = value;
    AppConstants.skipPin = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

class SkipPINToggle extends ConsumerWidget {
  const SkipPINToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSkipPINEnabled = ref.watch(skipPINToggleProvider);

    return Switch(
      value: isSkipPINEnabled,
      onChanged: (bool value) {
        ref.read(skipPINToggleProvider.notifier).toggle(value);
      },
      activeColor: AppStyle.blue[900],
      activeTrackColor: AppStyle.blue[900]?.withOpacity(0.5),
      inactiveThumbColor: AppStyle.black,
      inactiveTrackColor: AppStyle.black.withOpacity(0.5),
    );
  }
}

// Helper function to get the current skipPIN state
bool isSkipPINEnabled(WidgetRef ref) {
  return ref.watch(skipPINToggleProvider);
}
