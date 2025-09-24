import '../../roSystem/models/data/expense_data.dart';
import '../expense_details_income.dart';

class ExpenseState {
  final List<Expense>? expenses;
  final List<ExpenseType>? expenseTypes;
  final ExpenseDetailsIncome? revenue;
  final DateTime? start;
  final DateTime? end;
  final bool isLoading;

  const ExpenseState({
    this.expenses,
    this.expenseTypes,
    this.revenue,
    this.start,
    this.end,
    this.isLoading = false,
  });

  ExpenseState copyWith({
    List<Expense>? expenses,
    List<ExpenseType>? expenseTypes,
    ExpenseDetailsIncome? revenue,
    DateTime? start,
    DateTime? end,
    bool? isLoading,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      expenseTypes: expenseTypes ?? this.expenseTypes,
      revenue: revenue ?? this.revenue,
      start: start ?? this.start,
      end: end ?? this.end,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}


