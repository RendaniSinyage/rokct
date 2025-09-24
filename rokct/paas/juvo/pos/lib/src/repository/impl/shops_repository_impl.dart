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
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
      'status': 'approved',
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/${LocalStorage.getUser()?.role}/shops/search',
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
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
    };
    for (int i = 0; i < shopIds.length; i++) {
      data['shops[$i]'] = shopIds[i];
    }
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/v1/rest/shops',
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
    final data = <String, dynamic>{
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/seller/shops',
        queryParameters: data,
      );
      return ApiResult.success(
        data: EditShopData.fromJson(response.data['data']),
      );
    } catch (e, s) {
      debugPrint('==> get shops data failure: $e');
      debugPrint('==> get shops data failure: $s');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<CategoriesPaginateResponse>> getShopCategory() async {
    final data = <String, dynamic>{
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
      'type': 'shop'
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/seller/categories',
        queryParameters: data,
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
    final data = <String, dynamic>{
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/seller/shop-tags/paginate',
        queryParameters: data,
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
    final data = <String, dynamic>{
      for (int i = 0; i < (category?.length ?? 0); i++)
        'categories[]': category?[i].value,
      for (int r = 0; r < (tag?.length ?? 0); r++) 'tags[]': tag?[r].value,
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
      if (logoImg?.isNotEmpty ?? false) 'images[0]': logoImg,
      if (backImg?.isNotEmpty ?? false) 'images[1]': backImg,
      'title[${LocalStorage.getLanguage()?.locale ?? 'en'}]':
          editShopData.translation?.title,
      'description[${LocalStorage.getLanguage()?.locale ?? 'en'}]':
          editShopData.translation?.description,
      if (editShopData.statusNote?.isNotEmpty ?? false)
        'status_note': editShopData.statusNote,
      'status': editShopData.status.toString(),
      'phone': editShopData.phone,
      'price': editShopData.price,
      'price_per_km': editShopData.perKm,
      'delivery_time_from': editShopData.deliveryTime?.from,
      'delivery_time_to': editShopData.deliveryTime?.to,
      'delivery_time_type':
          type?.isNotEmpty ?? false ? type?.first.value : 'hour',
      'min_amount': editShopData.minAmount,
      'tax': editShopData.tax,
      'percentage': editShopData.percentage,
      'location[latitude]': editShopData.location?.latitude,
      'location[longitude]': editShopData.location?.longitude,
      if (displayName?.isNotEmpty ?? false)
        'address[${LocalStorage.getLanguage()?.locale ?? 'en'}]': displayName,
      'type': 'restaurant'
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.put(
        '/api/v1/dashboard/seller/shops',
        queryParameters: data,
      );
      return ApiResult.success(
        data: EditShopData.fromJson(response.data['data']),
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
    List<Map<String, dynamic>> days = [];
    for (final workingDay in workingDays) {
      final data = {
        'day': workingDay.day,
        'from': workingDay.from,
        'to': workingDay.to,
        'disabled': workingDay.disabled
      };
      days.add(data);
    }
    final data = {'dates': days};
    debugPrint('====> update working days ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.put(
        '/api/v1/dashboard/seller/shop-working-days/${uuid ?? LocalStorage.getUser()?.shop?.uuid}',
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
    final url = '${AppConstants.baseUrl}api/v1/dashboard/admin/shops/$shopId';

    try {
      final httpService = HttpService();
      final dio = httpService.client(requireAuth: true);
      final response = await dio.get(url);

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return ApiResult.success(data: ShopData.fromJson(response.data['data']));
      }

      return ApiResult.failure(error: response.statusMessage ?? 'Unknown error');
    } catch (e) {
      return ApiResult.failure(error: e.toString());
    }
  }

  @override
  Future<ApiResult<ShopDeliveriesResponse>> getOnlyDeliveries() async {
    final data = {
      'currency_id': LocalStorage.getSelectedCurrency().id,
    };
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/v1/rest/shops/deliveries',
        queryParameters: data,
      );
      return ApiResult.success(
        data: ShopDeliveriesResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get shops deliveries failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }
}

