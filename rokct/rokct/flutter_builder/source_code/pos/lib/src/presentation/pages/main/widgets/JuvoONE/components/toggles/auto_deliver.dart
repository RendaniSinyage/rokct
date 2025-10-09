import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../../../../core/constants/constants.dart';
import '../../../../../../theme/app_style.dart';


// autoDeliverProvider for the autoDeliver toggle
final autoDeliverProvider = StateNotifierProvider<autoDeliverNotifier, bool>((ref) => autoDeliverNotifier());

class autoDeliverNotifier extends StateNotifier<bool> {
  autoDeliverNotifier() : super(AppConstants.autoDeliver) {
    _loadState();
  }

  static const String _key = 'autoDeliver';

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
    AppConstants.autoDeliver = state;
  }

  Future<void> toggle(bool value) async {
    state = value;
    AppConstants.autoDeliver = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

class autoDeliver extends ConsumerWidget {
  const autoDeliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isautoDeliverEnabled = ref.watch(autoDeliverProvider);

    return Switch(
      value: isautoDeliverEnabled,
      onChanged: (bool value) {
        ref.read(autoDeliverProvider.notifier).toggle(value);
      },
      activeColor: AppStyle.blue[900],
      activeTrackColor: AppStyle.blue[900]?.withOpacity(0.5),
      inactiveThumbColor: AppStyle.black,
      inactiveTrackColor: AppStyle.black.withOpacity(0.5),
    );
  }
}

// Helper function to get the current autoDeliver state
bool isautoDeliverEnabled(WidgetRef ref) {
  return ref.watch(autoDeliverProvider);
}
