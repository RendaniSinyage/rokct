
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../core/constants/constants.dart';
import '../../../../../../repository/settings_repository.dart';
import '../../JuvoONE/widgets/expenses/expense_details_income.dart';
import '../../JuvoONE/widgets/expenses/repository/expense_repository.dart';
import '../../JuvoONE/widgets/roSystem/models/data/expense_data.dart';
import 'income_state.dart';

class IncomeNotifier extends StateNotifier<IncomeState> {
  final SettingsRepository _settingsRepository;
  final ExpenseRepository _expenseRepository;

  IncomeNotifier(this._settingsRepository, this._expenseRepository)
      : super(const IncomeState());

  changeIndex(String type) {
    state = state.copyWith(
        selectType: type,
        // Reset start and end dates when changing index
        start: null,
        end: null
    );
    fetchIncomeCarts();
    fetchIncomeCharts();
    fetchIncomeStatistic();
    fetchExpenseData();
  }

  fetchIncomeCarts({DateTime? start, DateTime? end}) async {
    state = state.copyWith(start: start, end: end);
    final response = await _settingsRepository.getIncomeCart(
        type: state.selectType,
        from: start ??
            (state.selectType == TrKeys.day
                ? DateTime.now()
                : state.selectType == TrKeys.month
                ? DateTime.now().subtract(const Duration(days: 30))
                : DateTime.now().subtract(const Duration(days: 7))),
        to: end ?? DateTime.now());
    response.when(
      success: (data) async {
        state = state.copyWith(incomeCart: data);
      },
      failure: (failure) {},
    );
  }

  fetchIncomeStatistic({DateTime? start, DateTime? end}) async {
    final response = await _settingsRepository.getIncomeStatistic(
        type: state.selectType,
        from: start ??
            (state.selectType == TrKeys.day
                ? DateTime.now()
                : state.selectType == TrKeys.month
                ? DateTime.now().subtract(const Duration(days: 30))
                : DateTime.now().subtract(const Duration(days: 7))),
        to: end ?? DateTime.now());
    response.when(
      success: (data) async {
        state = state.copyWith(incomeStatistic: data);
      },
      failure: (failure) {},
    );
  }

  fetchIncomeCharts({DateTime? start, DateTime? end}) async {
    final response = await _settingsRepository.getIncomeChart(
        type: start == null ? state.selectType : TrKeys.month,
        from: start ??
            (state.selectType == TrKeys.day
                ? DateTime.now()
                : state.selectType == TrKeys.month
                ? DateTime.now().subtract(const Duration(days: 30))
                : DateTime.now().subtract(const Duration(days: 7))),
        to: end ?? DateTime.now());
    response.when(
      success: (data) async {
        List<num> prices = [];
        List<DateTime> times = [];
        if (data.isNotEmpty) {
          num price = data.first.totalPrice ?? 0;
          for (var element in data) {
            if (price < (element.totalPrice ?? 0)) {
              price = element.totalPrice ?? 0;
            }
          }
          num a = price / 6;
          prices = List.generate(7, (index) => (price - (index * a)));
          times = List.generate(
            state.selectType == TrKeys.day
                ? 24
                : state.selectType == TrKeys.month
                ? 30
                : state.selectType == TrKeys.week
                ? 7
                : data.length,
                (index) => state.selectType == TrKeys.day
                ? DateTime.now().subtract(Duration(hours: index))
                : state.selectType == TrKeys.month
                ? DateTime.now().subtract(Duration(days: index))
                : state.selectType == TrKeys.week
                ? DateTime.now().subtract(Duration(days: index))
                : DateTime.now().subtract(Duration(days: index)),
          );
        }

        state = state.copyWith(
            incomeCharts: data, prices: prices.reversed.toList(), time: times);
      },
      failure: (failure) {},
    );
  }

  Future<void> fetchExpenseData({DateTime? start, DateTime? end}) async {
    state = state.copyWith(isLoading: true);

    DateTime startDate;
    DateTime endDate;

    // Prioritize manually selected dates
    if (start != null && end != null) {
      startDate = DateTime(start.year, start.month, start.day);
      endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);
    } else {
      // Use type-based calculation when no manual dates
      final now = DateTime.now();
      switch (state.selectType) {
        case TrKeys.day:
          startDate = DateTime(now.year, now.month, now.day);
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        case TrKeys.week:
          startDate = now.subtract(const Duration(days: 7));
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
        default: // month
          startDate = now.subtract(const Duration(days: 30));
          endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
          break;
      }
    }

