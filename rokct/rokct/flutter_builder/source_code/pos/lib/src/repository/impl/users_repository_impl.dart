import 'dart:convert';

import 'package:admin_desktop/src/core/routes/app_router.dart';
import 'package:admin_desktop/src/models/data/customer_model.dart';
import 'package:admin_desktop/src/models/response/edit_profile.dart';
import 'package:admin_desktop/src/models/response/profile_response.dart';
import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:admin_desktop/src/core/constants/tr_keys.dart';
import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../../models/response/delivery_zone_paginate.dart';
import '../repository.dart';

class UsersRepositoryImpl extends UsersRepository {
  @override
  Future<ApiResult<UsersPaginateResponse>> searchUsers({
    String? query,
    String? role,
    String? inviteStatus,
    int? page,
  }) async {
    final data = {
      if (query != null) 'search': query,
      'limit_start': (page ?? 1) - 1 * 14,
      'limit_page_length': 14,
      if (role != null) 'role': role,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_shop_users',
        queryParameters: data,
      );
      return ApiResult.success(
        data: UsersPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> search users failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> getProfileDetails(
      BuildContext context) async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_user_profile',
      );
      return ApiResult.success(
        data: ProfileResponse.fromJson(response.data),
      );
    } catch (e) {
      if ((e as DioException).type == DioExceptionType.badResponse &&
          e.response?.statusCode == 401) {
        if (context.mounted) {
          context.replaceRoute(const LoginRoute());
          LocalStorage.clearStore();
        }
      }
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<void>> updateDeliveryZones({
    required List<LatLng> points,
  }) async {
    final data = {
      'coordinates': points.map((e) => {'latitude': e.latitude, 'longitude': e.longitude}).toList(),
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.create_seller_delivery_zone',
        data: {'zone_data': data},
      );
      return const ApiResult.success(data: null);
    } catch (e) {
      debugPrint('==> update delivery zones failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<DeliveryZonePaginate>> getDeliveryZone() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_seller_delivery_zones',
      );
      return ApiResult.success(
        data: DeliveryZonePaginate.fromJson(response.data),
      );
    } catch (e, s) {
      debugPrint('===> error get delivery zone $e');
      debugPrint('===> error get delivery zone $s');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<bool>> checkDriverZone(LatLng location, int? shopId) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final data = {
        'latitude': location.latitude,
        'longitude': location.longitude,
        if (shopId != null) 'shop_id': shopId,
      };

      final response = await client.get(
          '/api/v1/method/rokct.paas.api.check_delivery_zone',
          queryParameters: data);

      return ApiResult.success(
        data: response.data["status"] == "success",
      );
    } catch (e) {
      debugPrint('==> get delivery zone failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
      );
    }
  }

  @override
  Future<ApiResult> checkCoupon({
    required String coupon,
    required int shopId,
  }) async {
    final data = {
      'code': coupon,
      'shop_id': shopId,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      await client.post(
        '/api/v1/method/rokct.paas.api.check_coupon',
        data: data,
      );
      return const ApiResult.success(data: true);
    } catch (e) {
      debugPrint('==> check coupon failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
      );
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> editProfile(
      {required EditProfile? user}) async {
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
      );
    }
  }

  @override
  Future<ApiResult<ProfileResponse>> createUser(
      {required CustomerModel query}) async {
    final data = query.toJson();
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.post(
        '/api/v1/method/rokct.paas.api.create_user',
        data: data,
      );
      return ApiResult.success(
        data: ProfileResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> create user failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
      );
    }
  }

  @override
  Future<ApiResult<UsersPaginateResponse>> getUsers({int? page}) async {
    final data = {
      'limit_start': (page ?? 1) - 1 * 6,
      'limit_page_length': 6,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
          '/api/v1/method/rokct.paas.api.get_all_users',
          queryParameters: data);
      return ApiResult.success(
        data: UsersPaginateResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get users failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  // NOTE: The following methods are not supported or relevant for the POS app.
  // - searchDeliveryman
  // - getUserDetails
  // - updatePassword
  // - updateProfileImage
  // - updateStatus

  @override
  Future<ApiResult<UsersPaginateResponse>> searchDeliveryman(String? query) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<SingleUserResponse>> getUserDetails(String uuid) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<ProfileResponse>> updatePassword({required String password, required String passwordConfirmation}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<ProfileResponse>> updateProfileImage({required String firstName, required String imageUrl}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult> updateStatus({required int? id, required String status}) {
    throw UnimplementedError();
  }
}