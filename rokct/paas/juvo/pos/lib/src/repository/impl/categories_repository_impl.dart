import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:flutter/material.dart';

import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../repository.dart';

class CategoriesRepositoryImpl extends CategoriesRepository {
  @override
  Future<ApiResult<CategoriesPaginateResponse>> searchCategories(
    String? query,
  ) async {
    final data = {
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
      'perPage': 100,
      'type': 'main',
      "has_products": 1,
      "p_shop_id": LocalStorage.getUser()?.role == TrKeys.waiter
          ?
          LocalStorage.getUser()?.invite?.shopId ?? 0
          : LocalStorage.getUser()?.shop?.id ?? 0
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        LocalStorage.getUser()?.role == TrKeys.seller
            ? '/api/v1/dashboard/${LocalStorage.getUser()?.role}/categories/paginate'
            : '/api/v1/rest/categories/paginate',
        queryParameters: data,
      );
      return ApiResult.success(
        data: CategoriesPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get categories failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }
}

