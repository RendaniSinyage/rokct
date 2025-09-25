import 'package:flutter/material.dart';
import 'package:foodyman/domain/di/dependency_manager.dart';
import 'package:foodyman/domain/handlers/api_result.dart';
import 'package:foodyman/domain/handlers/network_exceptions.dart';
import 'package:foodyman/domain/interface/notification.dart';
import 'package:foodyman/infrastructure/models/data/count_of_notifications_data.dart';
import 'package:foodyman/infrastructure/models/response/notification_response.dart';
import 'package:foodyman/infrastructure/services/app_helpers.dart';

class NotificationRepositoryImpl extends NotificationRepositoryFacade {
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
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // NOTE: The new backend does not have endpoints for reading notifications
  // or getting a count of notifications. These features would need to be
  // implemented on the backend if they are still required.

  @override
  Future<ApiResult<NotificationResponse>> readAll() async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<dynamic>> readOne({int? id}) async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<NotificationResponse>> getAllNotifications() async {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<CountNotificationModel>> getCount() async {
    throw UnimplementedError();
  }
}