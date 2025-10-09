import 'package:admin_desktop/src/models/response/income_cart_response.dart';
import 'package:admin_desktop/src/models/response/income_chart_response.dart';
import 'package:admin_desktop/src/models/response/income_statistic_response.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:admin_desktop/src/core/constants/constants.dart';

import '../../JuvoONE/widgets/expenses/expense_details_income.dart';
import '../../JuvoONE/widgets/roSystem/models/data/expense_data.dart';

part 'income_state.freezed.dart';

@freezed
class IncomeState with _$IncomeState {
  const factory IncomeState({
    @Default(true) bool isLoading,
    @Default(TrKeys.month) String selectType,
    @Default(null) IncomeCartResponse? incomeCart,
    @Default(null) IncomeStatisticResponse? incomeStatistic,
    @Default([]) List<IncomeChartResponse>? incomeCharts,
    @Default([]) List<num> prices,
    @Default([]) List<DateTime> time,
    @Default(null) DateTime? start,
    @Default(null) DateTime? end,
    // Added expense-related fields with defaults
    @Default([]) List<Expense>? expenses,
    @Default([]) List<ExpenseType>? expenseTypes,
    @Default(ExpenseDetailsIncome()) ExpenseDetailsIncome? expenseRevenue,
  }) = _IncomeState;

  const IncomeState._();
}
