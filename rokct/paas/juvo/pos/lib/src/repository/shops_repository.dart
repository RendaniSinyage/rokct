import 'package:multi_dropdown/models/value_item.dart';

import 'package:admin_desktop/src/core/handlers/handlers.dart';
import '../models/data/edit_shop_data.dart';
import 'package:admin_desktop/src/models/models.dart';

abstract class ShopsRepository {
  Future<ApiResult<ShopsPaginateResponse>> searchShops(String? query);

  Future<ApiResult<ShopsPaginateResponse>> getShopsByIds(
    List<int> shopIds,
  );
  Future<ApiResult<EditShopData>> getShopData();

  Future<ApiResult<CategoriesPaginateResponse>> getShopCategory();

  Future<ApiResult<CategoriesPaginateResponse>> getShopTag();

  Future<ApiResult<EditShopData>> updateShopData({
    required EditShopData editShopData,
    required String logoImg,
    required String backImg,
    List<ValueItem>? category,
    List<ValueItem>? tag,
    List<ValueItem>? type,
    String? displayName
  });

  Future<ApiResult<void>> updateShopWorkingDays({
    required List<ShopWorkingDays> workingDays,
    String? uuid,
  });

  Future<ApiResult<ShopDeliveriesResponse>> getOnlyDeliveries();

  Future<ApiResult<ShopData>> getShopDataById(int shopId);
}

