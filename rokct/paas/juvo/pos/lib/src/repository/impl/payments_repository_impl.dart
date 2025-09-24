import 'dart:convert';

import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:flutter/material.dart';

import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import '../../core/handlers/handlers.dart';
import '../../models/models.dart';
import '../repository.dart';

class PaymentsRepositoryImpl extends PaymentsRepository {
  @override
  Future<ApiResult<PaymentsResponse>> getPayments() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get('/api/v1/rest/payments');
      return ApiResult.success(
        data: PaymentsResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get payments failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<TransactionsResponse>> createTransaction({
    required int orderId,
    required int paymentId,
    String? terminalTransactionId,
  }) async {
    final data = {
      'payment_sys_id': paymentId,
      if (terminalTransactionId != null) 'terminal_transaction_id': terminalTransactionId,
      'note': terminalTransactionId != null ? 'Terminal payment' : 'Cash payment',
    };

    debugPrint('===> create transaction body: ${jsonEncode(data)}');
    debugPrint('===> create transaction order id: $orderId');

    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/v1/payments/order/$orderId/transactions',
        data: data,
      );
      return ApiResult.success(
        data: TransactionsResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> create transaction failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<TransactionData>> getTransactionById({
    required int transactionId,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/payments/transactions/$transactionId',
      );
      return ApiResult.success(
        data: TransactionData.fromJson(response.data['data']),
      );
    } catch (e) {
      debugPrint('==> get transaction failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<List<TransactionData>>> getTransactionsByOrderId({
    required int orderId,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/payments/order/$orderId/transactions',
      );

      final List<dynamic> data = response.data['data'] ?? [];
      final List<TransactionData> transactions = data
          .map((json) => TransactionData.fromJson(json))
          .toList();

      return ApiResult.success(data: transactions);
    } catch (e) {
      debugPrint('==> get transactions by order failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<TransactionData>> updateTransactionStatus({
    required int transactionId,
    required String status,
    String? note,
  }) async {
    final data = {
      'status': status,
      if (note != null) 'note': note,
    };

    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.put(
        '/api/v1/payments/transactions/$transactionId/status',
        data: data,
      );
      return ApiResult.success(
        data: TransactionData.fromJson(response.data['data']),
      );
    } catch (e) {
      debugPrint('==> update transaction status failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<void>> deleteTransaction({
    required int transactionId,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.delete(
        '/api/v1/payments/transactions/$transactionId',
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> delete transaction failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }
}
