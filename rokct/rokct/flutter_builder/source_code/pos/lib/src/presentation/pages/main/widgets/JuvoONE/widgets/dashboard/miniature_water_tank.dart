import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../theme/app_style.dart';
import '../roSystem/tanks/water_surface_painter.dart';

/// A miniature version of WaterTank designed for the dashboard grid
/// This is a simplified version that keeps the same visual style but is optimized for cards
class MiniatureWaterTank extends StatefulWidget {
  final double level;
  final double capacity;
  final String type;
  final double width;

  const MiniatureWaterTank({
    super.key,
    required this.level,
    required this.capacity,
    required this.type,
    this.width = 140,
  });

  @override
  State<MiniatureWaterTank> createState() => _MiniatureWaterTankState();
}

class _MiniatureWaterTankState extends State<MiniatureWaterTank> with TickerProviderStateMixin {
  late AnimationController _tiltController;
  late AnimationController _bounceController;
  late Animation<double> _tiltAnimation;
  late Animation<double> _bounceAnimation;

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
  }

  @override
  void dispose() {
    _tiltController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = ((widget.level / widget.capacity) * 100).round();
    final baseWaterColor = widget.type == 'raw' ? AppStyle.green : AppStyle.blue[500]!;
    final backgroundColor = AppStyle.grey[700];

    // Updated proportions - taller tank with less whitespace
    final height = (widget.width * 4) / 5; // Slightly taller proportion
    final standWidth = (widget.width * 2) / 3; // Narrower stand
    final standHeight = height / 8; // Shorter stand

    return SizedBox(
      width: widget.width,
      height: height + standHeight, // Include stand in total height
      child: Stack(
        alignment: Alignment.bottomCenter, // Align everything to bottom center
        children: [
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
                    // Water animation - keep this the same
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
                  ],
                ),
              ),
            ),
          ),

          // Stand - positioned at the bottom center
          Positioned(
            bottom: 0,
            // This centers the stand properly
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
            style: TextStyle(
              fontSize: 24.sp, // Smaller size for better fit
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),

        // Capacity text
        Positioned(
          bottom: 4, // Closer to bottom
          left: 0,
          right: 0,
          child: Text(
            '${widget.level.round()}/${widget.capacity.round()}L',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp, // Smaller font
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  String _getStatusText(int percentage) {
    if (percentage <= 5) return 'Empty';
    if (percentage <= 25) return '25%';
    if (percentage <= 50) return '50%';
    return 'Full';
  }
}
