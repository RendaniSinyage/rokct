import 'package:admin_desktop/src/core/constants/constants.dart';

import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/models/models.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../core/di/injection.dart';
import '../core/utils/utils.dart';

abstract class OrdersRepository {
  Future<ApiResult<CreateOrderResponse>> createOrder(OrderBodyData orderBody);

  Future<ApiResult<OrdersPaginateResponse>> getOrders({
    OrderStatus? status,
    int? page,
    DateTime? from,
    DateTime? to,
    String? search,
  });

  Future<ApiResult<OrdersPaginateResponse>> getUserDeliveredOrders({
    required int userId,
    int? page,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      String? currencyId;
      try {
        currencyId = LocalStorage.getSelectedCurrency().id.toString();
      } catch (e) {
        debugPrint('No currency selected or error getting currency: $e');
      }

      final data = {
        if (currencyId != null) 'currency_id': currencyId,
        if (LocalStorage.getLanguage() != null)
          'lang': LocalStorage.getLanguage()?.locale,
        'user_id': userId,  // This works as confirmed in API response
        'status': 'delivered',
        'perPage': 10,
        'sort': 'desc',    // To get latest orders first
        if (page != null) 'page': page,
      };

      final client = inject<HttpService>().client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/${LocalStorage.getUser()?.role}/orders/paginate',  // Confirmed working endpoint
        queryParameters: data,
      );

      return ApiResult.success(
        data: OrdersPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get user delivered orders failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
      );
    }
  }

  Future<ApiResult<dynamic>> updateOrderStatus({
    required OrderStatus status,
    int? orderId,
  });

  Future<ApiResult<dynamic>> updateOrderDetailStatus({
    required String status,
    int? orderId,
  });

  Future<ApiResult<dynamic>> updateOrderStatusKitchen({
    required OrderStatus status,
    int? orderId,
  });

  Future<ApiResult<SingleOrderResponse>> getOrderDetails({int? orderId});

  Future<ApiResult<SingleKitchenOrderResponse>> getOrderDetailsKitchen(
      {int? orderId});

  Future<ApiResult<dynamic>> setDeliverMan(
      {required int orderId, required int deliverymanId});

  Future<ApiResult<dynamic>> deleteOrder({required int orderId});

  Future<ApiResult<OrderKitchenResponse>> getKitchenOrders({
    String? status,
    int? page,
    String? search,
  });
}

