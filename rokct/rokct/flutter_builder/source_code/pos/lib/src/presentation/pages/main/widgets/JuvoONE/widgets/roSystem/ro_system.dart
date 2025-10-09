import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../../../../../../../../app_constants.dart';
import '../../../../../../../core/constants/enums.dart';
import '../../../../../../theme/app_style.dart';
import 'maintenance/maintenance_service.dart';


class ROSystemUI extends StatelessWidget {
  final String status;
  final double efficiency;
  final bool isSetup;
  final VoidCallback onSetupTap;

  const ROSystemUI({
    super.key,
    required this.status,
    required this.efficiency,
    required this.isSetup,
    required this.onSetupTap,
  });

  // This is now just a convenient way to check the setup state
  // The actual check is done in DashboardPage's _checkRequiredComponents
  bool get isFullySetup => isSetup;

  // Check if status indicates system is active
  bool get isSystemActive => status == 'Running';

  @override
  Widget build(BuildContext context) {
    // If the system is not fully set up, show setup UI
    if (!isFullySetup) {
      return _buildSetupPrompt();
    }

    // If the system is set up, show status UI
    return _buildSystemStatus();
  }

  Widget _buildSetupPrompt() {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Text(
            'RO System Not Setup',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppStyle.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onSetupTap,
            icon: const Icon(Remix.settings_2_line, size: 20),
            label: const Text('Setup System'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyle.brandGreen,
              foregroundColor: AppStyle.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatus() {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RO System Status',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppStyle.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          _buildStatusRows(),
          const SizedBox(height: 8),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildStatusRows() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Status indicator
        Row(
          children: [
            Icon(
              Remix.drop_line,
              size: 20,
              color: isSystemActive ? AppStyle.blue[500] : AppStyle.grey[400],
            ),
            const SizedBox(width: 8),
            Text(
              status,
              style: TextStyle(
                fontSize: 14,
                color: AppStyle.grey[800],
              ),
            ),
          ],
        ),
        // Efficiency indicator
        Row(
          children: [
            Icon(
              _getEfficiencyIcon(),
              size: 20,
              color: _getEfficiencyColor(efficiency),
            ),
            const SizedBox(width: 8),
            Text(
              '${efficiency.toStringAsFixed(1)}% Eff.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: _getEfficiencyColor(efficiency),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    return LinearProgressIndicator(
      value: efficiency / 100,
      backgroundColor: AppStyle.grey[200],
      valueColor: AlwaysStoppedAnimation<Color>(_getEfficiencyColor(efficiency)),
      borderRadius: BorderRadius.circular(2),
    );
  }

  IconData _getEfficiencyIcon() {
    if (efficiency >= 90) return Remix.heart_fill;
    if (efficiency >= 70) return Remix.heart_3_fill;
    if (efficiency >= 50) return Remix.heart_2_fill;
    return Remix.heart_line;
  }

  Color _getEfficiencyColor(double efficiency) {
    if (efficiency >= 90) return AppStyle.green;
    if (efficiency >= 70) return AppStyle.blue;
    if (efficiency >= 50) return Colors.orange;
    return AppStyle.red;
  }
}

// Utility class for calculating RO System efficiency
class ROSystemEfficiency {
  static const int maintenanceEffectDays = 30; // Maintenance effect lasts 30 days
  static const int replacementLifespanDays = 365; // Items should be replaced yearly
  static const double maintenanceBoost = 20.0; // Maintenance can boost efficiency by 20%

  static Future<double> calculateSystemEfficiency() async {
    final system = await MaintenanceService.getROSystem();
    if (system == null) return 0.0;

    double totalEfficiency = 0.0;
    int componentCount = 0;

    // Calculate vessel efficiencies
    for (var vessel in system.vessels) {
      totalEfficiency += _calculateComponentEfficiency(
        installationDate: vessel.installationDate,
        lastMaintenanceDate: vessel.lastMaintenanceDate,
      );
      componentCount++;
    }

    // Calculate filter efficiencies
    for (var filter in system.filters) {
      totalEfficiency += _calculateComponentEfficiency(
        installationDate: filter.installationDate,
        replacementLifespan: getFilterLifespan(filter.location),
      );
      componentCount++;
    }

    // Calculate membrane efficiency
    if (system.membraneCount > 0) {
      totalEfficiency += _calculateComponentEfficiency(
        installationDate: system.membraneInstallationDate,
        replacementLifespan: 730, // Membranes typically last 2 years
      );
      componentCount++;
    }

    return componentCount > 0 ? (totalEfficiency / componentCount) : 0.0;
  }

  static int getFilterLifespan(FilterLocation location) {
    switch (location) {
      case FilterLocation.pre:
        return 90; // 3 months
      case FilterLocation.ro:
        return 180; // 6 months
      case FilterLocation.post:
        return 90; // 3 months
    }
  }
// Add this static method to ROSystemEfficiency class if it's not already there
  static double calculateComponentEfficiency({
    required DateTime installationDate,
    DateTime? lastMaintenanceDate,
    int? replacementLifespan,
  }) {
    final now = DateTime.now();
    final daysSinceInstallation = now.difference(installationDate).inDays;

    if (replacementLifespan != null) {
      // For components that need replacement (filters, membranes)
      return 100.0 * (1 - (daysSinceInstallation / replacementLifespan)).clamp(0.0, 1.0);
    } else {
      // For components that need maintenance (vessels)
      final daysSinceLastMaintenance = lastMaintenanceDate != null
          ? now.difference(lastMaintenanceDate).inDays
          : daysSinceInstallation;

      // Efficiency drops after maintenance interval
      return 100.0 *
          (1 - (daysSinceLastMaintenance / AppConstants.maintenanceCheckDays)).clamp(0.0, 1.0);
    }
  }

  // Add this method to ROSystemEfficiency class
  static Future<double> calculateSystemEfficiencyForShopData(Map<String, dynamic> roSystemData) async {
    try {
      // Extract vessel data
      List<dynamic> vessels = roSystemData['vessels'] ?? [];
      List<dynamic> filters = roSystemData['filters'] ?? [];
      int membraneCount = roSystemData['membrane_count'] ?? 0;
      String? membraneInstallationDateStr = roSystemData['membrane_installation_date'];

      DateTime? membraneInstallationDate = membraneInstallationDateStr != null
          ? DateTime.parse(membraneInstallationDateStr)
          : null;

      // Calculate vessel efficiencies
      double vesselEfficiency = 0.0;
      if (vessels.isNotEmpty) {
        double totalVesselEfficiency = 0.0;
        for (var vessel in vessels) {
          String? installDateStr = vessel['installation_date'];
          String? lastMaintenanceDateStr = vessel['last_maintenance_date'];

          DateTime installDate = installDateStr != null
              ? DateTime.parse(installDateStr)
              : DateTime.now();

          DateTime? lastMaintenanceDate = lastMaintenanceDateStr != null
              ? DateTime.parse(lastMaintenanceDateStr)
              : null;

          totalVesselEfficiency += calculateComponentEfficiency(
            installationDate: installDate,
            lastMaintenanceDate: lastMaintenanceDate,
          );
        }
        vesselEfficiency = totalVesselEfficiency / vessels.length;
      }

      // Calculate filter efficiencies
      double filterEfficiency = 0.0;
      if (filters.isNotEmpty) {
        double totalFilterEfficiency = 0.0;
        for (var filter in filters) {
          String? installDateStr = filter['installation_date'];
          String? locationStr = filter['location'];

          DateTime installDate = installDateStr != null
              ? DateTime.parse(installDateStr)
              : DateTime.now();

          FilterLocation location = FilterLocation.pre;
          if (locationStr == 'ro') location = FilterLocation.ro;
          else if (locationStr == 'post') location = FilterLocation.post;

          totalFilterEfficiency += calculateComponentEfficiency(
            installationDate: installDate,
            replacementLifespan: getFilterLifespan(location),
          );
        }
        filterEfficiency = totalFilterEfficiency / filters.length;
      }

      // Calculate membrane efficiency
      double membraneEfficiency = 0.0;
      if (membraneCount > 0 && membraneInstallationDate != null) {
        membraneEfficiency = calculateComponentEfficiency(
          installationDate: membraneInstallationDate,
          replacementLifespan: AppConstants.roMembraneReplaceDays,
        );
      }

      // Calculate overall efficiency
      double totalEfficiency = 0.0;
      int components = 0;

      if (vessels.isNotEmpty) {
        totalEfficiency += vesselEfficiency * 0.4; // 40% weight
        components++;
      }

      if (filters.isNotEmpty) {
        totalEfficiency += filterEfficiency * 0.3; // 30% weight
        components++;
      }

      if (membraneCount > 0) {
        totalEfficiency += membraneEfficiency * 0.3; // 30% weight
        components++;
      }

      return components > 0 ? totalEfficiency / components : 0.0;
    } catch (e) {
      // Add proper error handling here
      print('Error calculating system efficiency: $e');
      return 0.0; // Return default value on error
    }
  }

    static double _calculateComponentEfficiency({
      required DateTime installationDate,
      DateTime? lastMaintenanceDate,
      int? replacementLifespan,
    }) {
      final now = DateTime.now();
      final daysSinceInstallation = now
          .difference(installationDate)
          .inDays;

      // Base efficiency based on age
      double baseEfficiency = 100.0;
      if (replacementLifespan != null) {
        baseEfficiency = 100.0 *
            (1 - (daysSinceInstallation / replacementLifespan)).clamp(0.0, 1.0);
      }

      // Maintenance boost if applicable
      if (lastMaintenanceDate != null) {
        final daysSinceMaintenance = now
            .difference(lastMaintenanceDate)
            .inDays;
        if (daysSinceMaintenance <= maintenanceEffectDays) {
          final maintenanceMultiplier = 1 + (maintenanceBoost / 100) *
              (1 - daysSinceMaintenance / maintenanceEffectDays);
          baseEfficiency =
              (baseEfficiency * maintenanceMultiplier).clamp(0.0, 100.0);
        }
      }

      return baseEfficiency;
    }

    /*static double calculateComponentEfficiency({
      required DateTime installationDate,
      DateTime? lastMaintenanceDate,
      int? replacementLifespan,
    }) {
      return _calculateComponentEfficiency(
        installationDate: installationDate,
        lastMaintenanceDate: lastMaintenanceDate,
        replacementLifespan: replacementLifespan,
      );
    }*/
  }
