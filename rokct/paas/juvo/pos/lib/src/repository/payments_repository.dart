import '../core/handlers/handlers.dart';
import '../models/models.dart';

abstract class PaymentsRepository {
  Future<ApiResult<PaymentsResponse>> getPayments();

  Future<ApiResult<TransactionsResponse>> createTransaction({
    required int orderId,
    required int paymentId,
    String? terminalTransactionId,
  });

  Future<ApiResult<TransactionData>> getTransactionById({
    required int transactionId,
  });

  Future<ApiResult<List<TransactionData>>> getTransactionsByOrderId({
    required int orderId,
  });

  Future<ApiResult<TransactionData>> updateTransactionStatus({
    required int transactionId,
    required String status,
    String? note,
  });

  Future<ApiResult<void>> deleteTransaction({
    required int transactionId,
  });
}
