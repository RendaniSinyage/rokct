import 'dart:convert';
import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../repository.dart';

class OrdersRepositoryImpl extends OrdersRepository {
  @override
  Future<ApiResult<CreateOrderResponse>> createOrder(
      OrderBodyData orderBody) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final data = orderBody.toJson();
      debugPrint('==> order create data: ${jsonEncode(data)}');
      final response = await client.post(
        '/api/v1/method/rokct.paas.api.create_order',
        data: data
      );

      return ApiResult.success(
        data: CreateOrderResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> order create failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<OrdersPaginateResponse>> getOrders({
    OrderStatus? status,
    int? page,
    DateTime? from,
    DateTime? to,
    String? search,
  }) async {
    String? statusText;
    switch (status) {
      case OrderStatus.accepted:
        statusText = 'accepted';
        break;
      case OrderStatus.ready:
        statusText = 'ready';
        break;
      case OrderStatus.onAWay:
        statusText = 'on_a_way';
        break;
      case OrderStatus.delivered:
        statusText = 'delivered';
        break;
      case OrderStatus.canceled:
        statusText = 'canceled';
        break;
      case OrderStatus.newOrder:
        statusText = 'new';
        break;
      case OrderStatus.cooking:
        statusText = 'cooking';
        break;
      default:
        statusText = null;
        break;
    }
    final data = {
      if (page != null) 'page': page,
      if (statusText != null) 'status': statusText,
      if (from != null)
        "from_date": from.toString().substring(0, from.toString().indexOf(" ")),
      if (to != null)
        "to_date": to.toString().substring(0, to.toString().indexOf(" ")),
      if (search != null) 'search': search,
      'limit_page_length': to == null ? 7 : 15,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_seller_orders',
        queryParameters: data,
      );
      return ApiResult.success(
        data: OrdersPaginateResponse.fromJson(response.data),
      );
    } catch (e, s) {
      debugPrint('==> get order $status failure: $e,$s');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> updateOrderStatus({
    required OrderStatus status,
    int? orderId,
  }) async {
    String? statusText;
    switch (status) {
      case OrderStatus.newOrder:
        statusText = 'new';
        break;
      case OrderStatus.accepted:
        statusText = 'accepted';
        break;
      case OrderStatus.ready:
        statusText = 'ready';
        break;
      case OrderStatus.onAWay:
        statusText = 'on_a_way';
        break;
      case OrderStatus.delivered:
        statusText = 'delivered';
        break;
      case OrderStatus.canceled:
        statusText = 'canceled';
        break;
      case OrderStatus.cooking:
        statusText = 'cooking';
        break;
    }

    final data = {'status': statusText};
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.update_order_status',
        data: {
          'order_id': orderId,
          'status': statusText,
        },
      );
      return const ApiResult.success(
        data: null,
      );
    } catch (e) {
      debugPrint('==> update order status failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<SingleOrderResponse>> getOrderDetails({int? orderId}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
          '/api/v1/method/rokct.paas.api.get_order_details',
          queryParameters: {'order_id': orderId});
      return ApiResult.success(
        data: SingleOrderResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get order details failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<dynamic>> setDeliverMan(
      {required int orderId, required int deliverymanId}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final data = {
        'deliveryman': deliverymanId,
      };
      final response = await client.post(
          '/api/v1/method/rokct.paas.api.update_order',
          data: {
            'order_id': orderId,
            'order_data': data,
          });
      return ApiResult.success(
        data: SingleOrderResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> set deliveryman failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult> deleteOrder({required int orderId}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.delete_order',
        data: {'order_id': orderId},
      );
      return const ApiResult.success(
        data: null,
      );
    } catch (e) {
      debugPrint('==> delete order failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  // NOTE: The following methods are not supported or relevant for the POS app.
  // - getKitchenOrders
  // - updateOrderDetailStatus
  // - updateOrderStatusKitchen
  // - getOrderDetailsKitchen

  @override
  Future<ApiResult<OrderKitchenResponse>> getKitchenOrders({String? status, int? page, DateTime? from, DateTime? to, String? search}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult> updateOrderDetailStatus({required String status, int? orderId}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult> updateOrderStatusKitchen({required OrderStatus status, int? orderId}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<SingleKitchenOrderResponse>> getOrderDetailsKitchen({int? orderId}) {
    throw UnimplementedError();
  }
}