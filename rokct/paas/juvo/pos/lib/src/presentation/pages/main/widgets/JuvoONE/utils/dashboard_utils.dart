import 'dart:math';

import '../../../../../../models/data/shop_data.dart';

// Calculate the efficiency of the RO system
int calculateROSystemEfficiency(Map<String, dynamic>? roSystem, Map<String, dynamic>? maintenance) {
  if (roSystem == null || maintenance == null) {
    return 0;  // Return 0 if either roSystem or maintenance is null
  }

  double membraneEfficiency = (roSystem['membranes'] as List<dynamic>?)
      !.map((membrane) => calculateVesselEfficiency(membrane['lastReplaced'] as String?))
      .fold(0.0, (sum, efficiency) => sum + (efficiency ?? 0)) / (roSystem['membranes']?.length ?? 1);

  double megaCharEfficiency = (roSystem['megaCharVessels'] as List<dynamic>?)
      !.map((vessel) => calculateVesselEfficiency(vessel['lastReplaced'] as String?))
      .fold(0.0, (sum, efficiency) => sum + (efficiency ?? 0)) / (roSystem['megaCharVessels']?.length ?? 1);

  num softenerEfficiency = calculateVesselEfficiency(maintenance['softenerLastReplaced'] as String?) ?? 0.0;

  return ((membraneEfficiency + megaCharEfficiency + softenerEfficiency) / 3).round();
}


// Calculate the efficiency of a single vessel
// Update this function to handle null input
int? calculateVesselEfficiency(String? lastReplaced) {
  if (lastReplaced == null) return null;
  DateTime currentDate = DateTime.now();
  DateTime replacementDate = DateTime.parse(lastReplaced);
  int monthsSinceReplacement = currentDate.difference(replacementDate).inDays ~/ 30;
  return max(0, (100 - (monthsSinceReplacement / 12) * 100).round());
}

// Calculate the amount of plastic saved in kilograms
double calculatePlasticSaved(double lastMonthUsage) {
  int bottlesSaved = (lastMonthUsage / 5).floor();
  double plasticSavedGrams = bottlesSaved * 120;
  return plasticSavedGrams / 1000; // Return as double for more precision
}


// Calculate the amount of CO2 reduced in kilograms
double calculateCO2Reduced(double lastMonthUsage) {
  int bottlesAvoided = (lastMonthUsage * 2).round();
  double co2ReducedGrams = bottlesAvoided * 82.8;
  return co2ReducedGrams / 1000; // Return as double for more precision
}


// Get the shop name from shop data
String getShopName(ShopData? shopData) {
  if (shopData?.translation?.title != null) {
    return shopData!.translation!.title!;
  } else if (shopData?.logoImg != null) {
    return shopData!.logoImg!;
  } else if (shopData?.uuid != null) {
    return shopData!.uuid!.replaceAll(RegExp(r'-'), ' ').split(' ').map((word) => word.capitalize()).join(' ');
  } else {
    return 'Water Refill Station';
  }
}
// Extension method to capitalize first letter of a string
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

// Calculate energy statistics
Map<String, double> calculateEnergyStats(List<Map<String, dynamic>> energyPurchases) {
  if (energyPurchases.isEmpty) {
    return {'dailyAverage': 0, 'thisMonth': 0, 'lastMonth': 0};
  }

  DateTime now = DateTime.now();
  int thisMonth = now.month;
  int thisYear = now.year;
  int lastMonth = thisMonth == 1 ? 12 : thisMonth - 1;
  int lastMonthYear = thisMonth == 1 ? thisYear - 1 : thisYear;

  var thisMonthPurchases = energyPurchases.where((purchase) {
    DateTime purchaseDate = DateTime.parse(purchase['date']);
    return purchaseDate.month == thisMonth && purchaseDate.year == thisYear;
  });

  var lastMonthPurchases = energyPurchases.where((purchase) {
    DateTime purchaseDate = DateTime.parse(purchase['date']);
    return purchaseDate.month == lastMonth && purchaseDate.year == lastMonthYear;
  });

  double thisMonthKwh = thisMonthPurchases.fold(0, (sum, purchase) => sum + double.parse(purchase['kwh'].toString()));
  double lastMonthKwh = lastMonthPurchases.fold(0, (sum, purchase) => sum + double.parse(purchase['kwh'].toString()));

  int daysInThisMonth = DateTime(thisYear, thisMonth + 1, 0).day;
  double dailyAverage = thisMonthKwh / daysInThisMonth;

  return {
    'dailyAverage': double.parse(dailyAverage.toStringAsFixed(2)),
    'thisMonth': double.parse(thisMonthKwh.toStringAsFixed(2)),
    'lastMonth': double.parse(lastMonthKwh.toStringAsFixed(2)),
  };
}

