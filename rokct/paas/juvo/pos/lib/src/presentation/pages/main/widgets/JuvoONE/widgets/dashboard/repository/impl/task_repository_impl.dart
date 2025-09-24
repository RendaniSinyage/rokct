import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../../../../../../core/handlers/handlers.dart';
import '../../models/todo_task.dart';
import '../task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final HttpService _httpService;
  static const String _baseUrl = 'api/v1/rest/resources';

  TaskRepositoryImpl(this._httpService);

  @override
  Future<ApiResult<List<TodoTask>>> fetchTasks(
      String? shopId, {
        String? kpiId,
        String? objectiveId,
        String? appId,
      }) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{};
      if (shopId != null) queryParams['shop_id'] = shopId;
      if (kpiId != null) queryParams['kpi_id'] = kpiId;
      if (objectiveId != null) queryParams['objective_id'] = objectiveId;
      if (appId != null) queryParams['app_id'] = appId;

      final dio = _httpService.client(requireAuth: true);
      final response = await dio.get(
        '$_baseUrl/tasks',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> tasksJson = jsonData['data'];
          final tasks = tasksJson
              .map((taskJson) => TodoTask.fromJson(taskJson))
              .toList();
          return ApiResult.success(data: tasks);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to load tasks',
          );
        }
      } else {
        return ApiResult.failure(
          error: 'Failed to load tasks. Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error fetching tasks: ${e.message}');
        print('Response: ${e.response?.data}');
      }
      return ApiResult.failure(
        error: NetworkExceptions.getErrorMessage(
          NetworkExceptions.getDioException(e),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching tasks: $e');
      }
      return ApiResult.failure(error: e.toString());
    }
  }

  @override
  Future<ApiResult<TodoTask>> getTask(String uuid) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.get('$_baseUrl/tasks/$uuid');

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final task = TodoTask.fromJson(jsonData['data']);
          return ApiResult.success(data: task);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to load task',
          );
        }
      } else {
        return ApiResult.failure(
          error: 'Failed to load task. Status: ${response.statusCode}',
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
  Future<ApiResult<TodoTask>> createTask(Map<String, dynamic> data) async {
    try {
      if (kDebugMode) {
        print('Creating task with data: $data');
      }

      final dio = _httpService.client(requireAuth: true);
      final response = await dio.post(
        '$_baseUrl/tasks',
        data: data,
      );

      if (kDebugMode) {
        print('Task creation response: ${response.statusCode} ${response.data}');
      }

      if (response.statusCode == 201) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final task = TodoTask.fromJson(jsonData['data']);
          return ApiResult.success(data: task);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to create task',
          );
        }
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to create task',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error creating task: ${e.message}');
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
        print('Error creating task: $e');
      }
      return ApiResult.failure(error: e.toString());
    }
  }

  @override
  Future<ApiResult<TodoTask>> updateTask(String uuid, Map<String, dynamic> data) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.put(
        '$_baseUrl/tasks/$uuid',
        data: data,
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final task = TodoTask.fromJson(jsonData['data']);
          return ApiResult.success(data: task);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to update task',
          );
        }
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to update task',
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
  Future<ApiResult<bool>> deleteTask(String uuid) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.delete('$_baseUrl/tasks/$uuid');

      if (response.statusCode == 200) {
        return const ApiResult.success(data: true);
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to delete task',
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
