import 'package:flutter/material.dart';

class WaterQuality extends StatelessWidget {
  final double ph;
  final int tds;
  final double temperature;
  final int hardness;

  const WaterQuality({
    Key? key,
    required this.ph,
    required this.tds,
    required this.temperature,
    required this.hardness,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[700] : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Water Quality',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 2.5,
            children: [
              _buildQualityItem(context, 'pH', '$ph'),
              _buildQualityItem(context, 'TDS', '$tds ppm'),
              _buildQualityItem(context, 'Temp', '$temperature°C'),
              _buildQualityItem(context, 'Hardness', '$hardness mg/L'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQualityItem(BuildContext context, String label, String value) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.grey[200] : Colors.grey[800],
          ),
        ),
      ],
    );
  }
}
