import 'package:flutter/material.dart';
import 'package:foodyman/domain/di/dependency_manager.dart';
import 'package:foodyman/domain/interface/orders.dart';
import 'package:foodyman/infrastructure/models/data/order_active_model.dart';
import 'package:foodyman/infrastructure/models/models.dart';
import 'package:foodyman/infrastructure/services/app_helpers.dart';
import 'package:foodyman/domain/handlers/handlers.dart';

class OrdersRepository implements OrdersRepositoryFacade {
  @override
  Future<ApiResult<OrderActiveModel>> createOrder(
      OrderBodyData orderBody) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/v1/method/rokct.paas.api.create_order',
        data: orderBody.toJson(),
      );
      return ApiResult.success(
        data: OrderActiveModel.fromJson(response.data),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<OrderPaginateResponse>> getOrders({
    required int page,
    String? status,
  }) async {
    final data = {
      'page': page,
      'limit_page_length': 10,
      if (status != null) 'status': status,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.list_orders',
        queryParameters: data,
      );
      return ApiResult.success(
        data: OrderPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get orders failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<OrderActiveModel>> getSingleOrder(num orderId) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_order_details',
        queryParameters: {'order_id': orderId},
      );
      return ApiResult.success(
        data: OrderActiveModel.fromJson(response.data),
      );
    } catch (e, s) {
      debugPrint('==> get single order failure: $e,$s');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> addReview(
      num orderId, {
        required double rating,
        required String comment,
      }) async {
    final data = {
      'order_id': orderId,
      'rating': rating,
      if (comment.isNotEmpty) 'comment': comment,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.add_order_review',
        data: data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> add order review failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<String>> process(
      dynamic orderBody, String name, {
        BuildContext? context,
      }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      var res = await client.post(
        '/api/v1/method/rokct.paas.api.initiate_${name.toLowerCase()}_payment',
        data: {'order_id': orderBody.orderId},
      );
      return ApiResult.success(data: res.data["redirect_url"]);
    } catch (e, s) {
      debugPrint('==> order process failure: $e, $s');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> cancelOrder(num orderId) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.cancel_order',
        data: {'order_id': orderId},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> get cancel order failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> refundOrder(num orderId, String title) async {
    try {
      final data = {
        "order": orderId,
        "cause": title,
      };
      final client = dioHttp.client(requireAuth: true);
      await client.post('/api/v1/method/rokct.paas.api.create_order_refund', data: data);
      return const ApiResult.success(
        data: null,
      );
    } catch (e) {
      debugPrint('==> refund order failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // NOTE: The following methods are not supported or have been consolidated.
  // - createAutoOrder
  // - deleteAutoOrder
  // - getCompletedOrders
  // - getActiveOrders
  // - getHistoryOrders
  // - processWalletTopUp
  // - processWalletTokenPayment
  // - processTokenPayment
  // - getSavedCards
  // - deleteCard
  // - setDefaultCard
  // - tokenizeCard
  // - processDirectCardPayment
  // - tokenizeAfterPayment
  // - tipProcess
  // - checkCoupon
  // - checkCashback
  // - getCalculate
  // - getRefundOrders
  // - getDriverLocation

  @override
  Future<ApiResult> createAutoOrder(String from, String to, int orderId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult> deleteAutoOrder(int orderId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<OrderPaginateResponse>> getCompletedOrders(int page) {
    return getOrders(page: page, status: 'Delivered');
  }

  @override
  Future<ApiResult<OrderPaginateResponse>> getActiveOrders(int page) {
    return getOrders(page: page, status: 'Accepted');
  }

  @override
  Future<ApiResult<OrderPaginateResponse>> getHistoryOrders(int page) {
    return getOrders(page: page, status: 'Delivered');
  }

  @override
  Future<ApiResult<String>> processWalletTopUp(double amount, {BuildContext? context, bool forceCardPayment = false, bool enableTokenization = true}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<String>> processWalletTokenPayment(double amount, String token) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<String>> processTokenPayment(OrderBodyData orderData, String token) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<List<SavedCardModel>>> getSavedCards() {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<bool>> deleteCard(String cardId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<bool>> setDefaultCard(String cardId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<String>> tokenizeCard({required String cardNumber, required String cardName, required String expiryDate, required String cvc}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<String>> processDirectCardPayment(OrderBodyData orderBody, String cardNumber, String cardName, String expiryDate, String cvc) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<String>> tokenizeAfterPayment(String cardNumber, String cardName, String expiryDate, String cvc, [String? token, String? lastFour, String? cardType]) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<String>> tipProcess(int? orderId, String paymentName, int? paymentId, num? tips) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<CouponResponse>> checkCoupon({required String coupon, required int shopId}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<CashbackResponse>> checkCashback({required double amount, required int shopId}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<GetCalculateModel>> getCalculate({required int cartId, required double lat, required double long, required DeliveryTypeEnum type, String? coupon}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<RefundOrdersModel>> getRefundOrders(int page) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<LocalLocation>> getDriverLocation(int deliveryId) {
    throw UnimplementedError();
  }
}