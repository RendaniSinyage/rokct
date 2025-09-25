import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:admin_desktop/src/models/data/count_of_notifications_data.dart';
import 'package:admin_desktop/src/models/data/notification_data.dart';
import 'package:admin_desktop/src/models/data/notification_transactions_data.dart';
import 'package:admin_desktop/src/models/data/read_one_notification_data.dart';
import 'package:admin_desktop/src/repository/notification_repository.dart';
import 'package:flutter/material.dart';
import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';

class NotificationRepositoryImpl extends NotificationRepository {
  @override
  Future<ApiResult<TransactionListResponse>> getTransactions(
      {int? page}) async {
    final data = {
      'limit_start': ((page ?? 1) - 1) * 4,
      'limit_page_length': 4,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_seller_transactions',
        queryParameters: data,
      );
      return ApiResult.success(
        data: TransactionListResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get getTransactions failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<NotificationResponse>> getNotifications({
    int? page,
  }) async {
    final data = {
      'limit_start': ((page ?? 1) - 1) * 7,
      'limit_page_length': 7,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_user_notifications',
        queryParameters: data,
      );
      return ApiResult.success(
        data: NotificationResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get notification failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  // NOTE: The following methods are not supported by the new backend.
  // - readAll
  // - readOne
  // - showSingleUser
  // - getAllNotifications
  // - getCount

  @override
  Future<ApiResult<NotificationResponse>> readAll() {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<ReadOneNotificationResponse>> readOne({int? id}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<NotificationResponse>> showSingleUser({int? id}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<NotificationResponse>> getAllNotifications() {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<CountNotificationModel>> getCount() {
    throw UnimplementedError();
  }
}