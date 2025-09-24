import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../../../../../../core/handlers/handlers.dart';
import '../../models/roadmap_version.dart';
import '../roadmap_repository.dart';

class RoadmapRepositoryImpl implements RoadmapRepository {
  final HttpService _httpService;
  static const String _baseUrl = 'api/v1/rest/resources';

  RoadmapRepositoryImpl(this._httpService);

  @override
  Future<ApiResult<List<RoadmapVersion>>> fetchRoadmapVersions(String? appId) async {
    if (appId == null) {
      return const ApiResult.failure(error: 'App ID is required');
    }

    try {
      final queryParams = <String, dynamic>{
        'app_id': appId,
      };

      final dio = _httpService.client(requireAuth: true);
      final response = await dio.get(
        '$_baseUrl/roadmap-versions',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> versionsJson = jsonData['data'];
          final versions = versionsJson
              .map((versionJson) => RoadmapVersion.fromJson(versionJson))
              .toList();

          // Sort versions by version number (descending - newest first)
          versions.sort((a, b) => _compareVersions(b.versionNumber, a.versionNumber));

          return ApiResult.success(data: versions);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to load roadmap versions',
          );
        }
      } else {
        return ApiResult.failure(
          error: 'Failed to load roadmap versions. Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error fetching roadmap versions: ${e.message}');
        print('Response: ${e.response?.data}');
      }
      return ApiResult.failure(
        error: NetworkExceptions.getErrorMessage(
          NetworkExceptions.getDioException(e),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching roadmap versions: $e');
      }
      return ApiResult.failure(error: e.toString());
    }
  }

  @override
  Future<ApiResult<RoadmapVersion>> getRoadmapVersion(String uuid) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.get('$_baseUrl/roadmap-versions/$uuid');

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final version = RoadmapVersion.fromJson(jsonData['data']);
          return ApiResult.success(data: version);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to load roadmap version',
          );
        }
      } else {
        return ApiResult.failure(
          error: 'Failed to load roadmap version. Status: ${response.statusCode}',
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
  Future<ApiResult<RoadmapVersion>> createRoadmapVersion(Map<String, dynamic> data) async {
    try {
      if (kDebugMode) {
        print('Creating roadmap version with data: $data');
      }

      final dio = _httpService.client(requireAuth: true);
      final response = await dio.post(
        '$_baseUrl/roadmap-versions',
        data: data,
      );

      if (kDebugMode) {
        print('Version creation response: ${response.statusCode} ${response.data}');
      }

      if (response.statusCode == 201) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final version = RoadmapVersion.fromJson(jsonData['data']);
          return ApiResult.success(data: version);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to create roadmap version',
          );
        }
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to create roadmap version',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error creating roadmap version: ${e.message}');
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
        print('Error creating roadmap version: $e');
      }
      return ApiResult.failure(error: e.toString());
    }
  }

  @override
  Future<ApiResult<RoadmapVersion>> updateRoadmapVersion(
      String uuid, Map<String, dynamic> data) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.put(
        '$_baseUrl/roadmap-versions/$uuid',
        data: data,
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final version = RoadmapVersion.fromJson(jsonData['data']);
          return ApiResult.success(data: version);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to update roadmap version',
          );
        }
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to update roadmap version',
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
  Future<ApiResult<bool>> deleteRoadmapVersion(String uuid) async {
    try {
      final dio = _httpService.client(requireAuth: true);
      final response = await dio.delete('$_baseUrl/roadmap-versions/$uuid');

      if (response.statusCode == 200) {
        return const ApiResult.success(data: true);
      } else {
        return ApiResult.failure(
          error: response.data['message'] ?? 'Failed to delete roadmap version',
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
  Future<ApiResult<List<RoadmapVersion>>> fetchVersionsByStatus(
      String appId, String status) async {
    try {
      // Build query parameters
      final queryParams = <String, dynamic>{
        'app_id': appId,
        'status': status,
      };

      final dio = _httpService.client(requireAuth: true);
      final response = await dio.get(
        '$_baseUrl/roadmap-versions',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final jsonData = response.data;
        if (jsonData['success'] == true && jsonData['data'] != null) {
          final List<dynamic> versionsJson = jsonData['data'];
          final versions = versionsJson
              .map((versionJson) => RoadmapVersion.fromJson(versionJson))
              .toList();

          // Sort versions by version number (descending - newest first)
          versions.sort((a, b) => _compareVersions(b.versionNumber, a.versionNumber));

          return ApiResult.success(data: versions);
        } else {
          return ApiResult.failure(
            error: jsonData['message'] ?? 'Failed to load versions by status',
          );
        }
      } else {
        return ApiResult.failure(
          error: 'Failed to load versions by status. Status: ${response.statusCode}',
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

  // Compare version numbers (e.g., "1.2.3" > "1.2.0")
  int _compareVersions(String version1, String version2) {
    final List<int> v1Parts = version1.split('.').map(int.parse).toList();
    final List<int> v2Parts = version2.split('.').map(int.parse).toList();

    // Pad shorter version with zeros
    while (v1Parts.length < v2Parts.length) {
      v1Parts.add(0);
    }
    while (v2Parts.length < v1Parts.length) {
      v2Parts.add(0);
    }

    // Compare each segment
    for (int i = 0; i < v1Parts.length; i++) {
      if (v1Parts[i] > v2Parts[i]) return 1;
      if (v1Parts[i] < v2Parts[i]) return -1;
    }

    return 0; // Versions are equal
  }
}
