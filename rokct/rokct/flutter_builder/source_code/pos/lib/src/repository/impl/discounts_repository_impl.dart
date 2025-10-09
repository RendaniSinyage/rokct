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
      'limit_page_length': 10,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_seller_discounts',
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
  Future<ApiResult<void>> deleteDiscount(int? discountId) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.delete_seller_discount',
        data: {'discount_name': discountId},
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
      'valid_from': startDate,
      'valid_upto': endDate,
      'rate': price,
      'items': ids,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.create_seller_discount',
        data: {'discount_data': data},
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
      'valid_from': startDate,
      'valid_upto': endDate,
      'rate': price,
      'items': ids,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.put(
        '/api/v1/method/rokct.paas.api.update_seller_discount',
        data: {
          'discount_name': id,
          'discount_data': data,
        },
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update discount failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  // NOTE: The getDiscountDetails method is no longer needed, as the
  // getAllDiscounts method now returns all the necessary data.
  @override
  Future<ApiResult<DiscountDetail>> getDiscountDetails({required int id}) {
    throw UnimplementedError();
  }
}