// Import the HttpService
import '../../../../../../../../app_constants.dart';
import '../../../../../../../core/handlers/handlers.dart';
import '../../../../../../../models/data/order_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Define the provider
final waterosOrdersProvider = StateNotifierProvider<WaterosOrdersNotifier, AsyncValue<List<OrderData>>>((ref) {
  return WaterosOrdersNotifier();
});

// Define the notifier
class WaterosOrdersNotifier extends StateNotifier<AsyncValue<List<OrderData>>> {
  WaterosOrdersNotifier() : super(const AsyncValue.loading());

  Future<void> fetchOrders([int? shopId]) async {
    try {
      // Update state to loading, but keep previous data if any
      state = AsyncValue.loading();

      // Build URL with shop_id parameter if provided
      String url = '${AppConstants.baseUrl}api/v1/dashboard/admin/orders';
      if (shopId != null) {
        url = '$url?shop_id=$shopId';
      }

      final httpService = HttpService();
      final dio = httpService.client(requireAuth: true);
      final res = await dio.get(url);

      if (res.statusCode! >= 200 && res.statusCode! < 300) {
        List<OrderData> orders = [];
        for (var order in res.data['data']) {
          orders.add(OrderData.fromJson(order));
        }
        state = AsyncValue.data(orders);
      } else {
        state = AsyncValue.error(
            res.statusMessage ?? 'Unknown error',
            StackTrace.current
        );
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}
