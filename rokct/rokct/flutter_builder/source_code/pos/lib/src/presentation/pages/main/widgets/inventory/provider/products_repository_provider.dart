import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_desktop/src/repository/repository.dart';

final productsRepositoryProvider = Provider<ProductsRepository>((ref) {
  return ProductsRepositoryImpl();
});
