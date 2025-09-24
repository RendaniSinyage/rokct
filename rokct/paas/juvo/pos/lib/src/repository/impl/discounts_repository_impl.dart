import 'dart:convert';
import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:admin_desktop/src/repository/discount_repository.dart';
import 'package:flutter/material.dart';
import '../../models/response/discount_paginate_response.dart';
import '../../models/response/single_discount_detail_response.dart';


class DiscountsRepositoryImpl extends DiscountsRepository {
  @override
  Future<ApiResult<DiscountPaginateResponse>> getAllDiscounts({
    bool isPagination = false,
    //bool isActive = true,
    int? page,
  }) async {
    final data = {
      'page': page,
      'perPage': 10,
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
      //'status': 'published'
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/seller/discounts/paginate',
        queryParameters: data,
      );
      return ApiResult.success(
        data: DiscountPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get all discounts failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));

    }
  }

  @override
  Future<ApiResult<DiscountDetail>> getDiscountDetails({
    required int id,
  }) async {
    final data = {
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/dashboard/seller/discounts/$id',
        queryParameters: data,
      );
      return ApiResult.success(
        data: DiscountDetail.fromJson(response.data),
      );
    } catch (e, s) {
      debugPrint('==> get discount details failure: $e,$s');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<void>> deleteDiscount(int? discountId) async {
    final data = {
      'ids': [discountId]
    };
    debugPrint('====> delete discount request ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.delete(
        '/api/v1/dashboard/seller/discounts/delete',
        data: data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> delete discount failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<void>> addDiscount({
    required String type,
    required num price,
    required bool active,
    required String startDate,
    required String endDate,
    required List<dynamic> ids,
    String? image,
  }) async {
    final data = {
      'type': type,
      'active': active ? 1 : 0,
      'start': startDate,
      'end': endDate,
      'price': price,
      for (int i = 0; i < ids.length; i++) 'stocks[$i]': ids[i],
      if (image != null) 'images[0]': image
    };
    debugPrint('====> add discount request ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/dashboard/seller/discounts',
        queryParameters: data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> add discount failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<void>> updateDiscount({
    required String type,
    required num price,
    required bool active,
    required String startDate,
    required String endDate,
    required List<dynamic> ids,
    String? image,
    required int id,
  }) async {
    final data = {
      'type': type,
      'active': active ? 1 : 0,
      'start': startDate,
      'end': endDate,
      'price': price,
      for (int i = 0; i < ids.length; i++) 'stocks[$i]': ids[i],
      if (image != null) 'images[0]': image
    };
    debugPrint('====> update discount request ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.put(
        '/api/v1/dashboard/seller/discounts/$id',
        queryParameters: data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update discount failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }
}

