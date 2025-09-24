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
        '/api/v1/dashboard/${LocalStorage.getUser()?.role}/orders',
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
  Future<ApiResult<OrderKitchenResponse>> getKitchenOrders({
    String? status,
    int? page,
    DateTime? from,
    DateTime? to,
    String? search,
  }) async {
    final data = {
      if (page != null) 'page': page,
      if (status != null && TrKeys.all != status) 'status': status,
      if (TrKeys.all == status) 'statuses[0]': "accepted",
      if (TrKeys.all == status) 'statuses[1]': "cooking",
      if (TrKeys.all == status) 'statuses[2]': "ready",
      if (search != null) 'search': search,
      'perPage': 9,
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/cook/orders/paginate',
        queryParameters: data,
      );
      return ApiResult.success(
        data: OrderKitchenResponse.fromJson(response.data),
      );
    } catch (e, s) {
      debugPrint('==> get order $status failure: $e, $s');
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
        "date_from": from.toString().substring(0, from.toString().indexOf(" ")),
      if (to != null)
        "date_to": to.toString().substring(0, to.toString().indexOf(" ")),
      if (search != null) 'search': search,
      'perPage': to == null ? 7 : 15,
      if (LocalStorage.getUser()?.role == TrKeys.waiter) 'empty-waiter': 1,
      if (LocalStorage.getUser()?.role == TrKeys.waiter)
        'delivery_type': 'dine_in',
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/${LocalStorage.getUser()?.role}/orders/paginate',
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
        LocalStorage.getUser()?.role == TrKeys.waiter
            ? '/api/v1/dashboard/waiter/order/$orderId/status/update'
            : '/api/v1/dashboard/${LocalStorage.getUser()?.role}/order/$orderId/status',
        data: data,
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
  Future<ApiResult<dynamic>> updateOrderDetailStatus({
    required String status,
    int? orderId,
  }) async {
    final data = {'status': status};
    debugPrint('==> update order status data: ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        LocalStorage.getUser()?.role == TrKeys.waiter
            ? '/api/v1/dashboard/waiter/order/details/$orderId/status/update'
            : LocalStorage.getUser()?.role == TrKeys.cook
                ? '/api/v1/dashboard/cook/order-detail/$orderId/status/update'
                : '/api/v1/dashboard/${LocalStorage.getUser()?.role}/order/details/$orderId/status',
        data: data,
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
  Future<ApiResult<dynamic>> updateOrderStatusKitchen({
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
      case OrderStatus.cooking:
        statusText = 'cooking';
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
    }

    final data = {'status': statusText};
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/dashboard/cook/orders/$orderId/status/update',
        data: data,
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
      final data = {
        'lang': LocalStorage.getLanguage()?.locale ?? 'en',
      };
      final response = await client.get(
          '/api/v1/dashboard/${LocalStorage.getUser()?.role}/orders/$orderId',
          queryParameters: data);
      return ApiResult.success(
        data: SingleOrderResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get order details failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<SingleKitchenOrderResponse>> getOrderDetailsKitchen(
      {int? orderId}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final data = {
        'lang': LocalStorage.getLanguage()?.locale ?? 'en',
      };
      final response = await client
          .get('/api/v1/dashboard/cook/orders/$orderId', queryParameters: data);
      return ApiResult.success(
        data: SingleKitchenOrderResponse.fromJson(response.data),
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
          '/api/v1/dashboard/${LocalStorage.getUser()?.role}/order/$orderId/deliveryman',
          data: data);
      return ApiResult.success(
        data: SingleOrderResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get order details failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult> deleteOrder({required int orderId}) async {
    final data = {'ids[0]': orderId};
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.delete(
        '/api/v1/dashboard/${LocalStorage.getUser()?.role}/orders/delete',
        queryParameters: data,
      );
      return const ApiResult.success(
        data: null,
      );
    } catch (e) {
      debugPrint('==> update order status failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }
}

