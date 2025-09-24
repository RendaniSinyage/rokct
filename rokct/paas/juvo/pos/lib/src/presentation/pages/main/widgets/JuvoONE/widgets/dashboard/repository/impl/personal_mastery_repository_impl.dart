import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../../../../../../core/handlers/handlers.dart';
import '../../models/personal_mastery_goal.dart';
import '../personal_mastery_repository.dart';

class PersonalMasteryRepositoryImpl implements PersonalMasteryRepository {
  final HttpService _httpService;
  static const String _baseUrl = 'api/v1/rest/resources';

  PersonalMasteryRepositoryImpl(this._httpService);

  @override
  Future<ApiResult<List<PersonalMasteryGoal>>> fetchPersonalMasteryGoals(int? userId) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{};
      if (userId != null) queryParams['user_id'] = userId.toString();

      final dio = _httpService.client(requireAuth: true);
      final response = await dio.get(
        '$_baseUrl/personal-mastery-goals',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> goalsJson = jsonData['data'];
          final goals = goalsJson
              .map((goalJson) => PersonalMasteryGoal.fromJson(goalJson))
              .toList();
          return ApiResult.success(data: goals);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to load personal mastery goals',
          );
        }
      } else {
        return ApiResult.failure(
          error: 'Failed to load personal mastery goals. Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error fetching personal mastery goals: ${e.message}');
        print('Response: ${e.response?.data}');
      }
      return ApiResult.failure(
        error: NetworkExceptions.getErrorMessage(
          NetworkExceptions.getDioException(e),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching personal mastery goals: $e');
      }
      return ApiResult.failure(error: e.toString());
    }
  }

  @override
  Future<ApiResult<PersonalMasteryGoal>> getPersonalMasteryGoal(String uuid) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.get('$_baseUrl/personal-mastery-goals/$uuid');

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final goal = PersonalMasteryGoal.fromJson(jsonData['data']);
          return ApiResult.success(data: goal);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to load personal mastery goal',
          );
        }
      } else {
        return ApiResult.failure(
          error: 'Failed to load personal mastery goal. Status: ${response.statusCode}',
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
  Future<ApiResult<PersonalMasteryGoal>> createPersonalMasteryGoal(
      Map<String, dynamic> data) async {
    try {
      if (kDebugMode) {
        print('Creating personal mastery goal with data: $data');
      }

      final dio = _httpService.client(requireAuth: true);
      final response = await dio.post(
        '$_baseUrl/personal-mastery-goals',
        data: data,
      );

      if (kDebugMode) {
        print('Goal creation response: ${response.statusCode} ${response.data}');
      }

      if (response.statusCode == 201) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final goal = PersonalMasteryGoal.fromJson(jsonData['data']);
          return ApiResult.success(data: goal);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to create personal mastery goal',
          );
        }
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to create personal mastery goal',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error creating personal mastery goal: ${e.message}');
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
        print('Error creating personal mastery goal: $e');
      }
      return ApiResult.failure(error: e.toString());
    }
  }

  @override
  Future<ApiResult<PersonalMasteryGoal>> updatePersonalMasteryGoal(
      String uuid, Map<String, dynamic> data) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.put(
        '$_baseUrl/personal-mastery-goals/$uuid',
        data: data,
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final goal = PersonalMasteryGoal.fromJson(jsonData['data']);
          return ApiResult.success(data: goal);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to update personal mastery goal',
          );
        }
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to update personal mastery goal',
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
  Future<ApiResult<bool>> deletePersonalMasteryGoal(String uuid) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.delete('$_baseUrl/personal-mastery-goals/$uuid');

      if (response.statusCode == 200) {
        return const ApiResult.success(data: true);
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to delete personal mastery goal',
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
  Future<ApiResult<List<PersonalMasteryGoal>>> fetchGoalsByArea(
      int? userId, String area) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{
        'area': area,
      };
      if (userId != null) queryParams['user_id'] = userId.toString();

      final dio = _httpService.client(requireAuth: true);
      final response = await dio.get(
        '$_baseUrl/personal-mastery-goals',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> goalsJson = jsonData['data'];
          final goals = goalsJson
              .map((goalJson) => PersonalMasteryGoal.fromJson(goalJson))
              .toList();
          return ApiResult.success(data: goals);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to load goals by area',
          );
        }
      } else {
        return ApiResult.failure(
          error: 'Failed to load goals by area. Status: ${response.statusCode}',
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
  Future<ApiResult<List<PersonalMasteryGoal>>> fetchGoalsByStatus(
      int? userId, String status) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{
        'status': status,
      };
      if (userId != null) queryParams['user_id'] = userId.toString();

      final dio = _httpService.client(requireAuth: true);
      final response = await dio.get(
        '$_baseUrl/personal-mastery-goals',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> goalsJson = jsonData['data'];
          final goals = goalsJson
              .map((goalJson) => PersonalMasteryGoal.fromJson(goalJson))
              .toList();
          return ApiResult.success(data: goals);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to load goals by status',
          );
        }
      } else {
        return ApiResult.failure(
          error: 'Failed to load goals by status. Status: ${response.statusCode}',
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
