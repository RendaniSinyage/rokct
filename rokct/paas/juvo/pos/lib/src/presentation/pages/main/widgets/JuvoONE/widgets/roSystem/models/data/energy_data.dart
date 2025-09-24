class EnergyConsumptionData {
  final double dailyAverage;
  final double thisMonth;
  final double lastMonth;

  EnergyConsumptionData({
    required this.dailyAverage,
    required this.thisMonth,
    required this.lastMonth,
  });

  factory EnergyConsumptionData.fromJson(Map<String, dynamic> json) {
    return EnergyConsumptionData(
      dailyAverage: json['daily_average']?.toDouble() ?? 0.0,
      thisMonth: json['this_month']?.toDouble() ?? 0.0,
      lastMonth: json['last_month']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily_average': dailyAverage,
      'this_month': thisMonth,
      'last_month': lastMonth,
    };
  }
}
