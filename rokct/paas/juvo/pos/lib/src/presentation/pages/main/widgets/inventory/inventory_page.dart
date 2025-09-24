import 'package:admin_desktop/src/models/models.dart';
import 'package:admin_desktop/src/presentation/components/custom_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../../core/constants/constants.dart';
import '../../../../../core/utils/utils.dart';
import '../../../../components/components.dart';
import '../../../../theme/theme.dart';
import '../../riverpod/provider/main_provider.dart';
import '../JuvoONE/components/stock_edit_dialog.dart';

class InventoryPage extends ConsumerWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final state = ref.watch(mainProvider);
    final notifier = ref.read(mainProvider.notifier);
    return CustomScaffold(
      body: (c) => Padding(
        padding: REdgeInsets.symmetric(horizontal: 15),
        child: Column(
          children: [
            15.verticalSpace,
            const InventoryHeader(),
            10.verticalSpace,
            CategoryTabs(
              categories: state.categories,
              selectedCategory: state.selectedCategory,
              onCategorySelected: (index) {
                notifier.setSelectedCategory(context, index);
              },
            ),
            10.verticalSpace,
            Expanded(child: InventoryList()),
          ],
        ),
      ),
    );
  }
}

class CategoryTabs extends StatelessWidget {
  final List<CategoryData> categories;
  final CategoryData? selectedCategory;
  final Function(int) onCategorySelected;

  const CategoryTabs({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.r),
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      height: 56.h,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 2,
        itemBuilder: (context, index) {
          return index == 0
              ? Padding(
            padding: EdgeInsets.only(right: 6.r),
            child: Icon(Remix.equalizer_2_fill, color: AppStyle.black),
          )
              : index == 1
              ? CategoryTabItem(
            isActive: selectedCategory?.id == null,
            onTap: () => onCategorySelected(-1),
            title: AppHelpers.getTranslation(TrKeys.all),
          )
              : CategoryTabItem(
            isActive: categories[index - 2].id == selectedCategory?.id,
            onTap: () => onCategorySelected(index - 2),
            title: categories[index - 2].translation?.title,
          );
        },
      ),
    );
  }
}

class CategoryTabItem extends StatelessWidget {
  final String? title;
  final bool isActive;
  final VoidCallback onTap;

  const CategoryTabItem({
    super.key,
    this.title,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 36.r,
        decoration: BoxDecoration(
          color: isActive ? AppStyle.primary : AppStyle.white,
          borderRadius: BorderRadius.circular(10.r),
          boxShadow: [
            BoxShadow(
              color: AppStyle.white.withOpacity(0.07),
              spreadRadius: 0,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        alignment: Alignment.center,
        padding: REdgeInsets.symmetric(horizontal: 18),
        margin: REdgeInsets.only(right: 8),
        child: Text(
          '$title',
          style: GoogleFonts.inter(
            fontSize: 13.sp,
            color: isActive ? AppStyle.white : AppStyle.black,
          ),
        ),
      ),
    );
  }
}

class InventoryHeader extends ConsumerWidget {
  const InventoryHeader({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return SizedBox.shrink();
  }
}

class InventoryList extends ConsumerWidget {
  const InventoryList({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final state = ref.watch(mainProvider);
    final notifier = ref.read(mainProvider.notifier);

    if (state.isProductsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.products.isEmpty) {
      return Center(
        child: Text(
          'No products found',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            color: AppStyle.black,
          ),
        ),
      );
    }

    // Sort products by stock quantity (lowest first)
    final sortedProducts = List<ProductData>.from(state.products)
      ..sort((a, b) {
        final aStock = a.stocks?.firstOrNull?.quantity ?? 0;
        final bStock = b.stocks?.firstOrNull?.quantity ?? 0;
        return aStock.compareTo(bStock);
      });

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 12.r),
          color: AppStyle.white,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text('Product', style: _headerStyle()),
              ),
              Expanded(
                flex: 1,
                child: Text('Stock', style: _headerStyle()),
              ),
              Expanded(
                flex: 1,
                child: Text('Price', style: _headerStyle()),
              ),
              SizedBox(width: 50.w),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sortedProducts.length,
            itemBuilder: (context, index) {
              final product = sortedProducts[index];
              return _InventoryListItem(
                product: product,
                index: index,
                onStockTap: () {
                  _showStockEditDialog(context, product);
                },
              );
            },
          ),
        ),
        if (state.hasMore)
          TextButton(
            onPressed: () {
              notifier.fetchProducts(
                checkYourNetwork: () {
                  AppHelpers.showSnackBar(
                    context,
                    AppHelpers.getTranslation(TrKeys.checkYourNetworkConnection),
                  );
                },
              );
            },
            child: Text(
              'Load More',
              style: GoogleFonts.inter(fontSize: 16.sp),
            ),
          ),
      ],
    );
  }

  TextStyle _headerStyle() {
    return GoogleFonts.inter(
      fontSize: 16.sp,
      fontWeight: FontWeight.w600,
      color: AppStyle.black,
    );
  }

  void _showStockEditDialog(BuildContext context, ProductData product) {
    AppHelpers.showAlertDialog(
      context: context,
      backgroundColor: AppStyle.white,
      width: 400.w,
      child: StockEditDialog(
        product: product,
        stock: product.stocks?.firstOrNull,
      ),
    );
  }
}

class _InventoryListItem extends StatelessWidget {
  final ProductData product;
  final VoidCallback onStockTap;
  final int index;

  const _InventoryListItem({
    required this.product,
    required this.onStockTap,
    required this.index,
  });

  void _showStockEditDialog(BuildContext context) {
    AppHelpers.showAlertDialog(
      context: context,
      backgroundColor: AppStyle.white,
      width: 400.w,
      child: StockEditDialog(
        product: product,
        stock: product.stocks?.firstOrNull,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stock = product.stocks?.firstOrNull;
    final stockQuantity = stock?.quantity ?? 0;
    final isOutOfStock = stock == null || stockQuantity <= 0;
    final isLowStock = !isOutOfStock && stockQuantity < 10;
    final isEvenRow = index % 2 == 0;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 12.r),
          color: isEvenRow ? AppStyle.primary.withOpacity(0.05) : AppStyle.shimmerBase.withOpacity(0.2),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    SizedBox(
                      width: 48.r,
                      height: 48.r,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.r),
                        child: CommonImage(
                          imageUrl: product.img,
                          height: 48,
                          width: 48,
                          isResponsive: true,
                        ),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.translation?.title ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w500,
                              color: AppStyle.black,
                            ),
                          ),
                          Text(
                            product.translation?.description ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              color: AppStyle.shimmerHighlightDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: onStockTap,
                  child: Text(
                    isOutOfStock ? 'Out of stock' : '$stockQuantity',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      color: isOutOfStock ? AppStyle.red : AppStyle.black,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  AppHelpers.numberFormat(stock?.price ?? 0),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: AppStyle.black,
                  ),
                ),
              ),
              Container(
                width: 50.w,
                decoration: BoxDecoration(
                  color: isOutOfStock ? AppStyle.red : (isLowStock ? AppStyle.orange : AppStyle.transparent),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: IconButton(
                  icon: Icon(
                    Remix.more_2_fill,
                    size: 24.r,
                    color: isOutOfStock ? AppStyle.white : (isLowStock ? AppStyle.black : AppStyle.textGrey),
                  ),
                  onPressed: () => _showStockEditDialog(context),
                ),
              ),
            ],
          ),
        ),
        Divider(color: AppStyle.white, height: 2),
      ],
    );
  }
}


