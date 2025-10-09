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
      'limit_start': (page ?? 1) - 1 * 12,
      'limit_page_length': 12,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        "/api/v1/method/rokct.paas.api.get_seller_stories",
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
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.delete_seller_story',
        data: {'story_name': id},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> delete story failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<void>> createStories(
      {required List<String> img, int? id}) async {
    final data = {
      'images': img,
      if (id != null) 'product_id': id
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.create_seller_story',
        data: {'story_data': data},
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
      'images': img,
      if (id != null) 'product_id': id
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.put(
        '/api/v1/method/rokct.paas.api.update_seller_story',
        data: {
          'story_name': storyId,
          'story_data': data,
        },
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update stories failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }
}