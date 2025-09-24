// repository/app_repository.dart
import '../../../../../../../../core/handlers/handlers.dart';
import '../models/app.dart';

abstract class AppRepository {
  Future<ApiResult<List<App>>> fetchApps(String? shopId);
  Future<ApiResult<App>> getApp(String uuid);
  Future<ApiResult<App>> createApp(Map<String, dynamic> data);
  Future<ApiResult<App>> updateApp(String uuid, Map<String, dynamic> data);
  Future<ApiResult<bool>> deleteApp(String uuid);
}
