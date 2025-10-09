import 'package:admin_desktop/src/core/handlers/api_result.dart';
import '../models/response/discount_paginate_response.dart';

abstract class DiscountsRepository {
  Future<ApiResult<DiscountPaginateResponse>> getAllDiscounts({
    int? page,
    bool isPagination = false,
  });

  Future<ApiResult<void>> deleteDiscount(int? discountId);

  Future<ApiResult> addDiscount({
    required String type,
    required num price,
    required bool active,
    required String startDate,
    required String endDate,
    required List ids,
    String? image,
  });

  Future<ApiResult> updateDiscount({
    required String type,
    required num price,
    required bool active,
    required String startDate,
    required String endDate,
    required List ids,
    String? image,
    required int id,
  });

  Future<ApiResult> getDiscountDetails({required int id});
}

