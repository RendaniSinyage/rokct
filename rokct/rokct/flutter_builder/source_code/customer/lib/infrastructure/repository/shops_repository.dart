import 'package:flutter/material.dart';
import 'package:foodyman/domain/di/dependency_manager.dart';
import 'package:foodyman/domain/interface/shops.dart';
import 'package:foodyman/infrastructure/models/models.dart';
import 'package:foodyman/domain/handlers/handlers.dart';
import 'package:foodyman/infrastructure/services/app_helpers.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/data/filter_model.dart';

class ShopsRepository implements ShopsRepositoryFacade {
  @override
  Future<ApiResult<ShopsPaginateResponse>> searchShops(
      {required String text, int? categoryId}) async {
    final params = {
      'search': text,
      if (categoryId != null) 'category_id': categoryId,
    };
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.search_shops',
        queryParameters: params,
      );
      return ApiResult.success(
        data: ShopsPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> search shops failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getAllShops(
    int page, {
    int? categoryId,
    FilterModel? filterModel,
    bool? isOpen,
  }) async {
    final params = {
      'limit_start': (page - 1) * 10,
      'limit_page_length': 10,
      if (categoryId != null) 'category_id': categoryId,
      if (filterModel?.sort != null) 'order_by': filterModel!.sort,
      if (isOpen ?? false) 'open': 1,
    };
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_shops',
        queryParameters: params,
      );
      return ApiResult.success(
        data: ShopsPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get all shops failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<SingleShopResponse>> getSingleShop(
      {required String uuid}) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_shop_by_uuid',
        queryParameters: {'uuid': uuid},
      );
      return ApiResult.success(
        data: SingleShopResponse.fromJson(response.data),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<bool>> checkDriverZone(LatLng location,
      {int? shopId}) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final data = {
        'latitude': location.latitude,
        'longitude': location.longitude,
        if (shopId != null) 'shop_id': shopId,
      };
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.check_delivery_zone',
        queryParameters: data,
      );
      return ApiResult.success(
        data: response.data["status"] == "success",
      );
    } catch (e) {
      debugPrint('==> get delivery zone failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // NOTE: The following methods are not supported by the new backend or have been consolidated.
  // - getNearbyShops
  // - getShopBranch
  // - joinOrder
  // - getShopFilter
  // - getPickupShops
  // - getShopsByIds
  // - createShop
  // - getShopsRecommend
  // - getStory
  // - getTags
  // - getSuggestPrice

  @override
  Future<ApiResult<ShopsPaginateResponse>> getNearbyShops(double latitude, double longitude) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<BranchResponse>> getShopBranch({required int uuid}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult> joinOrder({required String shopId, required String name, required String cartId}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getShopFilter({int? categoryId, required int page, int? subCategoryId}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getPickupShops() {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getShopsByIds(List<int> shopIds) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<void>> createShop({required double tax, required List<String> documents, required double deliveryTo, required double deliveryFrom, required String deliveryType, required String phone, required String name, required num category, required String description, required double startPrice, required double perKm, AddressNewModel? address, String? logoImage, String? backgroundImage}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getShopsRecommend(int page) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<List<List<StoryModel?>?>?>> getStory(int page) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<TagResponse>> getTags(int categoryId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<PriceModel>> getSuggestPrice() {
    throw UnimplementedError();
  }
}