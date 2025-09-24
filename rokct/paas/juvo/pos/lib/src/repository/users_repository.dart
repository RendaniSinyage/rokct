import 'package:admin_desktop/src/models/data/customer_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../models/response/delivery_zone_paginate.dart';
import '../models/response/edit_profile.dart';
import '../models/response/profile_response.dart';

abstract class UsersRepository {
  Future<ApiResult<UsersPaginateResponse>> searchUsers({
    String? query,
    String? role,
    String? inviteStatus,
    int? page,
  });
  Future<ApiResult<UsersPaginateResponse>> searchDeliveryman(String? query);

  Future<ApiResult<SingleUserResponse>> getUserDetails(String uuid);

  Future<ApiResult<ProfileResponse>> getProfileDetails(BuildContext context);

  Future<ApiResult<void>> updateDeliveryZones({
    required List<LatLng> points,
  });

  Future<ApiResult<DeliveryZonePaginate>> getDeliveryZone();

  Future<ApiResult<bool>> checkDriverZone(LatLng location, int? shopId);

  Future<ApiResult> checkCoupon({
    required String coupon,
    required int shopId,
  });

  Future<ApiResult<ProfileResponse>> editProfile({required EditProfile? user});

  Future<ApiResult<ProfileResponse>> updateProfileImage({
    required String firstName,
    required String imageUrl,
  });

  Future<ApiResult<ProfileResponse>> updatePassword({
    required String password,
    required String passwordConfirmation,
  });

  Future<ApiResult<UsersPaginateResponse>> getUsers({int? page});

  Future<ApiResult<ProfileResponse>> createUser({required CustomerModel query});

  Future<ApiResult> updateStatus({
    required int? id,
    required String status,
  });
}

