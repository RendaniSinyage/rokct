import 'package:flutter/material.dart';
import 'package:foodyman/domain/di/dependency_manager.dart';
import 'package:foodyman/domain/interface/user.dart';
import 'package:foodyman/infrastructure/models/data/address_new_data.dart';
import 'package:foodyman/infrastructure/models/models.dart';
import 'package:foodyman/infrastructure/models/request/edit_profile.dart';
import 'package:foodyman/infrastructure/services/app_helpers.dart';
import 'package:foodyman/domain/handlers/handlers.dart';
import 'package:foodyman/infrastructure/services/local_storage.dart';

class UserRepository implements UserRepositoryFacade {
  @override
  Future<ApiResult<ProfileResponse>> getProfileDetails() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get('/api/v1/method/rokct.paas.api.get_user_profile');
      return ApiResult.success(
        data: ProfileResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get user details failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> saveLocation({required AddressNewModel? address}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post('/api/v1/method/rokct.paas.api.add_user_address',
          data: address?.toJson());
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> updateLocation({
    required AddressNewModel? address,
    required int? addressId,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.put(
        '/api/v1/method/rokct.paas.api.update_user_address',
        data: {
          'name': addressId,
          'address_data': address?.toJson(),
        },
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> deleteAddress({required int id}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.delete_user_address',
        data: {'name': id},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> logoutAccount({required String fcm}) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post('/api/v1/method/rokct.paas.api.logout');
      LocalStorage.logout();
      return const ApiResult.success(data: null);
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> editProfile({required EditProfile? user}) async {
    final data = user?.toJson();
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.put(
        '/api/v1/method/rokct.paas.api.update_user_profile',
        data: {'profile_data': data},
      );
      return ApiResult.success(
        data: ProfileResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> update profile details failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<WalletHistoriesResponse>> getWalletHistories(int page) async {
    final data = {
      'limit_start': (page - 1) * 10,
      'limit_page_length': 10,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_wallet_history',
        queryParameters: data,
      );
      return ApiResult.success(
        data: WalletHistoriesResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get wallet histories failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<void>> updateFirebaseToken(String? token) async {
    final data = {
      'device_token': token,
      'provider': 'fcm', // Assuming FCM
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.register_device_token',
        data: data,
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update firebase token failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // NOTE: The following methods are not supported by the new backend.
  // - getReferralDetails
  // - setActiveAddress
  // - deleteAccount
  // - updateProfileImage
  // - updatePassword
  // - searchUser

  @override
  Future<ApiResult<ReferralModel>> getReferralDetails() {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult> setActiveAddress({required int id}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult> deleteAccount() {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<ProfileResponse>> updateProfileImage({required String firstName, required String imageUrl}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<ProfileResponse>> updatePassword({required String password, required String passwordConfirmation}) {
    throw UnimplementedError();
  }

  @override
  Future<dynamic> searchUser({required String name, required int page}) {
    throw UnimplementedError();
  }
}