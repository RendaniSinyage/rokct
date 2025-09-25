import 'package:flutter/material.dart';
import 'package:foodyman/domain/di/dependency_manager.dart';
import 'package:foodyman/infrastructure/models/data/login.dart';
import 'package:foodyman/infrastructure/models/request/sign_up_request.dart';
import 'package:foodyman/domain/handlers/handlers.dart';
import 'package:foodyman/domain/interface/auth.dart';
import 'package:foodyman/infrastructure/services/app_helpers.dart';
import 'package:foodyman/infrastructure/services/app_validators.dart';
import '../models/models.dart';

class AuthRepository implements AuthRepositoryFacade {
  @override
  Future<ApiResult<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      // NOTE: Frappe's core login endpoint is `/api/method/login`
      final response = await client.post(
        '/api/method/login',
        data: {
          'usr': email,
          'pwd': password,
        },
      );
      // Assuming a successful login returns user data that can be adapted to LoginResponse
      // This part will need careful adaptation based on the actual Frappe response
      return ApiResult.success(
        data: LoginResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> login failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<RegisterResponse>> sendOtp({required String phone}) async {
    final data = {'phone': phone.replaceAll('+', "")};
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.post(
        '/api/method/rokct.paas.api.send_phone_verification_code',
        data: data,
      );
      // The response from this endpoint is simple, may need to adjust RegisterResponse model
      return ApiResult.success(data: RegisterResponse.fromJson(response.data));
    } catch (e) {
      debugPrint('==> send otp failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<VerifyPhoneResponse>> verifyEmail({
    required String verifyCode,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/method/rokct.paas.api.verify_my_email',
        queryParameters: {'token': verifyCode},
      );
      return ApiResult.success(
          data: VerifyPhoneResponse.fromJson(response.data));
    } catch (e) {
      debugPrint('==> verify email failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<VerifyPhoneResponse>> verifyPhone({
    required String phone,
    required String otp,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.post(
        '/api/method/rokct.paas.api.verify_phone_code',
        data: {
          "phone": phone,
          "otp": otp,
        },
      );
      return ApiResult.success(
          data: VerifyPhoneResponse.fromJson(response.data));
    } catch (e) {
      debugPrint('==> verify phone failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.post(
        '/api/method/rokct.paas.api.forgot_password',
        data: {'user': email},
      );
      return ApiResult.success(data: response.data);
    } catch (e) {
      debugPrint('==> forgot password failure: $e');
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  @override
  Future<ApiResult<LoginResponse>> sigUpWithData({required UserModel user}) async {
    try {
      final client = dioHttp.client(requireAuth: false);
      var res = await client.post(
        '/api/method/rokct.paas.api.register_user',
        data: user.toJsonForSignUp(),
      );
      // This response will not contain tokens, adaptation needed
      return ApiResult.success(
        data: LoginResponse.fromJson(res.data),
      );
    } catch (e) {
      return ApiResult.failure(
        error: AppHelpers.errorHandler(e),
        statusCode: NetworkExceptions.getDioStatus(e),
      );
    }
  }

  // NOTE: The following methods are not supported by the new backend and have been removed.
  // - loginWithGoogle
  // - forgotPasswordConfirm
  // - forgotPasswordConfirmWithPhone
  // - sigUp
  // - sigUpWithPhone

  // Placeholder for unimplemented methods from the interface
  @override
  Future<ApiResult<VerifyData>> forgotPasswordConfirm({required String verifyCode, required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<VerifyData>> forgotPasswordConfirmWithPhone({required String phone}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<LoginResponse>> loginWithGoogle({required String email, required String displayName, required String id, required String avatar}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult> sigUp({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<ApiResult<VerifyData>> sigUpWithPhone({required UserModel user}) {
    throw UnimplementedError();
  }
}