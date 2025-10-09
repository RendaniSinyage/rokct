
import 'expenses_type.dart';

class ExpenseStatistics {
  final double totalExpenses;
  final List<ExpenseTypeStats> byType;

  ExpenseStatistics({
    required this.totalExpenses,
    required this.byType,
  });

  factory ExpenseStatistics.fromJson(Map<String, dynamic> json) {
    return ExpenseStatistics(
      totalExpenses: (json['total_expenses'] as num).toDouble(),
      byType: (json['by_type'] as List)
          .map((type) => ExpenseTypeStats.fromJson(type))
          .toList(),
    );
  }
}
