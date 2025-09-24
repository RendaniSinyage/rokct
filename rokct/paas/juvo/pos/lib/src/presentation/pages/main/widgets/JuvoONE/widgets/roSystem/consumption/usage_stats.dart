import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_desktop/src/models/data/order_data.dart';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:remixicon/remixicon.dart';
import 'package:admin_desktop/src/presentation/theme/app_style.dart';

import '../../../riverpod/provider/wateros_orders_provider.dart';

class UsageStats extends ConsumerWidget {
  final Function(Map<String, int>) onStatsCalculated;
  final int? shopId;

  const UsageStats({super.key, required this.onStatsCalculated, this.shopId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waterosOrdersAsync = ref.watch(waterosOrdersProvider);

    // Handle loading state
    if (waterosOrdersAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Handle error state
    if (waterosOrdersAsync.hasError) {
      if (kDebugMode) {
        print("Error loading orders: ${waterosOrdersAsync.error}");
      }
      return const Center(child: Text("Error loading usage data", style: TextStyle(color: Colors.red)));
    }

    // Ensure we have data
    if (!waterosOrdersAsync.hasValue || waterosOrdersAsync.value == null) {
      return const Center(child: Text("No usage data available"));
    }

    final waterosOrders = waterosOrdersAsync.value!;
    final usageStats = calculateUsageStats(waterosOrders);

    // Call the callback function with the calculated stats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onStatsCalculated(usageStats);
    });

    if (kDebugMode) {
      print("UsageStats rebuilt with ${waterosOrders.length} orders");
    }

    return Container();
  }

  Widget _buildUsageItem(BuildContext context, String label, int value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Remix.drop_line,
            size: 20,
            color: AppStyle.blue[500],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value L',
              style: const TextStyle(
                fontSize: 14,
                color: AppStyle.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, int> calculateUsageStats(List<OrderData> orders) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final endOfLastMonth = startOfMonth.subtract(const Duration(days: 1));

    // Debugging: Print date ranges
    if (kDebugMode) {
      print('Last Month Range: $startOfLastMonth to $endOfLastMonth');
    }

    return {
      'today': calculateUsage(orders, today, now),
      'week': calculateUsage(orders, startOfWeek, now),
      'month': calculateUsage(orders, startOfMonth, now),
      'lastMonth': calculateUsage(orders, startOfLastMonth, endOfLastMonth),
    };
  }

  int calculateUsage(List<OrderData> orders, DateTime start, DateTime end) {
    if (kDebugMode) {
      print('Calculating usage from ${start.toIso8601String()} to ${end.toIso8601String()}');
      print('Using date field: ${AppConstants.dateAt}');
    }

    final relevantOrders = orders.where((order) {
      final orderDate = order.toJson()[AppConstants.dateAt] as DateTime?;
      return orderDate != null &&
          orderDate.isAfter(start) &&
          orderDate.isBefore(end);
    }).toList();

    if (kDebugMode) {
      print('Found ${relevantOrders.length} orders in date range');
    }

    int totalUsage = 0;
    for (var order in relevantOrders) {
      final orderUsage = calculateOrderUsage(order);
      if (kDebugMode) {
        print('Order ${order.id} usage: $orderUsage L');
      }
      totalUsage += orderUsage;
    }

    if (kDebugMode) {
      print('Total usage: $totalUsage L');
    }

    return totalUsage;
  }

  int calculateOrderUsage(OrderData order) {
    int usage = 0;
    for (var detail in order.details ?? []) {
      final stockId = detail.stockId.toString();
      final litres = AppConstants.stockIds[stockId];
      if (litres != null) {
        usage += (litres * (detail.quantity ?? 0)).round();
      }
    }

    if (kDebugMode) {
      print('Order ${order.id} usage: $usage L');
    }

    return usage;
  }
}
