import '../../../../../../../../core/handlers/handlers.dart';
import '../models/roadmap_version.dart';

abstract class RoadmapRepository {
  Future<ApiResult<List<RoadmapVersion>>> fetchRoadmapVersions(String? appId);
  Future<ApiResult<RoadmapVersion>> getRoadmapVersion(String uuid);
  Future<ApiResult<RoadmapVersion>> createRoadmapVersion(Map<String, dynamic> data);
  Future<ApiResult<RoadmapVersion>> updateRoadmapVersion(String uuid, Map<String, dynamic> data);
  Future<ApiResult<bool>> deleteRoadmapVersion(String uuid);
  Future<ApiResult<List<RoadmapVersion>>> fetchVersionsByStatus(String appId, String status);
}
