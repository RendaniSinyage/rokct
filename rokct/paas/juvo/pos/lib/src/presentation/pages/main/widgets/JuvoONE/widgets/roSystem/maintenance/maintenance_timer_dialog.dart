import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../theme/theme.dart';
import '../models/data/ro_system_model.dart';
import 'maintenance_service.dart';

class MaintenanceTimerDialog extends StatefulWidget {
  final Vessel vessel;

  const MaintenanceTimerDialog({
    super.key,
    required this.vessel,
  });

  @override
  State<MaintenanceTimerDialog> createState() => _MaintenanceTimerDialogState();
}

class _MaintenanceTimerDialogState extends State<MaintenanceTimerDialog> {
  late Timer _timer;
  late MaintenanceStage _currentStage;
  late DateTime _stageStartTime;
  Duration _remainingTime = Duration.zero;
  bool _timerCompleted = false;

  @override
  void initState() {
    super.initState();
    _currentStage = widget.vessel.currentStage ?? MaintenanceStage.initialCheck;
    _stageStartTime = DateTime.now();
    _startTimer();
    _loadSavedProgress();
  }

  void _startTimer() {
    final duration = MaintenanceService.getMaintenanceDuration(
      widget.vessel.type,
      _currentStage,
    );

    _remainingTime = duration;
    _timerCompleted = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime.inSeconds > 0) {
          _remainingTime = _remainingTime - const Duration(seconds: 1);
        } else if (!_timerCompleted) {
          _timerCompleted = true;
          _timer.cancel();
        }
      });
    });
  }

  String _formatStageName(MaintenanceStage stage) {
    // Convert enum value to string and remove enum type name if present
    final rawName = stage.toString().split('.').last;

    // Split at capital letters, trim spaces, and capitalize first letter of each word
    final words = rawName.split(RegExp('(?=[A-Z])')).map((word) {
      return word.trim().isEmpty ? '' :
      word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).where((word) => word.isNotEmpty).toList();

    // Join with spaces
    return words.join(' ');
  }


  Future<void> _loadSavedProgress() async {
    try {
      final savedProgress = await MaintenanceService.getMaintenanceProgress(widget.vessel.id);

      if (savedProgress != null) {
        setState(() {
          _currentStage = MaintenanceStage.values.firstWhere(
                (s) => s.toString() == savedProgress.currentStage,
          );
          _stageStartTime = savedProgress.stageStartTime;

          // Calculate remaining time for current stage
          final duration = MaintenanceService.getMaintenanceDuration(
            widget.vessel.type,
            _currentStage,
          );
          final elapsedTime = DateTime.now().difference(_stageStartTime);
          _remainingTime = duration - elapsedTime;

          if (_remainingTime.isNegative) {
            _remainingTime = Duration.zero;
            _timerCompleted = true;
          }
        });
      } else {
        // No saved progress, start from beginning
        setState(() {
          _currentStage = MaintenanceStage.initialCheck;
          _stageStartTime = DateTime.now();
        });
      }
      _startTimer();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading saved progress: $e');
      }
      // Start from beginning if there's an error
      setState(() {
        _currentStage = MaintenanceStage.initialCheck;
        _stageStartTime = DateTime.now();
      });
      _startTimer();
    }
  }


  void _moveToNextStage() async {
    final stages = widget.vessel.type == 'megaChar'
        ? [
      MaintenanceStage.initialCheck,
      MaintenanceStage.pressureRelease,
      MaintenanceStage.backwash,
      MaintenanceStage.settling,
      MaintenanceStage.fastWash,
      MaintenanceStage.stabilization,
      MaintenanceStage.returnToFilter,
    ]
        : [
      MaintenanceStage.initialCheck,
      MaintenanceStage.pressureRelease,
      MaintenanceStage.backwash,
      MaintenanceStage.settling,
      MaintenanceStage.brineAndSlowRinse,
      MaintenanceStage.fastRinse,
      MaintenanceStage.brineRefill,
      MaintenanceStage.stabilization,
      MaintenanceStage.returnToService,
    ];

    final currentIndex = stages.indexOf(_currentStage);
    if (currentIndex < stages.length - 1) {
      final nextStage = stages[currentIndex + 1];
      final now = DateTime.now();

      try {
        // Save progress to local storage
        await MaintenanceService.saveMaintenanceProgress(
          vesselId: widget.vessel.id,
          stage: nextStage,
          stageStartTime: now,
        );

        setState(() {
          _currentStage = nextStage;
          _stageStartTime = now;
        });
        _startTimer();
      } catch (e) {
        if (kDebugMode) {
          print('Error saving progress: $e');
        }
        // Continue anyway since this is just local backup
        setState(() {
          _currentStage = nextStage;
          _stageStartTime = now;
        });
        _startTimer();
      }
    } else {
      _timer.cancel();
      // Clear progress before completing
      await MaintenanceService.clearMaintenanceProgress(widget.vessel.id);
      _completeVesselMaintenance();
    }
  }

  void _completeVesselMaintenance() async {
    try {
      await MaintenanceService.clearMaintenanceProgress(widget.vessel.id);

      widget.vessel.lastMaintenanceDate = DateTime.now();
      widget.vessel.currentStage = null;
      widget.vessel.maintenanceStartTime = null;

      final system = await MaintenanceService.getROSystem();
      if (system != null) {
        final updatedVessels = system.vessels.map((v) {
          if (v.id == widget.vessel.id) {
            return widget.vessel;
          }
          return v;
        }).toList();

        await MaintenanceService.saveROSystem(
          ROSystem(
            filters: system.filters,
            vessels: updatedVessels,
            membraneCount: system.membraneCount,
            membraneInstallationDate: system.membraneInstallationDate,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error completing maintenance: $e');
      }
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

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  String _getStageInstructions() {
    return switch (_currentStage) {
      MaintenanceStage.initialCheck => 'Check all connections and ensure system is ready for maintenance.',
      MaintenanceStage.pressureRelease => 'Release pressure from the system carefully.',
      MaintenanceStage.backwash => 'System is in backwash mode. Monitor pressure gauge.',
      MaintenanceStage.settling => 'Allow system to settle. Check for any irregularities.',
      MaintenanceStage.fastWash => 'System is in fast wash mode. Monitor water clarity.',
      MaintenanceStage.stabilization => 'Allow system to stabilize. Check pressure readings.',
      MaintenanceStage.returnToFilter => 'Return system to filtration mode.',
      MaintenanceStage.brineAndSlowRinse => 'System is in brine and slow rinse mode.',
      MaintenanceStage.fastRinse => 'System is in fast rinse mode. Monitor water quality.',
      MaintenanceStage.brineRefill => 'Brine tank is being refilled.',
      MaintenanceStage.returnToService => 'Return system to service mode.'
    };
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppStyle.white,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '${AppConstants.maintenanceTypes[widget.vessel.type]} Maintenance',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: AppStyle.black,
                    ),
                  ),
                ),
                if (_currentStage == MaintenanceStage.initialCheck)
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Remix.close_line,
                      color: AppStyle.black,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              _formatStageName(_currentStage),
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: AppStyle.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_remainingTime.inMinutes}:${(_remainingTime.inSeconds % 60).toString().padLeft(2, '0')}',
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w600,
                color: _timerCompleted ? AppStyle.brandGreen : AppStyle.black,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppStyle.grey[500]?.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppStyle.grey[500] ?? AppStyle.grey),
              ),
              child: Text(
                _getStageInstructions(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppStyle.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _timerCompleted ? _moveToNextStage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.enableJuvoONE
                    ? AppStyle.blueBonus
                    : AppStyle.brandGreen,
                minimumSize: const Size.fromHeight(50),
                disabledBackgroundColor: AppStyle.grey[500],
              ),
              child: Text(
                'Confirm and Continue',
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
}
