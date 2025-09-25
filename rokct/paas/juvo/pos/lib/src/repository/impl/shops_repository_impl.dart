import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:multi_dropdown/models/value_item.dart';

import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import '../../../app_constants.dart';
import '../../models/data/edit_shop_data.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../repository.dart';

class ShopsRepositoryImpl extends ShopsRepository {
  @override
  Future<ApiResult<ShopsPaginateResponse>> searchShops(String? query) async {
    final data = {
      if (query != null) 'search': query,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.search_shops',
        queryParameters: data,
      );
      return ApiResult.success(
        data: ShopsPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> search shops failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<ShopsPaginateResponse>> getShopsByIds(
    List<int> shopIds,
  ) async {
    final data = <String, dynamic>{
      'ids': shopIds,
    };
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_shops_by_ids',
        queryParameters: data,
      );
      return ApiResult.success(
        data: ShopsPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get shops by ids failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<EditShopData>> getShopData() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_user_shop',
      );
      return ApiResult.success(
        data: EditShopData.fromJson(response.data),
      );
    } catch (e, s) {
      debugPrint('==> get shops data failure: $e');
      debugPrint('==> get shops data failure: $s');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<CategoriesPaginateResponse>> getShopCategory() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_seller_categories',
        queryParameters: {'type': 'shop'},
      );
      return ApiResult.success(
        data: CategoriesPaginateResponse.fromJson(response.data),
      );
    } catch (e, s) {
      debugPrint('==> get shops category failure: $e');
      debugPrint('==> get shops category failure: $s');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<CategoriesPaginateResponse>> getShopTag() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_seller_tags',
      );
      return ApiResult.success(
        data: CategoriesPaginateResponse.fromJson(response.data),
      );
    } catch (e, s) {
      debugPrint('==> get shops category failure: $e');
      debugPrint('==> get shops category failure: $s');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<EditShopData>> updateShopData(
      {required EditShopData editShopData,
      required String? logoImg,
      required String? backImg,
      List<ValueItem>? category,
      List<ValueItem>? tag,
      List<ValueItem>? type,
      String? displayName}) async {
    final data = {
      'shop_data': editShopData.toJson(),
      if (logoImg != null) 'logo_image': logoImg,
      if (backImg != null) 'background_image': backImg,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.put(
        '/api/v1/method/rokct.paas.api.update_seller_shop',
        data: data,
      );
      return ApiResult.success(
        data: EditShopData.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> update shops data failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<void>> updateShopWorkingDays({
    required List<ShopWorkingDays> workingDays,
    String? uuid,
  }) async {
    final data = {'working_days_data': workingDays.map((e) => e.toJson()).toList()};
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.put(
        '/api/v1/method/rokct.paas.api.update_seller_shop_working_days',
        data: data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update shop working days failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<ShopData>> getShopDataById(int shopId) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_shop_by_id',
        queryParameters: {'id': shopId},
      );
      return ApiResult.success(data: ShopData.fromJson(response.data));
    } catch (e) {
      return ApiResult.failure(error: e.toString());
    }
  }

  // NOTE: The following methods are not supported or relevant for the POS app.
  // - getOnlyDeliveries

  @override
  Future<ApiResult<ShopDeliveriesResponse>> getOnlyDeliveries() {
    throw UnimplementedError();
  }
}