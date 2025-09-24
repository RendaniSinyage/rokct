import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import '../../models/response/stories_response.dart';
import '../stories_repository.dart';

class StoriesRepositoryImpl extends StoriesRepository {
  @override
  Future<ApiResult<StoriesResponse>> getStories({
    int? page,
  }) async {
    final data = {
      'page': page,
      'perPage': 12,
      'lang': LocalStorage.getLanguage()?.locale ?? 'en',
      'shop_id': LocalStorage.getUser()?.shop?.id,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        "/api/v1/dashboard/seller/stories",
        queryParameters: data,
      );
      return ApiResult.success(
        data: StoriesResponse.fromJson(response.data),
      );
    } catch (e, s) {
      debugPrint('==> get stories failure: $e,$s');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<void>> deleteStories(int id) async {
    final data = {
      'ids': [id]
    };
    debugPrint('====> delete brand request ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.delete(
        '/api/v1/dashboard/seller/stories/delete',
        data: data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> delete brand failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<void>> createStories(
      {required List<String> img, int? id}) async {
    final data = {
      for (int i = 0; i < img.length; i++) 'file_urls[$i]': img[i],
      if (id != null) 'product_id': id
    };
    debugPrint('====> add stories request ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/dashboard/seller/stories',
        queryParameters: data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> create stories failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<void>> updateStories(
      {required List<String> img, int? id, required int storyId}) async {
    final data = {
      for (int i = 0; i < img.length; i++) 'file_urls[$i]': img[i],
      if (id != null) 'product_id': id
    };
    debugPrint('====> update stories request ${jsonEncode(data)}');
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.put(
        '/api/v1/dashboard/seller/stories/$storyId',
        queryParameters: data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update stories failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }
}

