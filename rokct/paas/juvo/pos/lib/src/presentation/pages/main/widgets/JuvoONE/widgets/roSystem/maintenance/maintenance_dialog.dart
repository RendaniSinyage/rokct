import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_remix/flutter_remix.dart';
import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../../core/utils/utils.dart';
import '../../../../../../../theme/theme.dart';
import '../models/data/ro_system_model.dart';
import '../repository/ro_system_api.dart';
import 'maintenance_item.dart';
import '../setup_dialog.dart';
import 'maintenance_timer_dialog.dart';

class MaintenanceDialog extends StatefulWidget {
  const MaintenanceDialog({super.key});

  @override
  State<MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<MaintenanceDialog> {
  String? activeMaintenance;
  MaintenanceItem? activeItem;
  List<MaintenanceItem> items = [];
  bool isLoading = true;
  ROSystem? currentSystem;

  @override
  void initState() {
    super.initState();
    _loadMaintenanceItems();
  }

  Future<void> _loadMaintenanceItems() async {
    try {
      final system = await MaintenanceApiService.getROSystem();
      final maintenanceItems =
          await MaintenanceApiService.getMaintenanceItems();

      if (mounted) {
        setState(() {
          currentSystem = system;
          items = maintenanceItems;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading maintenance items: $e'),
            backgroundColor: AppStyle.red,
          ),
        );
      }
    }
  }

  Future<void> _handleMaintenanceAction(MaintenanceItem item) async {
    // Handle setup actions
    if (item.type == 'setup' ||
        item.type == 'vessel_setup' ||
        item.type == 'filter_setup' ||
        item.type == 'membrane_setup') {
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => const SystemSetupDialog(),
        );
        _loadMaintenanceItems();
      }
      return;
    }

    // For vessel maintenance, show timer dialog
    if ((item.type == 'megaChar' || item.type == 'softener') &&
        item.maintenanceType == 'maintenance' &&
        currentSystem != null) {
      final vessel = currentSystem!.vessels.firstWhere((v) => v.id == item.id);
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => MaintenanceTimerDialog(vessel: vessel),
        );
        _loadMaintenanceItems();
      }
      return;
    }

    setState(() {
      activeMaintenance = item.type;
      activeItem = item;
    });
  }

  Future<void> _handleMaintenanceComplete() async {
    if (activeItem == null || currentSystem == null) return;

    try {
      if (activeItem!.type == 'membrane') {
        await MaintenanceApiService.updateMaintenanceDate(
          type: 'membrane',
          referenceId: 'membrane_${currentSystem!.membraneCount}',
          date: DateTime.now(),
        );
      } else if (activeItem!.type == 'filter') {
        // Handle individual filter replacement
        final filters = currentSystem!.filters.map((f) {
          if (f.id == activeItem!.id) {
            return Filter(
              id: f.id,
              type: f.type,
              location: f.location,
              installationDate: DateTime.now(),
            );
          }
          return f;
        }).toList();

        await MaintenanceApiService.saveROSystem(
          ROSystem(
            filters: filters,
            vessels: currentSystem!.vessels,
            membraneCount: currentSystem!.membraneCount,
            membraneInstallationDate: currentSystem!.membraneInstallationDate,
          ),
        );
      } else {
        // Vessel maintenance
        await MaintenanceApiService.updateMaintenanceDate(
          type: 'vessel',
          referenceId: activeItem!.id!,
          date: DateTime.now(),
        );
      }

      await _loadMaintenanceItems();
      if (mounted) {
        setState(() {
          activeMaintenance = null;
          activeItem = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing maintenance: $e'),
            backgroundColor: AppStyle.red,
          ),
        );
      }
    }
  }

  String _getMaintenanceTitle() {
    if (activeItem == null) return '';

    if (activeItem!.type == 'filter') {
      final filterLocation =
          activeItem!.filterLocation?.toString().split('.').last;
      if (filterLocation != null) {
        final filterDisplayName = switch (filterLocation) {
          'pre' => AppHelpers.getTranslation(TrKeys.preFilter),
          'ro' => AppHelpers.getTranslation(TrKeys.roFilter),
          'post' => AppHelpers.getTranslation(TrKeys.postFilter),
          _ => ''
        };
        return '$filterDisplayName ${AppHelpers.getTranslation(TrKeys.replacement)}';
      }
    }

    if (activeItem!.type == 'membrane') {
      return '${AppHelpers.getTranslation(TrKeys.roMembrane)} ${AppHelpers.getTranslation(TrKeys.replacement)}';
    }

    final maintenanceText = activeItem!.maintenanceType == 'maintenance'
        ? TrKeys.maintenance
        : TrKeys.replacement;
    return '${AppConstants.maintenanceTypes[activeItem!.type]} ${AppHelpers.getTranslation(maintenanceText)}';
  }

  Widget _buildMaintenanceItem(MaintenanceItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              FlutterRemix.alert_line,
              color: AppStyle.doorColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                item.message,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppStyle.black,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyle.brandGreen,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            onPressed: () => _handleMaintenanceAction(item),
            child: Text(
              AppHelpers.getTranslation(TrKeys.confirm),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppStyle.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Dialog(
        backgroundColor: AppStyle.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    if (activeMaintenance != null) {
      return Dialog(
        backgroundColor: AppStyle.white,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getMaintenanceTitle(),
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppStyle.black,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.enableJuvoONE
                      ? AppStyle.blueBonus
                      : AppStyle.brandGreen,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: _handleMaintenanceComplete,
                child: Text(
                  AppHelpers.getTranslation(TrKeys.complete),
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppStyle.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: AppStyle.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.maintenanceAlerts),
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppStyle.black,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    FlutterRemix.close_line,
                    color: AppStyle.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (items.isEmpty)
              Text(
                AppHelpers.getTranslation(TrKeys.noMaintenanceAlerts),
                style: GoogleFonts.inter(
                  color: AppStyle.brandGreen,
                  fontSize: 16,
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) =>
                    _buildMaintenanceItem(items[index]),
              ),
          ],
        ),
      ),
    );
  }
}