// Calculate expenses
Map<String, double> calculateExpenses(List<Map<String, dynamic>> expenses) {
  DateTime now = DateTime.now();
  String today = now.toIso8601String().split('T')[0];
  String thisWeekStart = now.subtract(Duration(days: now.weekday - 1)).toIso8601String().split('T')[0];
  String thisMonthStart = DateTime(now.year, now.month, 1).toIso8601String().split('T')[0];
  String lastMonthStart = DateTime(now.year, now.month - 1, 1).toIso8601String().split('T')[0];
  String lastMonthEnd = DateTime(now.year, now.month, 0).toIso8601String().split('T')[0];

  return {
    'today': expenses.where((e) => e['date'] == today).fold(0, (sum, e) => sum + e['amount']),
    'thisWeek': expenses.where((e) => e['date'].compareTo(thisWeekStart) >= 0).fold(0, (sum, e) => sum + e['amount']),
    'thisMonth': expenses.where((e) => e['date'].compareTo(thisMonthStart) >= 0).fold(0, (sum, e) => sum + e['amount']),
    'lastMonth': expenses.where((e) => e['date'].compareTo(lastMonthStart) >= 0 && e['date'].compareTo(lastMonthEnd) <= 0).fold(0, (sum, e) => sum + e['amount']),
  };
}

// Get fallback usage data
double getFallbackUsageData(String period) {
  Map<String, double> fallbackData = {
    'today': 100,
    'week': 700,
    'month': 3000,
    'lastMonth': 2800
  };
  return fallbackData[period] ?? 0;
}

// Get fallback revenue data
double getFallbackRevenueData(String period) {
  Map<String, double> fallbackData = {
    'today': 200,
    'week': 1400,
    'month': 6000,
    'lastMonth': 5600
  };
  return fallbackData[period] ?? 0;
}

// Check for maintenance alerts
List<Map<String, dynamic>> checkMaintenanceAlerts(Map<String, dynamic> data) {
  List<Map<String, dynamic>> alerts = [];
  DateTime currentDate = DateTime.now();
  bool isWeekend = currentDate.weekday == DateTime.saturday || currentDate.weekday == DateTime.sunday;

  // Weekly backwash check
  DateTime backwashDate = DateTime.parse(data['maintenance']['lastBackwash']).add(Duration(days: data['maintenance']['periods']['backwash']));
  if (currentDate.isAfter(backwashDate) && isWeekend) {
    alerts.add({
      'type': 'megaChar',
      'message': 'Weekly backwash needed for Mega Char',
      'dueDate': currentDate,
      'isWeekendTask': true
    });
    alerts.add({
      'type': 'softener',
      'message': 'Weekly backwash needed for Softener',
      'dueDate': currentDate,
      'isWeekendTask': true
    });
  }

  // Membrane replacement check
  DateTime membraneDate = DateTime.parse(data['roSystem']['membranes'][0]['lastReplaced']).add(Duration(days: data['maintenance']['periods']['membrane']));
  if (currentDate.isAfter(membraneDate)) {
    alerts.add({
      'type': 'Membrane',
      'message': '${data['roSystem']['membranes'].length} membrane(s) need replacement',
      'dueDate': membraneDate
    });
  }

  // Mega Char and Softener media replacement check
  DateTime mediaReplacementDate = DateTime.parse(data['maintenance']['mediaLastReplaced']).add(Duration(days: data['maintenance']['periods']['mediaReplacement']));
  if (currentDate.isAfter(mediaReplacementDate)) {
    alerts.add({
      'type': 'Media Replacement',
      'message': 'Mega Char (${data['roSystem']['megaCharVessels'].length} vessel(s)) and Softener media need replacement',
      'dueDate': mediaReplacementDate
    });
  }

  // Pre-filter replacement check
  DateTime preFilterDate = DateTime.parse(data['maintenance']['preFilterLastReplaced']).add(Duration(days: data['maintenance']['periods']['preFilter']));
  if (currentDate.isAfter(preFilterDate)) {
    alerts.add({
      'type': 'Pre-filter',
      'message': 'Pre-filter needs replacement',
      'dueDate': preFilterDate
    });
  }

  // Post-filter replacement check
  DateTime postFilterDate = DateTime.parse(data['maintenance']['postFilterLastReplaced']).add(Duration(days: data['maintenance']['periods']['postFilter']));
  if (currentDate.isAfter(postFilterDate)) {
    alerts.add({
      'type': 'Post-filter',
      'message': 'Post-filter needs replacement',
      'dueDate': postFilterDate
    });
  }

  return alerts;
}
