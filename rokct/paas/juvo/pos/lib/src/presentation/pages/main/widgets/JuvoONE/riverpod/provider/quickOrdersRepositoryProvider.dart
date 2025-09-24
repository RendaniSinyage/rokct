import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../core/di/dependency_manager.dart';
import '../../../../../../../repository/repository.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return getIt.get<OrdersRepository>();
});
