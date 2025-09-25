import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import '../../models/response/stock_paginate_response.dart';
import '../stock_repository.dart';

class StockRepositoryImpl implements StockRepository {
  @override
  Future<ApiResult<StockPaginateResponse>> getStocks({
    required int page,
    int? categoryId,
    String? query,
    ProductStatus? status,
    int? brandId,
    int? shopId,
    bool? isNew,
    List<int>? brandIds,
    List<int>? categoryIds,
    List<int>? extrasId,
    num? priceTo,
    num? priceFrom,
  }) async {
    String? statusText;
    if (status != null) {
      switch (status) {
        case ProductStatus.pending:
          statusText = 'pending';
          break;
        case ProductStatus.published:
          statusText = 'published';
          break;
        case ProductStatus.unpublished:
          statusText = 'unpublished';
          break;
        default:
          statusText = 'published';
          break;
      }
    }

    final data = {
      if (query != null) 'search': query,
      'limit_start': (page - 1) * 10,
      'limit_page_length': 10,
      if (categoryId != null) 'category_id': categoryId,
      if (brandId != null) 'brand_id': brandId,
      if (statusText != null) 'status': statusText,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_seller_inventory_items',
        queryParameters: data,
      );
      return ApiResult.success(
        data: StockPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get stock failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }
}