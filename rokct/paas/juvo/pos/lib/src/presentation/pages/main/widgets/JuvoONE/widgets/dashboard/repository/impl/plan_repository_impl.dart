import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../../../../../../core/handlers/handlers.dart';
import '../../../../../../../../../core/utils/utils.dart';
import '../../models/vision.dart';
import '../plan_repository.dart';

class PlanRepositoryImpl implements PlanRepository {
  final HttpService _httpService;
  static const String _baseUrl = 'api/v1/rest/resources';

  PlanRepositoryImpl(this._httpService);

  @override
  Future<ApiResult<Vision>> getPlanOnPage(String? shopId) async {
    try {
      // If shopId is null, try to get it from LocalStorage
      shopId ??= LocalStorage.getUser()?.shop?.id?.toString();

      if (shopId == null) {
        return ApiResult.failure(
            error: 'No shop ID available. Please select a shop.'
        );
      }

      final dio = _httpService.client(requireAuth: true);

      // Ensure the token is being added
      final token = LocalStorage.getToken();
      if (token.isEmpty) {
        return ApiResult.failure(
            error: 'Authentication token is missing'
        );
      }

      // Add authorization header manually if needed
      dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await dio.get('$_baseUrl/plan-on-page/$shopId');

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final vision = Vision.fromJson(jsonData['data']);
          return ApiResult.success(data: vision);
        } else {
          return ApiResult.failure(
              error: jsonData['message'] ?? 'Failed to load plan data'
          );
        }
      } else {
        return ApiResult.failure(
            error: 'Failed to load plan data. Status: ${response.statusCode}'
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error fetching plan: ${e.message}');
        print('Response: ${e.response?.data}');
        print('Shop ID: $shopId');
        print('Token: ${LocalStorage.getToken()}');
      }

      // Check if there's a specific error message from the server
      final errorMessage = e.response?.data is Map
          ? (e.response?.data['message'] ?? 'Unknown error')
          : 'Unknown error';

      return ApiResult.failure(
          error: errorMessage
      );
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error fetching plan: $e');
      }
      return ApiResult.failure(error: e.toString());
    }
  }



  @override
  Future<ApiResult<Vision>> createVision(Map<String, dynamic> data) async {
    try {
      if (kDebugMode) {
        print('Creating vision with data: $data');
      }

      final dio = _httpService.client(requireAuth: true);

      // Ensure dates are converted to ISO 8601 format
      if (data['effective_date'] is DateTime) {
        data['effective_date'] = (data['effective_date'] as DateTime).toIso8601String().split('T')[0];
      }
      if (data['end_date'] is DateTime) {
        data['end_date'] = (data['end_date'] as DateTime)?.toIso8601String().split('T')[0];
      }

      final response = await dio.post(
        '$_baseUrl/visions',
        data: data,
      );

      if (kDebugMode) {
        print('Vision creation response: ${response.statusCode} ${response.data}');
      }

      if (response.statusCode == 201) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final vision = Vision.fromJson(jsonData['data']);
          return ApiResult.success(data: vision);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to create vision',
          );
        }
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to create vision',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error creating vision: ${e.message}');
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
        print('Error creating vision: $e');
      }
      return ApiResult.failure(error: e.toString());
    }
  }

  @override
  Future<ApiResult<Vision>> updateVision(String uuid, Map<String, dynamic> data) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.put('$_baseUrl/visions/$uuid', data: data);

      if (response.statusCode == 200) {
        // Successfully updated, now get the updated plan
        return await getPlanOnPage(data['shop_id']);
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to update vision',
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
  Future<ApiResult<dynamic>> createPillar(Map<String, dynamic> data) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.post('$_baseUrl/pillars', data: data);

      if (response.statusCode == 201) {
        return ApiResult.success(data: response.data['data']);
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to create pillar',
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
  Future<ApiResult<dynamic>> updatePillar(String uuid, Map<String, dynamic> data) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.put('$_baseUrl/pillars/$uuid', data: data);

      if (response.statusCode == 200) {
        return ApiResult.success(data: response.data['data']);
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to update pillar',
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
  Future<ApiResult<dynamic>> createStrategicObjective(Map<String, dynamic> data) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.post('$_baseUrl/objectives', data: data);

      if (response.statusCode == 201) {
        return ApiResult.success(data: response.data['data']);
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to create objective',
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
  Future<ApiResult<dynamic>> updateStrategicObjective(String uuid, Map<String, dynamic> data) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.put('$_baseUrl/objectives/$uuid', data: data);

      if (response.statusCode == 200) {
        return ApiResult.success(data: response.data['data']);
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to update objective',
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
  Future<ApiResult<dynamic>> createKpi(Map<String, dynamic> data) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.post('$_baseUrl/kpis', data: data);

      if (response.statusCode == 201) {
        return ApiResult.success(data: response.data['data']);
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to create KPI',
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
  Future<ApiResult<dynamic>> updateKpi(String uuid, Map<String, dynamic> data) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.put('$_baseUrl/kpis/$uuid', data: data);

      if (response.statusCode == 200) {
        return ApiResult.success(data: response.data['data']);
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to update KPI',
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
