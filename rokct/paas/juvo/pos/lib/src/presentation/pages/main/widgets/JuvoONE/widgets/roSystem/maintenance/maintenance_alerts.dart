// maintenance_alert.dart
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../../core/utils/utils.dart';
import 'maintenance_dialog.dart';
import '../repository/ro_system_api.dart';

final maintenanceProvider = StateNotifierProvider<MaintenanceNotifier, MaintenanceState>((ref) {
  return MaintenanceNotifier();
});

class MaintenanceState {
  final bool hasMaintenanceItems;
  final bool needsSetup;
  final bool isLoading;
  final String? error;

  MaintenanceState({
    this.hasMaintenanceItems = false,
    this.needsSetup = false,
    this.isLoading = false,
    this.error,
  });

  MaintenanceState copyWith({
    bool? hasMaintenanceItems,
    bool? needsSetup,
    bool? isLoading,
    String? error,
  }) {
    return MaintenanceState(
      hasMaintenanceItems: hasMaintenanceItems ?? this.hasMaintenanceItems,
      needsSetup: needsSetup ?? this.needsSetup,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MaintenanceNotifier extends StateNotifier<MaintenanceState> {
  MaintenanceNotifier() : super(MaintenanceState()) {
    checkMaintenance();
  }

  Future<void> checkMaintenance() async {
    if (mounted) {
      state = state.copyWith(isLoading: true, error: null);

      try {
        // First check if RO system exists
        final system = await MaintenanceApiService.getROSystem();

        if (system == null) {
          // No RO system configured
          if (mounted) {
            state = state.copyWith(
              hasMaintenanceItems: false,
              needsSetup: true, // Set to true when no system exists
              isLoading: false,
            );
          }
          return; // Exit early
        }

        // If system exists, check maintenance items
        final items = await MaintenanceApiService.getMaintenanceItems();

        if (mounted) {
          state = state.copyWith(
            hasMaintenanceItems: items.isNotEmpty,
            needsSetup: false, // System exists, so no setup needed
            isLoading: false,
          );
        }
      } catch (e) {
        if (mounted) {
          state = state.copyWith(
            isLoading: false,
            error: e.toString(),
          );
        }
      }
    }
  }

  void startPeriodicCheck() {
    Future.delayed(const Duration(minutes: 5), () {
      if (mounted) {
        checkMaintenance();
        startPeriodicCheck();
      }
    });
  }
}

class MaintenanceAlert extends ConsumerStatefulWidget {
  const MaintenanceAlert({super.key});

  @override
  ConsumerState<MaintenanceAlert> createState() => _MaintenanceAlertState();
}

class _MaintenanceAlertState extends ConsumerState<MaintenanceAlert> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(maintenanceProvider.notifier).startPeriodicCheck();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceProvider);

    if (state.isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }

    final alertColor = state.needsSetup ? Colors.amber :
    state.hasMaintenanceItems ? Colors.amber :
    Colors.grey;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.error != null)
          Tooltip(
            message: state.error,
            child: const Icon(
              FlutterRemix.error_warning_fill,
              color: Colors.red,
              size: 24,
            ),
          )
        else
          !state.needsSetup ?
          IconButton(
            onPressed: () {
              AppHelpers.showAlertDialog(
                context: context,
                child: const MaintenanceDialog(), // Show maintenance dialog otherwise
              );
            },
            icon: Icon( FlutterRemix.alert_fill,
              color: alertColor,
              size: 24,
            ),
            tooltip: state.hasMaintenanceItems
                ? AppHelpers.getTranslation(TrKeys.maintenanceRequired)
                : AppHelpers.getTranslation(TrKeys.noMaintenanceAlerts),
          ) : const SizedBox.shrink(),
        const VerticalDivider(),
      ],
    );
  }
}
