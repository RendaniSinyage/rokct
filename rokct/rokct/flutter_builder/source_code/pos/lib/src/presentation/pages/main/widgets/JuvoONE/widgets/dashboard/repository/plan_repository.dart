
import '../../../../../../../../core/handlers/handlers.dart';
import '../models/vision.dart';

abstract class PlanRepository {
  Future<ApiResult<Vision>> createVision(Map<String, dynamic> data);
  Future<ApiResult<Vision>> updateVision(String uuid, Map<String, dynamic> data);
  Future<ApiResult<Vision>> getPlanOnPage(String? shopId);
  Future<ApiResult<dynamic>> createPillar(Map<String, dynamic> data);
  Future<ApiResult<dynamic>> updatePillar(String uuid, Map<String, dynamic> data);
  Future<ApiResult<dynamic>> createStrategicObjective(Map<String, dynamic> data);
  Future<ApiResult<dynamic>> updateStrategicObjective(String uuid, Map<String, dynamic> data);
  Future<ApiResult<dynamic>> createKpi(Map<String, dynamic> data);
  Future<ApiResult<dynamic>> updateKpi(String uuid, Map<String, dynamic> data);
}
