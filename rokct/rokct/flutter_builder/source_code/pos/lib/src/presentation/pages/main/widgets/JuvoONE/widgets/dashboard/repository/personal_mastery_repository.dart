import '../../../../../../../../core/handlers/handlers.dart';
import '../models/personal_mastery_goal.dart';

abstract class PersonalMasteryRepository {
  Future<ApiResult<List<PersonalMasteryGoal>>> fetchPersonalMasteryGoals(int? userId);
  Future<ApiResult<PersonalMasteryGoal>> getPersonalMasteryGoal(String uuid);
  Future<ApiResult<PersonalMasteryGoal>> createPersonalMasteryGoal(Map<String, dynamic> data);
  Future<ApiResult<PersonalMasteryGoal>> updatePersonalMasteryGoal(String uuid, Map<String, dynamic> data);
  Future<ApiResult<bool>> deletePersonalMasteryGoal(String uuid);
  Future<ApiResult<List<PersonalMasteryGoal>>> fetchGoalsByArea(int? userId, String area);
  Future<ApiResult<List<PersonalMasteryGoal>>> fetchGoalsByStatus(int? userId, String status);
}
