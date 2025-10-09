import 'package:admin_desktop/src/models/response/product_calculate_response.dart';
import 'package:admin_desktop/src/core/handlers/handlers.dart';
import 'package:admin_desktop/src/models/models.dart';

abstract class ProductsRepository {
  Future<ApiResult<ProductsPaginateResponse>> getProductsPaginate({
    String? query,
    int? categoryId,
    int? brandId,
    int? shopId,
    required int page,
  });

  Future<ApiResult<SingleProductResponse>> updateStocks({
    required List<Stocks> stocks,
    required List<int> deletedStocks,
    String? uuid,
    bool isAddon = false,
  });

  Future<ApiResult<SingleProductResponse>> getProductDetails(String uuid);

  Future<ApiResult<ProductCalculateResponse>> getAllCalculations(
      List<BagProductData> bagProducts,
      String type, {
        String? coupon,
      });
}
