import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/repository/repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../JuvoONE/widgets/expenses/repository/expense_repository.dart';
import 'income_notifier.dart';
import 'income_state.dart';

final incomeProvider = StateNotifierProvider<IncomeNotifier, IncomeState>((ref) {
  return IncomeNotifier(
    getIt<SettingsRepository>(),
    getIt<ExpenseRepository>(),
  );
});

