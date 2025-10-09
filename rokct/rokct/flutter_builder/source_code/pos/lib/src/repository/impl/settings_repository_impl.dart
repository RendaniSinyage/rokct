import 'dart:convert';

import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/models/response/income_chart_response.dart';
import 'package:admin_desktop/src/models/response/income_statistic_response.dart';
import 'package:admin_desktop/src/models/response/sale_cart_response.dart';
import 'package:flutter/material.dart';

import 'package:admin_desktop/src/core/di/dependency_manager.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../../models/response/income_cart_response.dart';
import '../../models/response/sale_history_response.dart';
import '../repository.dart';

class SettingsSettingsRepositoryImpl extends SettingsRepository {
  @override
  Future<ApiResult<GlobalSettingsResponse>> getGlobalSettings() async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get('/api/v1/method/rokct.paas.api.get_global_settings');
      debugPrint('==> get global settings response: $response');
      return ApiResult.success(
        data: GlobalSettingsResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get settings failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<MobileTranslationsResponse>> getMobileTranslations(
      {String? lang}) async {
    final data = {'lang': lang ?? LocalStorage.getLanguage()?.locale ?? 'en'};
    try {
      final dioHttp = HttpService();
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_mobile_translations',
        queryParameters: data,
      );
      await LocalStorage.setTranslations(
          MobileTranslationsResponse.fromJson(response.data).data);
      return  ApiResult.success(data: MobileTranslationsResponse.fromJson(response.data));
    } catch (e) {
      debugPrint('==> get translations failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<TranslationsResponse>> getTranslations() async {
    try {
      final client = dioHttp.client(requireAuth: false);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_all_translations',
      );
      return ApiResult.success(
        data: TranslationsResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get translations failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<SaleHistoryResponse>> getSaleHistory(
      int type, int page) async {
    final data = {
      'type': type == 0
          ? "deliveryman"
          : type == 1
              ? "today"
              : "history",
      "perPage": 10,
      "page": page,
    };
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_seller_sales_report',
        queryParameters: data,
      );
      return ApiResult.success(
        data: SaleHistoryResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get sale history failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<SaleCartResponse>> getSaleCart() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
        '/api/v1/method/rokct.paas.api.get_seller_statistics',
      );
      return ApiResult.success(
        data: SaleCartResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get sale cart failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }


  @override
  Future<ApiResult<IncomeStatisticResponse>> getIncomeStatistic(
      {required String type,
        required DateTime? from,
        required DateTime? to}) async {
    try {
      final data = {
        "type": type,
        "date_from": from.toString().substring(0, from.toString().indexOf(" ")),
        "date_to": to.toString().substring(0, to.toString().indexOf(" "))
      };
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
          '/api/v1/method/rokct.paas.api.get_seller_statistics',
          queryParameters: data);
      return ApiResult.success(
        data: IncomeStatisticResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get sale statistic failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<IncomeCartResponse>> getIncomeCart(
      {required String type,
      required DateTime? from,
      required DateTime? to}) async {
    try {
      final data = {
        "type": type,
        "date_from": from.toString().substring(0, from.toString().indexOf(" ")),
        "date_to": to.toString().substring(0, to.toString().indexOf(" "))
      };
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get(
          '/api/v1/method/rokct.paas.api.get_seller_statistics',
          queryParameters: data);
      return ApiResult.success(
        data: IncomeCartResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get sale cart failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<List<IncomeChartResponse>>> getIncomeChart(
      {required String type,
      required DateTime? from,
      required DateTime? to}) async {
    try {
      final data = {
        "type": type == TrKeys.week ? TrKeys.month : type,
        "date_from": from.toString().substring(0, from.toString().indexOf(" ")),
        "date_to": to.toString().substring(0, to.toString().indexOf(" "))
      };
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get('/api/v1/method/rokct.paas.api.get_seller_statistics',
          queryParameters: data);
      return ApiResult.success(
        data: incomeChartResponseFromJson(jsonEncode(response.data)),
      );
    } catch (e) {
      debugPrint('==> get sale cart failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }

  @override
  Future<ApiResult<LanguagesResponse>> getLanguages() async {
    try {
      final client = HttpService().client(requireAuth: false);
      final response = await client.get('/api/v1/method/rokct.paas.api.get_languages');
      if (LocalStorage.getLanguage() == null ||
          !(LanguagesResponse.fromJson(response.data)
              .data
              ?.map((e) => e.id)
              .contains(LocalStorage.getLanguage()?.id) ??
              true)) {
        LanguagesResponse.fromJson(response.data).data?.forEach((element) {
          if (element.isDefault ?? false) {
            LocalStorage.setLanguageData(element);
            LocalStorage.setLangLtr(element.backward);
          }
        });
      }
      return ApiResult.success(
        data: LanguagesResponse.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get languages failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }
  @override
  Future<ApiResult<HelpModel>> getFaq() async {
    try {
      final client = dioHttp.client(requireAuth: true);
      final response = await client.get('/api/v1/method/rokct.paas.api.get_faqs');
      return ApiResult.success(
        data: HelpModel.fromJson(response.data),
      );
    } catch (e) {
      debugPrint('==> get faq failure: $e');
      return ApiResult.failure(error: AppHelpers.errorHandler(e));
    }
  }
}