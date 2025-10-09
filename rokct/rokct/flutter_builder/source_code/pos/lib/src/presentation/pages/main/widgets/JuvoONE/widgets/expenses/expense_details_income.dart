import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../repository/settings_repository.dart';
import '../roSystem/models/data/expense_data.dart';

class ExpenseDetailsIncome {
  final double? revenue;
  final double? expense;
  final double? profit;
  final double? expensePercent;
  final String? expenseType;

  const ExpenseDetailsIncome({
    this.revenue,
    this.expense,
    this.profit,
    this.expensePercent,
    this.expenseType,
  });

  ExpenseDetailsIncome copyWith({
    double? revenue,
    double? expense,
    double? profit,
    double? expensePercent,
    String? expenseType,
  }) {
    return ExpenseDetailsIncome(
      revenue: revenue ?? this.revenue,
      expense: expense ?? this.expense,
      profit: profit ?? this.profit,
      expensePercent: expensePercent ?? this.expensePercent,
      expenseType: expenseType ?? this.expenseType,
    );
  }
}


