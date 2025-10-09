import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../theme/app_style.dart';
import '../repository/tanks_api.dart';
import 'flashing_alertIcon.dart';
import 'water_surface_painter.dart';

class WaterTank extends StatefulWidget {
  final double level;
  final double capacity;
  final String type;
  final double width;
  final List<int> tankNumbers;
  final int selectedTank;
  final void Function(int) onTankSelected;
  final int? tankId;
  final VoidCallback? onStatusChanged;

  const WaterTank({
    super.key,
    required this.level,
    required this.capacity,
    required this.type,
    this.width = 300,
    required this.tankNumbers,
    required this.selectedTank,
    required this.onTankSelected,
    this.tankId,
    this.onStatusChanged,
  });

  @override
  State<WaterTank> createState() => _WaterTankState();
}

class _WaterTankState extends State<WaterTank> with TickerProviderStateMixin {
  late AnimationController _tiltController;
  late AnimationController _bounceController;
  late Animation<double> _tiltAnimation;
  late Animation<double> _bounceAnimation;
  bool _isUpdating = false;
  bool _hasInitialized = false;

  Future<void> _handleStatusUpdate() async {
    if (_isUpdating || widget.tankId == null) return;

    try {
      setState(() => _isUpdating = true);

      final percentage = ((widget.level / widget.capacity) * 100).round();

      if (kDebugMode) {
        print('Handling status update');
        print('Tank ID: ${widget.tankId}');
        print('Current percentage: $percentage');
      }

      // Calculate new status
      final TankStatus newStatus;
      if (percentage <= 5) {
        newStatus = TankStatus.empty;
      } else if (percentage <= 25) {
        newStatus = TankStatus.quarterEmpty;
      } else if (percentage <= 50) {
        newStatus = TankStatus.halfEmpty;
      } else {
        newStatus = TankStatus.full;
      }

      if (kDebugMode) {
        print('Updating to status: $newStatus');
      }

      // Call API to update status
      await TankApiService.updateTankStatus(widget.tankId!, newStatus);

      // Notify parent of change
      if (widget.onStatusChanged != null) {
        widget.onStatusChanged!();
      }

    } catch (e) {
      if (kDebugMode) {
        print('Error in _handleStatusUpdate: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update tank status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _initializeSelection() {
    if (!_hasInitialized && widget.tankNumbers.length == 1 && widget.selectedTank == -1) {
      widget.onTankSelected(0);
      _hasInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _tiltController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _tiltAnimation = CurvedAnimation(
      parent: _tiltController,
      curve: Curves.easeInOut,
    );

    _bounceController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: -0.005, end: 0.005).animate(
      CurvedAnimation(
        parent: _bounceController,
        curve: Curves.easeInOut,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeSelection());
  }

  @override
  void dispose() {
    _tiltController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  String _getStatusText(int percentage) {
    if (widget.type == 'raw') {
      if (percentage <= 5) return 'Empty';
      if (percentage <= 25) return '25%';
      if (percentage <= 50) return '50%';
      return 'Full';
    } else {
      if (percentage <= 5) return 'Empty';
      if (percentage <= 25) return '25%';
      if (percentage <= 50) return '50%';
      return 'Full';
    }
  }

  Color _getStatusColor(int percentage) {
    if (percentage <= 5) return Colors.red.withOpacity(0.8);
    if (percentage <= 25) return Colors.orange.withOpacity(0.8);
    if (percentage <= 50) return Colors.yellow.withOpacity(0.8);
    return Colors.blue.withOpacity(0.8);
  }

  @override
  Widget build(BuildContext context) {
    final percentage = ((widget.level / widget.capacity) * 100).round();
    final baseWaterColor = widget.type == 'raw' ? AppStyle.green : AppStyle.blue[500]!;
    final backgroundColor = AppStyle.grey[700];

    final height = (widget.width * 3) / 4;
    final standWidth = (widget.width * 3) / 4;
    final standHeight = height / 6;

    return SizedBox(
      width: widget.width,
      height: height + standHeight,
      child: Stack(
        children: [
          // Stand
          Positioned(
            bottom: 0,
            left: (widget.width - standWidth) / 2,
            child: Container(
              width: standWidth,
              height: standHeight,
              decoration: BoxDecoration(
                color: AppStyle.grey[600],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
            ),
          ),
          // Tank
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height,
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Water animation
                    AnimatedBuilder(
                      animation: Listenable.merge([_tiltAnimation, _bounceAnimation]),
                      builder: (context, child) {
                        return Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          height: height * (widget.level / widget.capacity + _bounceAnimation.value),
                          child: CustomPaint(
                            painter: WaterSurfacePainter(
                              tiltFactor: _tiltAnimation.value,
                              baseColor: baseWaterColor,
                              level: widget.level / widget.capacity + _bounceAnimation.value,
                              percentage: percentage,
                            ),
                            size: Size.infinite,
                          ),
                        );
                      },
                    ),

                    // Content overlay
                    _buildTankContent(height, percentage),

                    // Tank selector
                    if (widget.tankNumbers.isNotEmpty)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: _buildTankSelector(),
                      ),

                    // Status button
                    if (widget.tankId != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: _buildStatusButton(percentage),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTankContent(double height, int percentage) {
    return Stack(
      children: [
        // Percentage text
        Center(
          child: Text(
            '$percentage%',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // Capacity text
        Positioned(
          bottom: 8,
          left: 0,
          right: 0,
          child: Text(
            '${widget.level.round()}/${widget.capacity.round()}L',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),

        // Alert icon
        if (percentage == 0)
          const Positioned(
            top: 8,
            right: 8,
            child: FlashingAlertIcon(),
          ),
      ],
    );
  }

  Widget _buildTankSelector() {
    return Row(
      children: [
        if (widget.tankNumbers.length > 1)
          GestureDetector(
            onTap: () => widget.onTankSelected(-1),
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: widget.selectedTank == -1 ? AppStyle.blue : AppStyle.grey[600],
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'All',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ...widget.tankNumbers.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              onTap: () => widget.onTankSelected(entry.key),
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: widget.selectedTank == entry.key ? AppStyle.blue : AppStyle.grey[600],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatusButton(int percentage) {
    return GestureDetector(
      onTap: _isUpdating ? null : _handleStatusUpdate,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: _isUpdating ? Colors.grey.withOpacity(0.8) : _getStatusColor(percentage),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isUpdating)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              Icon(
                percentage <= 5 ? Icons.water_drop_outlined : Icons.water_drop,
                color: Colors.white,
                size: 16,
              ),
            const SizedBox(width: 4),
            Text(
              _getStatusText(percentage),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
