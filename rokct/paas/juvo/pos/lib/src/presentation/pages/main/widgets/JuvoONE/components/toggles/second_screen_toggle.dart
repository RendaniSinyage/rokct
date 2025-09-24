import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../../core/constants/constants.dart';
import '../../../../../../theme/app_style.dart';


final secondScreenToggleProvider = StateNotifierProvider<SecondScreenToggleNotifier, bool>((ref) => SecondScreenToggleNotifier());

class SecondScreenToggleNotifier extends StateNotifier<bool> {
  SecondScreenToggleNotifier() : super(AppConstants.secondScreen) {
    _loadState();
  }

  static const String _key = 'secondScreenEnabled';

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_key) ?? false;
    AppConstants.secondScreen = state;
  }

  Future<void> toggle(bool value) async {
    state = value;
    AppConstants.secondScreen = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}

class SecondScreenToggle extends ConsumerWidget {
  const SecondScreenToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSecondScreenEnabled = ref.watch(secondScreenToggleProvider);

    return Switch(
              value: isSecondScreenEnabled,
              onChanged: (bool value) {
                ref.read(secondScreenToggleProvider.notifier).toggle(value);
              },
              activeColor: AppStyle.blue[900],
              activeTrackColor: AppStyle.blue[900]?.withOpacity(0.5),
              inactiveThumbColor: AppStyle.black,
              inactiveTrackColor: AppStyle.black.withOpacity(0.5),

    );
  }
}

bool isSecondScreenEnabled(WidgetRef ref) {
  return ref.watch(secondScreenToggleProvider);
}
