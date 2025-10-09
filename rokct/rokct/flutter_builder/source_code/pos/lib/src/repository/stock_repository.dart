import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/handlers/api_result.dart';
import '../models/response/stock_paginate_response.dart';

abstract class StockRepository {
  Future<ApiResult<StockPaginateResponse>> getStocks({
    required int page,
    int? categoryId,
    String? query,
    ProductStatus? status,
    int? brandId,
    bool? isNew,
    List<int>? brandIds,
    List<int>? categoryIds,
    List<int>? extrasId,
    num? priceTo,
    num? priceFrom,
  });
}

