import 'package:admin_desktop/generated/assets.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/add_product/add_product_dialog.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/utils.dart';
import '../../../components/components.dart';
import '../../../theme/app_style.dart';
import '../riverpod/provider/main_provider.dart';
import '../../../../models/models.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/add_product/provider/add_product_provider.dart';
import 'right_side/riverpod/right_side_provider.dart';

// Extension method to check stock status
extension ProductStockStatus on ProductData {
  bool get isOutOfStock {
    return stocks == null ||
        stocks!.isEmpty ||
        stocks!.first.quantity == null ||
        stocks!.first.quantity! <= 0;
  }

  bool get isLowStock {
    if (isOutOfStock) return false;
    return stocks!.first.quantity! < 10;
  }

  // Get priority for sorting (0 highest, 2 lowest)
  int get stockPriority {
    if (isOutOfStock) return 0;
    if (isLowStock) return 1;
    return 2;
  }
}

// Sort products by stock status
List<ProductData> sortProductsByStock(List<ProductData> products) {
  return List<ProductData>.from(products)
    ..sort((a, b) {
      // First compare by stock priority
      final priorityComparison = a.stockPriority.compareTo(b.stockPriority);
      if (priorityComparison != 0) return priorityComparison;

      // If priorities are equal, maintain original order
      return products.indexOf(a).compareTo(products.indexOf(b));
    });
}

class ProductsList extends ConsumerWidget {
  const ProductsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mainProvider);
    final notifier = ref.read(mainProvider.notifier);
    final rightSideState = ref.watch(rightSideProvider);
    final rightSideNotifier = ref.read(rightSideProvider.notifier);
    final addProductNotifier = ref.read(addProductProvider.notifier);

    void handleProductTap(ProductData product, bool isDoubleTap) {
      // Check if the product is out of stock
      if (product.isOutOfStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${product.translation?.title ?? 'This product'} is out of stock'),
          ),
        );
        return;
      }

      if (product.stocks?.first.extras?.isEmpty ?? true) {
        final selectedBag = rightSideState.bags[rightSideState.selectedBagIndex];
        final existingProductIndex = selectedBag.bagProducts
            ?.indexWhere((p) => p.stockId == product.stocks?.first.id) ??
            -1;

        if (existingProductIndex != -1) {
          // Product exists, increase quantity
          rightSideNotifier.increaseProductCount(
              productIndex: existingProductIndex);
        } else {
          // Product doesn't exist, add as new
          addProductNotifier.setProduct(
            product,
            rightSideState.selectedBagIndex,
          );
          addProductNotifier.addProductToBag(
            context,
            rightSideState.selectedBagIndex,
            rightSideNotifier,
          );
        }
      } else {
        // If the product has extras, show the AddProductDialog
        showDialog(
          context: context,
          builder: (context) {
            return AddProductDialog(product: product);
          },
        );
      }
    }

    return state.isProductsLoading
        ? const ProductGridListShimmer()
        : state.products.isNotEmpty
        ? ScrollConfiguration(
      behavior:
      ScrollConfiguration.of(context).copyWith(dragDevices: {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      }),
      child: ListView(
        shrinkWrap: false,
        cacheExtent: (state.products.length / 4) * 250,
        children: [
          AnimationLimiter(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              primary: false,
              itemCount: state.products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                childAspectRatio: 200 / 300,
                mainAxisSpacing: 10.r,
                crossAxisSpacing: 10.r,
                crossAxisCount: 4,
              ),
              padding: REdgeInsets.only(top: 8, bottom: 10),
              itemBuilder: (context, index) {
                // Get sorted products
                final sortedProducts = sortProductsByStock(state.products);
                final product = sortedProducts[index];

                return AnimationConfiguration.staggeredGrid(
                  columnCount: sortedProducts.length,
                  position: index,
                  duration: const Duration(milliseconds: 375),
                  child: ScaleAnimation(
                    scale: 0.5,
                    child: FadeInAnimation(
                      child: GestureDetector(
                        onTap: product.isOutOfStock
                            ? null
                            : () => handleProductTap(product, false),
                        onDoubleTap: product.isOutOfStock
                            ? null
                            : () => handleProductTap(product, true),
                        child: Opacity(
                          opacity: product.isOutOfStock ? 0.5 : 1.0,
                          child: ProductGridItem(
                            product: product,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          10.verticalSpace,
          state.isMoreProductsLoading
              ? const ProductGridListShimmer(verticalPadding: 0)
              : (state.hasMore
              ? Material(
            borderRadius: BorderRadius.circular(10.r),
            color: AppStyle.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(10.r),
              onTap: () {
                notifier.fetchProducts(
                  checkYourNetwork: () {
                    AppHelpers.showSnackBar(
                      context,
                      AppHelpers.getTranslation(
                          TrKeys.checkYourNetworkConnection
                      ),
                    );
                  },
                );
              },
              child: Container(
                height: 50.r,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(
                    color: AppStyle.black.withOpacity(0.17),
                    width: 1.r,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  AppHelpers.getTranslation(TrKeys.viewMore),
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    color: AppStyle.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
              : const SizedBox()),
          15.verticalSpace,
        ],
      ),
    )
        : Padding(
      padding: EdgeInsets.only(left: 64.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          170.verticalSpace,
          Container(
            width: 142.r,
            height: 142.r,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: AppStyle.white,
            ),
            alignment: Alignment.center,
            child: Image.asset(
              Assets.pngNoProducts,
              width: 87.r,
              height: 60.r,
              fit: BoxFit.cover,
            ),
          ),
          14.verticalSpace,
          Text(
            '${AppHelpers.getTranslation(TrKeys.thereAreNoItemsInThe)} ${AppHelpers.getTranslation(TrKeys.products).toLowerCase()}',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: -14 * 0.02,
              color: AppStyle.black,
            ),
          ),
        ],
      ),
    );
  }
}
