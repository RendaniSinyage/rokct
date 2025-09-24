import 'package:admin_desktop/src/models/response/income_statistic_response.dart';
import 'package:admin_desktop/src/models/response/sale_cart_response.dart';

import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../models/response/income_cart_response.dart';
import '../models/response/income_chart_response.dart';
import '../models/response/sale_history_response.dart';

abstract class SettingsRepository {
  Future<ApiResult<GlobalSettingsResponse>> getGlobalSettings();

  Future<ApiResult<TranslationsResponse>> getTranslations();

  Future<ApiResult<SaleHistoryResponse>> getSaleHistory(int type,int page);

  Future<ApiResult<SaleCartResponse>> getSaleCart();

  Future<ApiResult<IncomeCartResponse>> getIncomeCart(
      {required String type,required DateTime? from,required DateTime? to});

  Future<ApiResult<IncomeStatisticResponse>> getIncomeStatistic(
      {required String type,required DateTime? from,required DateTime? to});

  Future<ApiResult<List<IncomeChartResponse>>> getIncomeChart(
      {required String type,required DateTime? from,required DateTime? to});

   Future<ApiResult<LanguagesResponse>> getLanguages();

  Future<ApiResult<MobileTranslationsResponse>> getMobileTranslations({String? lang});

  Future<ApiResult<HelpModel>> getFaq();

}

