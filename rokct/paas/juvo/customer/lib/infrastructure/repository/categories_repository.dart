import 'package:foodyman/domain/di/dependency_manager.dart';
import 'package:foodyman/domain/interface/categories.dart';
import 'package:foodyman/infrastructure/models/models.dart';
import 'package:foodyman/domain/handlers/handlers.dart';
import 'package:foodyman/infrastructure/services/app_helpers.dart';

class CategoriesRepository implements CategoriesRepositoryFacade {
  @override
  Future<ApiResult<CategoriesPaginateResponse>> getAllCategories({
    required int page,
    String? shopId,
  }) async {
    final params = {
      'limit_start': (page - 1) * 10,
      'limit_page_length': 10,
      if (shopId != null) 'shop_id': shopId,
    };

    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/rokct.paas.api.get_categories',
        queryParameters: params,
      );
      return ApiResult.success(
        data: CategoriesPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CategoriesPaginateResponse>> searchCategories(
      {required String text}) async {
    final params = {'search': text};
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/rokct.paas.api.search_categories',
        queryParameters: params,
      );
      return ApiResult.success(
        data: CategoriesPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<CategoriesPaginateResponse>> getCategoriesByShop(
      {required String shopId}) async {
    return getAllCategories(page: 1, shopId: shopId);
  }
}