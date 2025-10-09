import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../../core/constants/constants.dart';
import '../../../../../../theme/app_style.dart';

// StateNotifierProvider for the WaterOS toggle
final waterOSToggleProvider = StateNotifierProvider<WaterOSToggleNotifier, bool>((ref) => WaterOSToggleNotifier());

class WaterOSToggleNotifier extends StateNotifier<bool> {
  WaterOSToggleNotifier() : super(AppConstants.enableJuvoONE) {
    _loadState();
  }

  static const String _key = 'enableJuvoONE';

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
    AppConstants.enableJuvoONE = state;
  }

  Future<void> toggle(bool value) async {
    state = value;
    AppConstants.enableJuvoONE = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

class WaterOSToggle extends ConsumerWidget {
  const WaterOSToggle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWaterOSEnabled = ref.watch(waterOSToggleProvider);

    return Switch(
      value: isWaterOSEnabled,
      onChanged: (bool value) {
        ref.read(waterOSToggleProvider.notifier).toggle(value);
      },
      activeColor: AppStyle.blue[900],
      activeTrackColor: AppStyle.blue[900]?.withOpacity(0.5),
      inactiveThumbColor: AppStyle.black,
      inactiveTrackColor: AppStyle.black.withOpacity(0.5),
    );
  }
}

// Helper function to get the current WaterOS state
bool isWaterOSEnabled(WidgetRef ref) {
  return ref.watch(waterOSToggleProvider);
}
