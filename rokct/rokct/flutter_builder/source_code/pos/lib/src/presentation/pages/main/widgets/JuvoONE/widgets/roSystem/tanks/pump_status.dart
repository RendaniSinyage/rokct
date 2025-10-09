import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';
import '../../../../../../../theme/app_style.dart';
import '../models/data/tank_models.dart';
import '../repository/tanks_api.dart';
import 'pump_runtime_manager.dart';

class PumpStatus extends StatefulWidget {
  final bool isOn;
  final double flowRate;
  final int? tankId;
  final VoidCallback? onStatusChanged;
  final double currentLevel;
  final double capacity;
  final List<Tank> tanks;
  final double Function(Tank) calculateWaterLevel;  // Add this line

  const PumpStatus({
    super.key,
    required this.isOn,
    required this.flowRate,
    required this.currentLevel,
    required this.capacity,
    required this.tanks,
    required this.calculateWaterLevel,  // Add this line
    this.tankId,
    this.onStatusChanged,
  });

  @override
  State<PumpStatus> createState() => _PumpStatusState();
}

class _PumpStatusState extends State<PumpStatus> {
  late PumpRuntimeManager _pumpManager;

  @override
  void initState() {
    super.initState();
    _pumpManager = PumpRuntimeManager(
      onWaterLevelUpdate: () {
        widget.onStatusChanged?.call();
      },
      tanks: widget.tanks,
      calculateWaterLevel: widget.calculateWaterLevel,  // Add this line
    );
  }

  @override
  void dispose() {
    _pumpManager.dispose();
    super.dispose();
  }

  Future<void> _togglePump() async {
    if (widget.tankId == null) return;

    try {
      final newStatus = !widget.isOn;
      if (kDebugMode) {
        print('Toggling pump for tank ${widget.tankId} from ${widget.isOn} to $newStatus');
      }

      if (newStatus) {
        // When turning on, update both status and flow rate
        await TankApiService.updatePumpStatus(widget.tankId!, true, widget.flowRate);
        await _pumpManager.startPump(widget.tankId!, widget.flowRate, widget.currentLevel);
      } else {
        // When turning off, only update status
        await TankApiService.updatePumpOnlyStatus(widget.tankId!, false);
        await _pumpManager.stopPump(widget.tankId!);
      }

      // Add immediate refresh after toggle
      if (mounted) {
        // Short delay to allow API to process
        await Future.delayed(const Duration(milliseconds: 100));
        // Call status changed callback to trigger refresh
        widget.onStatusChanged?.call();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling pump: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate display flow rate - show 0 if pump is off, but maintain actual rate in state
    final displayFlowRate = widget.isOn ? widget.flowRate : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppStyle.black.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pump Status',
                style: TextStyle(
                  color: AppStyle.grey[600],
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                widget.isOn ? 'ON' : 'OFF',
                style: TextStyle(
                  color: widget.isOn ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Remix.pulse_fill, color: AppStyle.blue[400]),
                  Text(
                    '${displayFlowRate.toStringAsFixed(1)} L/min',
                    style: TextStyle(
                      color: AppStyle.grey[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (widget.tankId != null)
            IconButton(
              onPressed: _togglePump,
              icon: Icon(
                widget.isOn ? Icons.power_settings_new : Icons.power_settings_new_outlined,
                color: widget.isOn ? Colors.green : Colors.red,
              ),
            ),
        ],
      ),
    );
  }
}
