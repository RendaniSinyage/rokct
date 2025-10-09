import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:foodyman/domain/di/dependency_manager.dart';
import 'package:foodyman/domain/interface/gallery.dart';
import 'package:foodyman/infrastructure/models/models.dart';
import 'package:foodyman/domain/handlers/handlers.dart';
import 'package:foodyman/infrastructure/services/app_helpers.dart';

class GalleryRepository implements GalleryRepositoryFacade {
  @override
  Future<ApiResult<GalleryUploadResponse>> uploadImage(
    String file,
    String docType,
    String docName,
  ) async {
    final data = FormData.fromMap(
      {
        'file': await MultipartFile.fromFile(file),
        'doctype': docType,
        'docname': docName,
        'is_private': 0,
      },
    );
    try {
      final client = dioHttp.client(requireAuth: true);
      // NOTE: Using Frappe's standard file upload method
      final response = await client.post(
        '/api/v1/method/upload_file',
        data: data,
      );
      // The response will contain the file URL, which needs to be saved
      // to the appropriate document in a separate API call.
      return ApiResult.success(
        data: GalleryUploadResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> upload image failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // NOTE: The `uploadMultiImage` method is no longer needed, as multiple
  // images can be uploaded by calling `uploadImage` multiple times.
  @override
  Future<ApiResult<MultiGalleryUploadResponse>> uploadMultiImage(
    List<String?> filePaths,
    UploadType uploadType,
  ) {
    throw UnimplementedError();
  }
}