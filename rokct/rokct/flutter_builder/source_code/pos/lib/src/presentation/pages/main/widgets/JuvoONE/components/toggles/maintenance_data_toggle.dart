import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../../theme/theme.dart';
import '../../widgets/roSystem/models/data/ro_system_model.dart';
import '../../widgets/roSystem/repository/ro_system_api.dart';

// Provider to trigger UI updates after reset
final maintenanceResetProvider = StateProvider<bool>((ref) => false);

class MaintenanceDataToggle extends ConsumerWidget {
  const MaintenanceDataToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppStyle.red,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      onPressed: () => _showResetConfirmation(context, ref),
      child: Text(
        'Reset Maintenance Data',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppStyle.white,
        ),
      ),
    );
  }

  Future<void> _showResetConfirmation(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reset Maintenance Data?',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppStyle.black,
          ),
        ),
        content: Text(
          'This will clear all maintenance settings and history. You will need to set up the system again. Are you sure?',
          style: GoogleFonts.inter(color: AppStyle.black),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(
                color: AppStyle.black,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyle.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Reset Data',
              style: GoogleFonts.inter(
                color: AppStyle.white,
              ),
            ),
          ),
        ],
        backgroundColor: AppStyle.white,
      ),
    );

    if (confirm == true) {
      try {
        // Create an empty RO system to effectively reset the data
        await MaintenanceApiService.saveROSystem(
          ROSystem(
            filters: [],
            vessels: [],
            membraneCount: 0,
            membraneInstallationDate: DateTime.now(),
          ),
        );

        // Notify the UI that data has been reset
        ref.read(maintenanceResetProvider.notifier).state = !ref.read(maintenanceResetProvider);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Maintenance data has been reset',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: AppStyle.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error resetting maintenance data: $e',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: AppStyle.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }
}
