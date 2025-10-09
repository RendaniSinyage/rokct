import 'package:either_dart/either.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../../../core/utils/utils.dart';
import '../../roSystem/models/data/expense_data.dart';
import 'expenses_api.dart';
import '../expenses_statistics.dart';

class ExpenseRepository {
  final ExpenseService _expenseService;

  ExpenseRepository(this._expenseService);

  // Generic error handling method
  String _handleError(dynamic error) {
    // Log the error
    print('Expense Repository Error: $error');

    // Provide user-friendly error messages
    if (error is Exception) {
      // Check for specific types of exceptions
      if (error.toString().contains('SocketException')) {
        return 'No internet connection. Please check your network.';
      }
      if (error.toString().contains('TimeoutException')) {
        return 'Request timed out. Please try again.';
      }
    }

    // Generic error message for unhandled errors
    return 'An unexpected error occurred. Please try again later.';
  }

  // Wrapper method to check connectivity before making network calls
  Future<Either<String, T>> _safeApiCall<T>(Future<T> Function() apiCall) async {
    // Check internet connectivity
    final isConnected = await AppConnectivity.connectivity();

    if (!isConnected) {
      return Left('No internet connection. Please check your network.');
    }

    try {
      final result = await apiCall();
      return Right(result);
    } catch (e) {
      return Left(_handleError(e));
    }
  }

  Future<Either<String, List<ExpenseType>?>> getExpenseTypes() async {
    return _safeApiCall(() => _expenseService.getExpenseTypes());
  }

  Future<Either<String, List<Expense>?>> getExpenses({
    int? shopId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int perPage = 15,
  }) async {
    print('⭐️ Repository getExpenses called with:');
    print('⭐️ startDate: $startDate');
    print('⭐️ endDate: $endDate');

    return _safeApiCall(() => _expenseService.getExpenses(
      shopId: shopId,
      startDate: startDate,
      endDate: endDate,
      page: page,
      perPage: perPage,
    ));
  }

  Future<Either<String, Expense>> createExpense(Expense expense) async {
    return _safeApiCall(() => _expenseService.createExpense(expense));
  }

  Future<Either<String, Expense>> updateExpense(int id, Expense expense) async {
    return _safeApiCall(() => _expenseService.updateExpense(id, expense));
  }

  Future<Either<String, void>> deleteExpense(int id) async {
    return _safeApiCall(() => _expenseService.deleteExpense(id));
  }

  Future<Either<String, ExpenseStatistics>> getExpenseStatistics({
    int? shopId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _safeApiCall(() => _expenseService.getStatistics(
      shopId: shopId,
      startDate: startDate,
      endDate: endDate,
    ));
  }
}

// Provider for dependency injection
final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  final expenseService = ref.read(expenseServiceProvider);
  return ExpenseRepository(expenseService);
});
