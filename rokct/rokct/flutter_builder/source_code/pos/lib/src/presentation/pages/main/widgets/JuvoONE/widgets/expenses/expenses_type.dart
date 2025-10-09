
class ExpenseTypeStats {
  final String name;
  final double totalAmount;
  final int count;
  final double totalKwh;
  final double totalLitres;

  ExpenseTypeStats({
    required this.name,
    required this.totalAmount,
    required this.count,
    required this.totalKwh,
    required this.totalLitres,
  });

  factory ExpenseTypeStats.fromJson(Map<String, dynamic> json) {
    return ExpenseTypeStats(
      name: json['name'] ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      count: json['count'] ?? 0,
      totalKwh: (json['total_kwh'] as num?)?.toDouble() ?? 0.0,
      totalLitres: (json['total_litres'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ExpenseTypeStatsParams {
  final DateTime? startDate;
  final DateTime? endDate;

  ExpenseTypeStatsParams({this.startDate, this.endDate});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is ExpenseTypeStatsParams &&
              runtimeType == other.runtimeType &&
              startDate == other.startDate &&
              endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}
