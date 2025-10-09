import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../../../theme/app_style.dart';

class EnvironmentalImpact extends StatelessWidget {
  final int totalUsage; // Total water usage in liters

  const EnvironmentalImpact({
    super.key,
    required this.totalUsage,
  });

  double get plasticSaved => calculatePlasticSaved(totalUsage);
  double get co2Reduced => calculateCO2Reduced(totalUsage);

  // Calculate the amount of plastic saved in kilograms
  double calculatePlasticSaved(int usage) {
    int bottlesSaved = (usage / 5).floor(); // Assuming 5L per bottle
    double plasticSavedGrams = bottlesSaved * 120; // Assuming 120g of plastic per bottle
    return plasticSavedGrams / 1000; // Convert to kg
  }

  // Calculate the amount of CO2 reduced in kilograms
  double calculateCO2Reduced(int usage) {
    int bottlesAvoided = usage ~/ 5; // Integer division by 5
    double co2ReducedGrams = bottlesAvoided * 82.8; // Assuming 82.8g of CO2 per bottle
    return co2ReducedGrams / 1000; // Convert to kg
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.grey[800],
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppStyle.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Environmental Impact',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppStyle.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildImpactItem(context, 'Plastic Saved', plasticSaved, Remix.recycle_line),
              _buildImpactItem(context, 'CO2 Reduced', co2Reduced, Remix.cloud_line),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactItem(BuildContext context, String label, double value, IconData icon) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 24,
            color: AppStyle.green[500],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppStyle.grey[400],
                  ),
                ),
                Text(
                  '${value.toStringAsFixed(2)} kg',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppStyle.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
