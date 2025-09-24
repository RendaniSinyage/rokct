import 'package:admin_desktop/src/core/handlers/handlers.dart';
import '../models/response/stories_response.dart';

abstract class StoriesRepository {
  Future<ApiResult<StoriesResponse>> getStories({
    int? page,
  });

  Future<ApiResult<void>> deleteStories(int id);

  Future<ApiResult> createStories({required List<String> img, int? id});

  Future<ApiResult> updateStories({
    required List<String> img,
    int? id,
    required int storyId,
  });
}

