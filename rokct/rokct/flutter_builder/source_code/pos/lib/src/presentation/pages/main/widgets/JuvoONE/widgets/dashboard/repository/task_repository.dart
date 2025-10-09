import '../../../../../../../../core/handlers/handlers.dart';
import '../models/todo_task.dart';

abstract class TaskRepository {
  Future<ApiResult<List<TodoTask>>> fetchTasks(
      String? shopId, {
        String? kpiId,
        String? objectiveId,
        String? appId,
      });

  Future<ApiResult<TodoTask>> getTask(String uuid);
  Future<ApiResult<TodoTask>> createTask(Map<String, dynamic> data);
  Future<ApiResult<TodoTask>> updateTask(String uuid, Map<String, dynamic> data);
  Future<ApiResult<bool>> deleteTask(String uuid);
}
