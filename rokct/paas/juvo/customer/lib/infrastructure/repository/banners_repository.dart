import 'package:flutter/material.dart';
import 'package:foodyman/domain/di/dependency_manager.dart';
import 'package:foodyman/domain/interface/banners.dart';
import 'package:foodyman/infrastructure/models/models.dart';
import 'package:foodyman/domain/handlers/handlers.dart';
import 'package:foodyman/infrastructure/services/app_helpers.dart';

class BannersRepository implements BannersRepositoryFacade {
  @override
  Future<ApiResult<BannersPaginateResponse>> getBannersPaginate(
      {required int page}) async {
    final params = {
      'limit_start': (page - 1) * 10,
      'limit_page_length': 10,
    };
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/rokct.paas.api.get_banners',
        queryParameters: params,
      );
      return ApiResult.success(
        data: BannersPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get banners failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<BannerData>> getBannerById(
    int? bannerId,
  ) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/rokct.paas.api.get_banner',
        queryParameters: {'id': bannerId},
      );
      return ApiResult.success(
        data: BannerData.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get banner by id failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // NOTE: The following methods are not supported by the new backend.
  // - getAdsPaginate
  // - getAdsById
  // - likeBanner

  @override
  Future<ApiResult<BannersPaginateResponse>> getAdsPaginate({required int page}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<BannerData>> getAdsById(int? bannerId) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<void>> likeBanner(int? bannerId) {
    throw UnimplementedError();
  }
}