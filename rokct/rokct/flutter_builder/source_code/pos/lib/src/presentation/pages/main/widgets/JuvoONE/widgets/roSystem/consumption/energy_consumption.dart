import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import '../../../../../../../theme/app_style.dart';

class EnergyConsumption extends StatelessWidget {
  final double dailyAverage;
  final double thisMonth;
  final double lastMonth;

  const EnergyConsumption({
    super.key,
    this.dailyAverage = 0.0,
    this.thisMonth = 0.0,
    this.lastMonth = 0.0,
  });

  Widget _buildEnergyItem(BuildContext context, String label, double value) {
    return Row(
      children: [
        const Icon(
          Remix.flashlight_line,
          size: 24,
          color: AppStyle.starColor,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ${value.toStringAsFixed(2)} kWh',
          style: const TextStyle(fontSize: 14, color: AppStyle.black),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
      Text(
      'Energy Consumption',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppStyle.grey[800],
      ),
    ),
    const SizedBox(height: 8),
    _buildEnergyItem(context, 'Daily Average', dailyAverage),
    const SizedBox(height: 8),
    _buildEnergyItem(context, 'This Month', thisMonth),
    const SizedBox(height: 8),
    _buildEnergyItem(context, 'Last Month', lastMonth),
    ]);
    }
}
