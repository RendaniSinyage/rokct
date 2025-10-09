import 'package:admin_desktop/src/core/constants/constants.dart';

import 'package:admin_desktop/src/core/handlers/api_result.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../models/response/gallery_upload_response.dart';

abstract class GalleryRepositoryFacade {
  Future<ApiResult<GalleryUploadResponse>> uploadImage(
      String file,
      UploadType uploadType,
      );

  Future<ApiResult<MultiGalleryUploadResponse>> uploadMultiImage(
      List<String?> filePaths,
      UploadType uploadType,
      );
}

