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
      final response = await client.get('/api/v1/method/rokct.paas.api.get_payment_gateways');
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
      'reference_doctype': 'Order',
      'reference_name': orderId,
      'payment_gateway': paymentId,
      if (terminalTransactionId != null) 'transaction_id': terminalTransactionId,
    };

    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/v1/method/rokct.paas.api.create_transaction',
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
        '/api/v1/method/rokct.paas.api.get_transaction',
        queryParameters: {'id': transactionId},
      );
      return ApiResult.success(
        data: TransactionData.fromJson(response.data),
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
        '/api/v1/method/rokct.paas.api.get_transactions_by_order',
        queryParameters: {'order_id': orderId},
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

  // NOTE: The following methods are not supported by the new backend.
  // - updateTransactionStatus
  // - deleteTransaction

  @override
  Future<ApiResult<TransactionData>> updateTransactionStatus({required int transactionId, required String status, String? note}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<void>> deleteTransaction({required int transactionId}) {
    throw UnimplementedError();
  }
}