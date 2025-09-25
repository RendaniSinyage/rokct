import 'package:flutter/material.dart';
import 'package:foodyman/domain/di/dependency_manager.dart';
import 'package:foodyman/domain/interface/brands.dart';
import 'package:foodyman/infrastructure/models/models.dart';
import 'package:foodyman/infrastructure/services/app_helpers.dart';
import 'package:foodyman/domain/handlers/handlers.dart';

class BrandsRepository implements BrandsRepositoryFacade {
  @override
  Future<ApiResult<BrandsPaginateResponse>> getBrandsPaginate(int page) async {
    final params = {
      'limit_start': (page - 1) * 18,
      'limit_page_length': 18,
    };
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/rokct.paas.api.get_brands',
        queryParameters: params,
      );
      return ApiResult.success(
        data: BrandsPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get brands paginate failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<SingleBrandResponse>> getSingleBrand(String uuid) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/rokct.paas.api.get_brand_by_uuid',
        queryParameters: {'uuid': uuid},
      );
      return ApiResult.success(
        data: SingleBrandResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get brand failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // NOTE: The following methods are no longer needed as the new get_brands
  // endpoint can handle these cases with filters.
  // - getAllBrands
  // - searchBrands

  @override
  Future<ApiResult<BrandsPaginateResponse>> getAllBrands({int? categoryId, String? shopId}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<BrandsPaginateResponse>> searchBrands(String query) {
    throw UnimplementedError();
  }
}