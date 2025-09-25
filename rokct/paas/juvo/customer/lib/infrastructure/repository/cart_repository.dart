import 'package:flutter/material.dart';
import 'package:foodyman/domain/handlers/api_result.dart';
import 'package:foodyman/domain/interface/cart.dart';
import 'package:foodyman/infrastructure/models/data/cart_data.dart';
import 'package:foodyman/domain/di/dependency_manager.dart';
import 'package:foodyman/domain/handlers/network_exceptions.dart';
import 'package:foodyman/infrastructure/services/app_helpers.dart';

class CartRepository implements CartRepositoryFacade {
  @override
  Future<ApiResult<CartModel>> getCart(String shopId) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_cart',
        queryParameters: {'shop_id': shopId},
      );
      return ApiResult.success(
        data: CartModel.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> getCart failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CartModel>> addToCart({
    required String itemCode,
    required int qty,
    required String shopId,
  }) async {
    final data = {
      'item_code': itemCode,
      'qty': qty,
      'shop_id': shopId,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/v1/method/rokct.paas.api.add_to_cart',
        data: data,
      );
      return ApiResult.success(
        data: CartModel.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> addToCart failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> removeProductFromCart({required int cartDetailId}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.remove_from_cart',
        data: {'cart_detail_name': cartDetailId},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> removeProductFromCart failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // NOTE: The following methods are not supported by the new backend.
  // - createCart
  // - insertCart
  // - insertCartWithGroup
  // - createAndCart
  // - getCartInGroup
  // - deleteCart
  // - changeStatus
  // - deleteUser
  // - startGroupOrder

  @override
  Future<ApiResult<CartModel>> createCart({required CartRequest cart}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<CartModel>> insertCart({required CartRequest cart}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<CartModel>> insertCartWithGroup({required CartRequest cart}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<CartModel>> createAndCart({required CartRequest cart}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<CartModel>> getCartInGroup(String? cartId, String? shopId, String? cartUuid) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<CartModel>> deleteCart({required int cartId}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult> changeStatus({required String? userUuid, required String? cartId}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult> deleteUser({required int cartId, required String userId}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult> startGroupOrder({required int cartId}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<CartModel>> removeProductCart({required int cartDetailId, List<int>? listOfId}) {
    throw UnimplementedError();
  }
}