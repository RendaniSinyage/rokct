import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/models/models.dart';

abstract class CurrenciesRepository {
  Future<ApiResult<CurrenciesResponse>> getCurrencies();
}

