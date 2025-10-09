import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../../theme/theme.dart';
import './miniature_water_tank.dart';
import 'shop_dashboard_grid.dart';

class ShopDashboardCard extends StatelessWidget {
  final ShopDashboardSummary shop;
  final VoidCallback onTap;

  const ShopDashboardCard({
    super.key,
    required this.shop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 12.r), // Reduced padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shop header with logo and name
              Row(
                children: [
                  shop.name.isNotEmpty
                      ? Text(
                      shop.name,
                      style: TextStyle(
                        fontSize: 15.sp, // Slightly smaller
                        fontWeight: FontWeight.bold,
                        color: AppStyle.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                      : Icon(
                    Icons.store,
                    size: 28.r,
                    color: AppStyle.grey[600],
                  ),
                  SizedBox(width: 8.w), // Smaller spacing
                  Expanded(
                    child: Text(
                      shop.name,
                      style: TextStyle(
                        fontSize: 15.sp, // Slightly smaller
                        fontWeight: FontWeight.bold,
                        color: AppStyle.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // Label row for tanks - integrated in layout to save space
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Raw',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp, // Smaller font
                        fontWeight: FontWeight.w500,
                        color: AppStyle.black,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Purified',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp, // Smaller font
                        fontWeight: FontWeight.w500,
                        color: AppStyle.black,
                      ),
                    ),
                  ),
                ],
              ),

              // Tanks visualization section
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: MiniatureWaterTank(
                        level: _getRawTankLevel(),
                        capacity: _getRawTankCapacity(),
                        type: 'raw',
                        width: 120.w,
                      ),
                    ),
                    SizedBox(width: 6.w), // Smaller spacing
                    Expanded(
                      child: MiniatureWaterTank(
                        level: _getPurifiedTankLevel(),
                        capacity: _getPurifiedTankCapacity(),
                        type: 'purified',
                        width: 120.w,
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom metrics - more compact layout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // System efficiency indicator
                  Row(
                    children: [
                      Icon(
                        Icons.health_and_safety_outlined,
                        size: 14.r, // Smaller icon
                        color: AppStyle.grey[600],
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        shop.systemEfficiency != null
                            ? '${shop.systemEfficiency!.toStringAsFixed(1)}%'
                            : '-',
                        style: TextStyle(
                          fontSize: 13.sp, // Smaller font
                          fontWeight: FontWeight.bold,
                          color: _getEfficiencyColor(shop.systemEfficiency),
                        ),
                      ),
                    ],
                  ),

                  // Usage indicator
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop_outlined,
                        size: 14.r, // Smaller icon
                        color: AppStyle.grey[600],
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        shop.usageThisMonth != null
                            ? '${shop.usageThisMonth!.toStringAsFixed(0)}L'
                            : '-',
                        style: TextStyle(
                          fontSize: 13.sp, // Smaller font
                          fontWeight: FontWeight.bold,
                          color: AppStyle.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Utility methods to get tank information
  double _getRawTankLevel() {
    if (shop.tankStatuses == null || !shop.tankStatuses!.containsKey('raw')) {
      return 0.0;
    }

    final tankInfo = shop.tankStatuses!['raw'];
    if (tankInfo == null || tankInfo['tank_count'] == 0) {
      return 0.0;
    }

    final tanks = tankInfo['tanks'];
    if (tanks is! List || tanks.isEmpty) {
      return 0.0;
    }

    double totalCapacity = 0.0;
    double totalLevel = 0.0;

    for (final tank in tanks) {
      final capacity = double.parse(tank['capacity'].toString());
      totalCapacity += capacity;

      // Calculate level based on status
      switch (tank['status']) {
        case 'full':
          totalLevel += capacity;
          break;
        case 'empty':
        // Level is 0
          break;
        case 'halfEmpty':
          totalLevel += capacity * 0.5;
          break;
        case 'quarterEmpty':
          totalLevel += capacity * 0.75;
          break;
      }
    }

    return totalLevel;
  }

  double _getRawTankCapacity() {
    if (shop.tankStatuses == null || !shop.tankStatuses!.containsKey('raw')) {
      return 100.0; // Default capacity
    }

    final tankInfo = shop.tankStatuses!['raw'];
    if (tankInfo == null || tankInfo['tank_count'] == 0) {
      return 100.0;
    }

    final tanks = tankInfo['tanks'];
    if (tanks is! List || tanks.isEmpty) {
      return 100.0;
    }

    double totalCapacity = 0.0;
    for (final tank in tanks) {
      totalCapacity += double.parse(tank['capacity'].toString());
    }

    return totalCapacity > 0 ? totalCapacity : 100.0;
  }

  double _getPurifiedTankLevel() {
    if (shop.tankStatuses == null || !shop.tankStatuses!.containsKey('purified')) {
      return 0.0;
    }

    final tankInfo = shop.tankStatuses!['purified'];
    if (tankInfo == null || tankInfo['tank_count'] == 0) {
      return 0.0;
    }

    final tanks = tankInfo['tanks'];
    if (tanks is! Map || tanks.isEmpty) {
      return 0.0;
    }

    double totalRemaining = 0.0;
    tanks.forEach((key, tank) {
      if (tank['remaining_capacity'] != null) {
        totalRemaining += double.parse(tank['remaining_capacity'].toString());
      }
    });

    return totalRemaining;
  }

  double _getPurifiedTankCapacity() {
    if (shop.tankStatuses == null || !shop.tankStatuses!.containsKey('purified')) {
      return 100.0; // Default capacity
    }

    final tankInfo = shop.tankStatuses!['purified'];
    if (tankInfo == null || tankInfo['tank_count'] == 0) {
      return 100.0;
    }

    final tanks = tankInfo['tanks'];
    if (tanks is! Map || tanks.isEmpty) {
      return 100.0;
    }

    double totalCapacity = 0.0;
    tanks.forEach((key, tank) {
      if (tank['total_capacity'] != null) {
        totalCapacity += double.parse(tank['total_capacity'].toString());
      }
    });

    return totalCapacity > 0 ? totalCapacity : 100.0;
  }

  Color _getEfficiencyColor(double? efficiency) {
    if (efficiency == null) return AppStyle.black;
    if (efficiency >= 90) return AppStyle.green;
    if (efficiency >= 70) return AppStyle.blue;
    if (efficiency >= 50) return Colors.orange;
    return AppStyle.red;
  }
}
