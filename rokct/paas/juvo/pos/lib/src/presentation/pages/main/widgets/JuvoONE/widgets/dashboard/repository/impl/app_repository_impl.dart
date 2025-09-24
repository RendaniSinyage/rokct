
// repository/app_repository_impl.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../../../../../../core/handlers/handlers.dart';
import '../app_repository.dart';

class AppRepositoryImpl implements AppRepository {
  final HttpService _httpService;
  static const String _baseUrl = 'api/v1/rest/resources';

  AppRepositoryImpl(this._httpService);

  @override
  Future<ApiResult<List<App>>> fetchApps(String? shopId) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{};
      if (shopId != null) queryParams['shop_id'] = shopId;

      final dio = _httpService.client(requireAuth: true);
      final response = await dio.get(
        '$_baseUrl/apps',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> appsJson = jsonData['data'];
          final apps = appsJson
              .map((appJson) => App.fromJson(appJson))
              .toList();
          return ApiResult.success(data: apps);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to load apps',
          );
        }
      } else {
        return ApiResult.failure(
          error: 'Failed to load apps. Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error fetching apps: ${e.message}');
        print('Response: ${e.response?.data}');
      }
      return ApiResult.failure(
        error: NetworkExceptions.getErrorMessage(
          NetworkExceptions.getDioException(e),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching apps: $e');
      }
      return ApiResult.failure(error: e.toString());
    }
  }

  @override
  Future<ApiResult<App>> getApp(String uuid) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.get('$_baseUrl/apps/$uuid');

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final app = App.fromJson(jsonData['data']);
          return ApiResult.success(data: app);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to load app',
          );
        }
      } else {
        return ApiResult.failure(
          error: 'Failed to load app. Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      return ApiResult.failure(
        error: NetworkExceptions.getErrorMessage(
          NetworkExceptions.getDioException(e),
        ),
      );
    } catch (e) {
      return ApiResult.failure(error: e.toString());
    }
  }

  @override
  Future<ApiResult<App>> createApp(Map<String, dynamic> data) async {
    try {
      if (kDebugMode) {
        print('Creating app with data: $data');
      }

      final dio = _httpService.client(requireAuth: true);
      final response = await dio.post(
        '$_baseUrl/apps',
        data: data,
      );

      if (response.statusCode == 201) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final app = App.fromJson(jsonData['data']);
          return ApiResult.success(data: app);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to create app',
          );
        }
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to create app',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error creating app: ${e.message}');
        print('Response: ${e.response?.data}');
      }

      // Extract validation errors if present
      if (e.response?.statusCode == 422 && e.response?.data?['errors'] != null) {
        final errors = e.response!.data['errors'] as Map<String, dynamic>;
        final errorMessages = errors.values
            .expand((e) => e is List ? e : [e.toString()])
            .join(', ');
        return ApiResult.failure(error: errorMessages);
      }

      return ApiResult.failure(
        error: NetworkExceptions.getErrorMessage(
          NetworkExceptions.getDioException(e),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error creating app: $e');
      }
      return ApiResult.failure(error: e.toString());
    }
  }

  @override
  Future<ApiResult<App>> updateApp(String uuid, Map<String, dynamic> data) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.put(
        '$_baseUrl/apps/$uuid',
        data: data,
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final app = App.fromJson(jsonData['data']);
          return ApiResult.success(data: app);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to update app',
          );
        }
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to update app',
        );
      }
    } on DioException catch (e) {
      return ApiResult.failure(
        error: NetworkExceptions.getErrorMessage(
          NetworkExceptions.getDioException(e),
        ),
      );
    } catch (e) {
      return ApiResult.failure(error: e.toString());
    }
  }

  @override
  Future<ApiResult<bool>> deleteApp(String uuid) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.delete('$_baseUrl/apps/$uuid');

      if (response.statusCode == 200) {
        return const ApiResult.success(data: true);
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to delete app',
        );
      }
    } on DioException catch (e) {
      return ApiResult.failure(
        error: NetworkExceptions.getErrorMessage(
          NetworkExceptions.getDioException(e),
        ),
      );
    } catch (e) {
      return ApiResult.failure(error: e.toString());
    }
  }
}