    try {
      // Fetch expense types
      final expenseTypesResponse = await _expenseRepository.getExpenseTypes();
      List<ExpenseType>? expenseTypes;
      expenseTypesResponse.fold(
              (error) {
            print('Expense Types Error: $error');
          },
              (types) {
            expenseTypes = types;
          }
      );

      // Fetch expenses with date range
      final expensesResponse = await _expenseRepository.getExpenses(
        startDate: startDate,
        endDate: endDate,
      );

      List<Expense>? expenses;
      double totalExpenses = 0.0;

      expensesResponse.fold(
              (error) {
            print('Expenses Error: $error');
          },
              (fetchedExpenses) {
            expenses = fetchedExpenses;

            // Detailed debug logging
            print('🔍 Start Date: $startDate');
            print('🔍 End Date: $endDate');
            print('🔍 Total Fetched Expenses: ${fetchedExpenses?.length ?? 0}');
            fetchedExpenses?.forEach((expense) {
              print('🔍 Expense Details:');
              print('   - ID: ${expense.id}');
              print('   - Created At: ${expense.createdAt}');
              print('   - Price: ${expense.price}');
              print('   - Quantity: ${expense.qty}');
            });

            // Explicitly filter expenses with detailed logging
            final filteredExpenses = fetchedExpenses?.where((expense) {
              if (expense.createdAt == null) {
                print('🔍 Skipping expense: createdAt is null');
                return false;
              }

              // Strip time components from createdAt
              final expenseDate = DateTime(
                  expense.createdAt!.year,
                  expense.createdAt!.month,
                  expense.createdAt!.day
              );

              // Detailed comparison logging
              print('🔍 Comparing Dates:');
              print('   - Expense Date: $expenseDate');
              print('   - Start Date: $startDate');
              print('   - End Date: $endDate');

              final isWithinRange =
                  (expenseDate.isAtSameMomentAs(startDate) || expenseDate.isAfter(startDate)) &&
                      (expenseDate.isAtSameMomentAs(endDate) || expenseDate.isBefore(endDate));

              print('🔍 Is Within Range: $isWithinRange');

              return isWithinRange;
            }).toList();

            // Calculate total expenses only for the filtered expenses
            totalExpenses = filteredExpenses?.fold(0.0, (sum, expense) =>
            sum! + (expense.price * expense.qty)) ?? 0.0;

            print('🔍 Filtered Expenses: ${filteredExpenses?.length ?? 0}');
            print('🔍 Total Expenses: $totalExpenses');
          }
      );

      // Fetch income cart with same date range
      final incomeCartResponse = await _settingsRepository.getIncomeCart(
        type: start == null ? state.selectType : TrKeys.month,
        from: startDate,
        to: endDate,
      );

      // Calculate profit and details
      ExpenseDetailsIncome expenseDetailsIncome = const ExpenseDetailsIncome();

      incomeCartResponse.when(
          success: (incomeCart) {
            final revenue = (incomeCart.revenue ?? 0).toDouble();
            final profit = revenue - totalExpenses;
            final expensePercent = revenue > 0
                ? (totalExpenses / revenue * 100).roundToDouble()
                : 0.0;

            expenseDetailsIncome = ExpenseDetailsIncome(
              revenue: revenue,
              expense: totalExpenses,
              profit: profit,
              expensePercent: expensePercent,
              expenseType: revenue > 0 ? (profit >= 0 ? 'plus' : 'minus') : null,
            );
          },
          failure: (error) {
            print('Income Cart Error: $error');
          }
      );

      state = state.copyWith(
        expenses: expenses,
        expenseTypes: expenseTypes,
        expenseRevenue: expenseDetailsIncome,
        start: startDate,
        end: endDate,
        isLoading: false,
      );

    } catch (e) {
      print('Error fetching expense data: $e');
      state = state.copyWith(
        isLoading: false,
        expenseRevenue: const ExpenseDetailsIncome(),
      );
    }
  }

  void refreshData() {
    // Use the current state's dates for all fetches
    final start = state.start;
    final end = state.end;

    // If no dates are selected, use default date range based on selectType
    if (start == null || end == null) {
      fetchExpenseData();
    } else {
      // Force a refresh with explicitly selected dates
      fetchIncomeCarts(start: start, end: end);
      fetchIncomeCharts(start: start, end: end);
      fetchIncomeStatistic(start: start, end: end);
      fetchExpenseData(start: start, end: end);
    }
  }
}
