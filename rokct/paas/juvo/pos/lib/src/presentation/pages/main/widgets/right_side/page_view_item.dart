import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';

import '../../../../../../generated/assets.dart';
import '../../../../../core/constants/constants.dart';
import '../../../../../core/utils/utils.dart';
import '../../../../../models/data/addons_data.dart';
import '../../../../../models/models.dart';
import '../../../../components/components.dart';
import '../../../../theme/app_style.dart';
import '../../../../theme/theme.dart';
import 'promo_code_dialog.dart';
import 'note_dialog.dart';
import 'order_information.dart';
import 'riverpod/right_side_provider.dart';
import 'riverpod/right_side_state.dart';
//import 'package:admin_desktop/src/presentation/components/list_items/product_bag_item.dart';

class PageViewItem extends ConsumerStatefulWidget {
  final BagData bag;
  final VoidCallback onAddItem;
  final VoidCallback onRemoveItem;

  const PageViewItem({
    super.key,
    required this.bag,
    required this.onAddItem,
    required this.onRemoveItem,
  });

  @override
  ConsumerState<PageViewItem> createState() => _PageViewItemState();
}

class _PageViewItemState extends ConsumerState<PageViewItem> {
  late TextEditingController coupon;
  bool _showAllItems = false;

  @override
  void initState() {
    super.initState();
    coupon = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      ref
          .read(rightSideProvider.notifier)
          .setInitialBagData(context, widget.bag);
    });
  }

  @override
  void dispose() {
    coupon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(rightSideProvider.notifier);
    final state = ref.watch(rightSideProvider);
    return AbsorbPointer(
      absorbing: state.isUserDetailsLoading ||
          state.isPaymentsLoading ||
          state.isBagsLoading ||
          state.isUsersLoading ||
          state.isCurrenciesLoading ||
          state.isProductCalculateLoading,
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    color: AppStyle.white,
                  ),
                  child: (state.paginateResponse?.stocks?.isNotEmpty ?? false)
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(
                                top: 8.r,
                                right: 24.r,
                                left: 24.r,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppHelpers.getTranslation(TrKeys.products),
                                    style: GoogleFonts.inter(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500,
                                        color: AppStyle.black),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      notifier.clearBag();
                                      widget.onRemoveItem();
                                    },
                                    child: Padding(
                                      padding: EdgeInsets.all(8.r),
                                      child: const Icon(
                                        FlutterRemix.delete_bin_line,
                                        color: AppStyle.red,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(),
                            _buildItemList(state),
                            8.verticalSpace,
                            Column(
                              children: [
                                Padding(
                                  padding:
                                      REdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    children: [
                                      Text(
                                        AppHelpers.getTranslation(TrKeys.add),
                                        style: GoogleFonts.inter(
                                            color: AppStyle.black,
                                            fontSize: 14.sp),
                                      ),
                                      const Spacer(),
                                      InkWell(
                                        onTap: () {
                                          AppHelpers.showAlertDialog(
                                              context: context,
                                              child: const PromoCodeDialog());
                                        },
                                        child: AnimationButtonEffect(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10.r,
                                                horizontal: 18.r),
                                            decoration: BoxDecoration(
                                                color: AppStyle.red
                                                    .withOpacity(0.4),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10.r)),
                                            child: Text(
                                              AppHelpers.getTranslation(
                                                  TrKeys.promoCode),
                                              style: GoogleFonts.inter(
                                                  fontSize: 14.sp,
                                                  color: AppStyle.black),
                                            ),
                                          ),
                                        ),
                                      ),
                                      26.horizontalSpace,
                                      InkWell(
                                        onTap: () {
                                          AppHelpers.showAlertDialog(
                                              context: context,
                                              child: const NoteDialog());
                                        },
                                        child: AnimationButtonEffect(
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 10.r,
                                                horizontal: 18.r),
                                            decoration: BoxDecoration(
                                                color: AppConstants
                                                        .enableJuvoONE
                                                    ? AppStyle.blueBonus
                                                    : AppStyle.addButtonColor,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        10.r)),
                                            child: Text(
                                              AppHelpers.getTranslation(
                                                  TrKeys.note),
                                              style: GoogleFonts.inter(
                                                  fontSize: 14.sp,
                                                  color: AppStyle.black),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _price(state),
                              ],
                            ),
                            28.verticalSpace,
                          ],
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            170.verticalSpace,
                            Container(
                              width: 142.r,
                              height: 142.r,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.r),
                                color: AppStyle.dontHaveAccBtnBack,
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
                              '${AppHelpers.getTranslation(TrKeys.thereAreNoItemsInThe)} ${AppHelpers.getTranslation(TrKeys.bag).toLowerCase()}',
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -14 * 0.02,
                                color: AppStyle.black,
                              ),
                            ),
                            SizedBox(height: 170.r, width: double.infinity),
                          ],
                        ),
                ),
                15.verticalSpace,
              ],
            ),
          ),
          BlurLoadingWidget(
            isLoading: state.isUserDetailsLoading ||
                state.isPaymentsLoading ||
                state.isBagsLoading ||
                state.isUsersLoading ||
                state.isCurrenciesLoading ||
                state.isProductCalculateLoading,
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(RightSideState state) {
    final items = state.paginateResponse?.stocks ?? [];
    final itemCount = items.length;
    final displayCount = _showAllItems ? itemCount : min(3, itemCount);

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: displayCount,
          itemBuilder: (context, index) {
            if (index == 2 && itemCount > 3 && !_showAllItems) {
              return _buildViewMoreButton(itemCount - 2);
            }
            return CartOrderItem(
              symbol: widget.bag.selectedCurrency?.symbol,
              add: () {
                ref
                    .read(rightSideProvider.notifier)
                    .increaseProductCount(productIndex: index);
                widget.onAddItem();
              },
              remove: () {
                ref
                    .read(rightSideProvider.notifier)
                    .decreaseProductCount(productIndex: index);
                widget.onRemoveItem();
              },
              cart: items[index],
              delete: () {
                ref.read(rightSideProvider.notifier).deleteProductCount(
                      bagProductData: state
                          .bags[state.selectedBagIndex].bagProducts?[index],
                      productIndex: index,
                    );
                widget.onRemoveItem();
              },
            );
          },
        ),
        if (_showAllItems && itemCount > 3) _buildViewLessButton(),
      ],
    );
  }

  Widget _buildViewMoreButton(int remainingCount) {
    return InkWell(
      onTap: () {
        setState(() {
          _showAllItems = true;
        });
      },
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View $remainingCount more item${remainingCount > 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppStyle.blue,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down,
              color: AppStyle.blue,
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewLessButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _showAllItems = false;
        });
      },
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'View less',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: AppStyle.blue,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_up,
              color: AppStyle.blue,
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }

  Column _price(RightSideState state) {
    final itemCount = state.paginateResponse?.stocks?.length ?? 0;
    final showAllFees = itemCount <= 2;

    // Always calculate the total price including all fees
    final totalPrice = (state.paginateResponse?.price ?? 0) +
        (state.paginateResponse?.totalTax ?? 0) +
        (state.paginateResponse?.serviceFee ?? 0) +
        (state.paginateResponse?.deliveryFee ?? 0) -
        (state.paginateResponse?.totalDiscount ?? 0) -
        (state.paginateResponse?.couponPrice ?? 0);

    return Column(
      children: [
        8.verticalSpace,
        const Divider(),
        8.verticalSpace,
        Padding(
          padding: REdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              if (showAllFees)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.subtotal),
                          style: GoogleFonts.inter(
                            color: AppStyle.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            symbol: widget.bag.selectedCurrency?.symbol ??
                                LocalStorage.getSelectedCurrency().symbol,
                          ).format(state.paginateResponse?.price ?? 0),
                          style: GoogleFonts.inter(
                            color: AppStyle.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    20.verticalSpace,
                  ],
                ),
              if (showAllFees || (state.paginateResponse?.totalTax ?? 0) != 0)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.tax),
                          style: GoogleFonts.inter(
                            color: AppStyle.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          NumberFormat.currency(
                            symbol: widget.bag.selectedCurrency?.symbol ??
                                LocalStorage.getSelectedCurrency().symbol,
                          ).format(state.paginateResponse?.totalTax ?? 0),
                          style: GoogleFonts.inter(
                            color: AppStyle.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    20.verticalSpace,
                  ],
                ),
              if (showAllFees || (state.paginateResponse?.serviceFee ?? 0) != 0)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.serviceFee),
                          style: GoogleFonts.inter(
                            color: AppStyle.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          AppHelpers.numberFormat(
                              state.paginateResponse?.serviceFee,
                              symbol: widget.bag.selectedCurrency?.symbol),
                          style: GoogleFonts.inter(
                            color: AppStyle.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    20.verticalSpace,
                  ],
                ),
              if ((showAllFees ||
                      (state.paginateResponse?.deliveryFee ?? 0) != 0) &&
                  state.paginateResponse?.deliveryFee != null)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.deliveryFee),
                          style: GoogleFonts.inter(
                            color: AppStyle.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          AppHelpers.numberFormat(
                              state.paginateResponse?.deliveryFee,
                              symbol: widget.bag.selectedCurrency?.symbol),
                          style: GoogleFonts.inter(
                            color: AppStyle.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    20.verticalSpace,
                  ],
                ),
              if (showAllFees ||
                  (state.paginateResponse?.totalDiscount ?? 0) != 0)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.discount),
                          style: GoogleFonts.inter(
                            color: AppStyle.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          "-${NumberFormat.currency(
                            symbol: widget.bag.selectedCurrency?.symbol ??
                                LocalStorage.getSelectedCurrency().symbol,
                          ).format(state.paginateResponse?.totalDiscount ?? 0)}",
                          style: GoogleFonts.inter(
                            color: AppStyle.red,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    20.verticalSpace,
                  ],
                ),
              if (state.paginateResponse?.couponPrice != 0)
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.promoCode),
                          style: GoogleFonts.inter(
                            color: AppStyle.black,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          "-${NumberFormat.currency(
                            symbol: widget.bag.selectedCurrency?.symbol ??
                                LocalStorage.getSelectedCurrency().symbol,
                          ).format(state.paginateResponse?.couponPrice ?? 0)}",
                          style: GoogleFonts.inter(
                            color: AppStyle.red,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ],
                    ),
                    20.verticalSpace,
                  ],
                ),
            ],
          ),
        ),
        8.verticalSpace,
        const Divider(),
        8.verticalSpace,
        Padding(
          padding: REdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppHelpers.getTranslation(TrKeys.totalPrice),
                    style: GoogleFonts.inter(
                      color: AppStyle.black,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(
                      symbol: widget.bag.selectedCurrency?.symbol ??
                          LocalStorage.getSelectedCurrency().symbol,
                    ).format(totalPrice),
                    style: GoogleFonts.inter(
                      color: AppStyle.black,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
              24.verticalSpace,
              LoginButton(
                isLoading: state.isButtonLoading,
                title: AppHelpers.getTranslation(TrKeys.order),
                titleColor: AppStyle.black,
                onPressed: () {
                  AppHelpers.showAlertDialog(
                      context: context, child: OrderInformation());
                },
              )
            ],
          ),
        ),
      ],
    );
  }
}

class CartOrderItem extends StatelessWidget {
  final ProductData? cart;
  final String? symbol;
  final VoidCallback add;
  final VoidCallback remove;
  final VoidCallback delete;
  final bool isActive;
  final bool isOwn;

  const CartOrderItem({
    super.key,
    required this.add,
    required this.remove,
    required this.cart,
    required this.delete,
    this.isActive = true,
    this.isOwn = true,
    required this.symbol,
  });

  @override
  Widget build(BuildContext context) {
    num sumPrice = 0;
    num disSumPrice = 0;
    for (Addons e in (cart?.addons ?? [])) {
      disSumPrice += (e.price ?? 0);
    }
    disSumPrice = (cart?.totalPrice ?? 0) + (cart?.discount ?? 0);
    sumPrice += (cart?.totalPrice ?? 0);
    return Slidable(
      endActionPane: ActionPane(
        extentRatio: 0.12,
        motion: const ScrollMotion(),
        children: [
          Expanded(
            child: Builder(
              builder: (context) {
                return GestureDetector(
                  onTap: () {
                    Slidable.of(context)?.close();
                    delete.call();
                  },
                  child: Container(
                    width: 50.r,
                    height: 72.r,
                    decoration: BoxDecoration(
                      color: AppStyle.red,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(16.r),
                        bottomLeft: Radius.circular(16.r),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      FlutterRemix.close_fill,
                      color: AppStyle.black,
                      size: 24.r,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      child: Column(
        children: [
          isActive
              ? Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppStyle.white,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.r),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      text: cart
                                          ?.stock?.product?.translation?.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        color: AppStyle.black,
                                      ),
                                      children: [
                                        if (cart?.stock?.extras?.isNotEmpty ??
                                            false)
                                          TextSpan(
                                            text:
                                                " (${cart?.stock?.extras?.first.value ?? ""})",
                                            style: GoogleFonts.inter(
                                              fontSize: 14.sp,
                                              color: AppStyle.hint,
                                            ),
                                          )
                                      ],
                                    ),
                                  ),
                                  8.verticalSpace,
                                  for (Addons e in (cart?.addons ?? []))
                                    Text(
                                      "${e.product?.translation?.title ?? ""} ( ${NumberFormat.currency(
                                        symbol: symbol ??
                                            LocalStorage.getSelectedCurrency()
                                                .symbol,
                                      ).format((e.price ?? 0) / (e.quantity ?? 1))} x ${(e.quantity ?? 1)} )",
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: AppStyle.unselectedTab,
                                      ),
                                    ),
                                  16.verticalSpace,
                                ],
                              ),
                            ),
                          ),
                          4.horizontalSpace,
                          (cart?.stock?.bonus != null)
                              ? Positioned(
                                  bottom: 4.r,
                                  right: 4.r,
                                  child: Container(
                                    width: 22.w,
                                    height: 22.h,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppStyle.blue,
                                    ),
                                    child: Icon(
                                      FlutterRemix.gift_2_fill,
                                      size: 14.r,
                                      color: AppStyle.white,
                                    ),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              vertical: 10.h,
                              horizontal: 16.w,
                            ),
                            decoration: BoxDecoration(
                              color: AppStyle.brandGreen,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(10.r),
                                bottomRight: Radius.circular(10.r),
                              ),
                            ),
                            child: Text(
                              "${(cart?.quantity ?? 1).toString()}x",
                              style: GoogleFonts.inter(
                                fontSize: 14.sp,
                                color: AppStyle.black,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          24.horizontalSpace,
                          GestureDetector(
                            onTap: remove,
                            child: AnimationButtonEffect(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppStyle.brandGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(10.r),
                                    bottomLeft: Radius.circular(10.r),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 25.w,
                                  ),
                                  child: const Icon(
                                    Icons.remove,
                                    color: AppStyle.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          4.horizontalSpace,
                          GestureDetector(
                            onTap: add,
                            child: AnimationButtonEffect(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppStyle.brandGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(10.r),
                                    bottomRight: Radius.circular(10.r),
                                  ),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 8.h,
                                    horizontal: 25.w,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: AppStyle.black,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          !(cart?.stock?.bonus != null)
                              ? Column(
                                  children: [
                                    Text(
                                      AppHelpers.numberFormat(
                                        (cart?.discount ?? 0) != 0
                                            ? disSumPrice
                                            : sumPrice,
                                      ),
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: (cart?.discount ?? 0) != 0
                                            ? 12.sp
                                            : 16.sp,
                                        color: AppStyle.black,
                                        decoration: (cart?.discount ?? 0) != 0
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                      ),
                                    ),
                                    (cart?.discount ?? 0) != 0
                                        ? Container(
                                            margin: EdgeInsets.only(top: 8.r),
                                            decoration: BoxDecoration(
                                              color: AppStyle.red,
                                              borderRadius:
                                                  BorderRadius.circular(30.r),
                                            ),
                                            padding: EdgeInsets.all(4.r),
                                            child: Row(
                                              children: [
                                                SvgPicture.asset(
                                                    "assets/svg/discount.svg"),
                                                4.horizontalSpace,
                                                Text(
                                                  NumberFormat.currency(
                                                    symbol: symbol ??
                                                        LocalStorage
                                                                .getSelectedCurrency()
                                                            .symbol,
                                                  ).format(sumPrice),
                                                  style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14.sp,
                                                    color: AppStyle.white,
                                                  ),
                                                )
                                              ],
                                            ),
                                          )
                                        : const SizedBox.shrink()
                                  ],
                                )
                              : const SizedBox.shrink(),
                          16.horizontalSpace,
                        ],
                      ),
                    ],
                  ),
                )
              : Container(
                  margin: EdgeInsets.only(bottom: 8.h),
                  padding: EdgeInsets.all(16.r),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppStyle.white,
                    borderRadius: BorderRadius.all(
                      Radius.circular(10.r),
                    ),
                    border: Border.all(color: AppStyle.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    text: cart
                                        ?.stock?.product?.translation?.title,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: AppStyle.black,
                                    ),
                                    children: [
                                      if (cart?.stock?.extras?.isNotEmpty ??
                                          false)
                                        TextSpan(
                                          text:
                                              " (${cart?.stock?.extras?.first.value ?? ""})",
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            color: AppStyle.hint,
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                                8.verticalSpace,
                                for (Addons e in (cart?.addons ?? []))
                                  Text(
                                    "${e.product?.translation?.title ?? ""} ( ${NumberFormat.currency(
                                      symbol: symbol ??
                                          LocalStorage.getSelectedCurrency()
                                              .symbol,
                                    ).format((e.price ?? 0) / (e.quantity ?? 1))} x ${(e.quantity ?? 1)} )",
                                    style: GoogleFonts.inter(
                                      fontSize: 13.sp,
                                      color: AppStyle.black,
                                    ),
                                  ),
                                8.verticalSpace,
                                Row(
                                  children: [
                                    Text(
                                      "${NumberFormat.currency(
                                        symbol: symbol ??
                                            LocalStorage.getSelectedCurrency()
                                                .symbol,
                                      ).format((cart?.totalPrice ?? 1) / (cart?.quantity ?? 1))} X ${cart?.quantity ?? 1}",
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: AppStyle.black,
                                      ),
                                    ),
                                    const Spacer(),
                                    !(cart?.stock?.bonus != null)
                                        ? Column(
                                            children: [
                                              Text(
                                                NumberFormat.currency(
                                                  symbol: symbol ??
                                                      LocalStorage
                                                              .getSelectedCurrency()
                                                          .symbol,
                                                ).format(
                                                    (cart?.discount ?? 0) != 0
                                                        ? disSumPrice
                                                        : sumPrice),
                                                style: GoogleFonts.inter(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize:
                                                        (cart?.discount ?? 0) !=
                                                                0
                                                            ? 12
                                                            : 16,
                                                    color: AppStyle.black,
                                                    decoration:
                                                        (cart?.discount ?? 0) !=
                                                                0
                                                            ? TextDecoration
                                                                .lineThrough
                                                            : TextDecoration
                                                                .none),
                                              ),
                                              (cart?.discount ?? 0) != 0
                                                  ? Container(
                                                      margin: EdgeInsets.only(
                                                          top: 8.r),
                                                      decoration: BoxDecoration(
                                                          color: AppStyle.red,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      30.r)),
                                                      padding:
                                                          EdgeInsets.all(4.r),
                                                      child: Row(
                                                        children: [
                                                          SvgPicture.asset(
                                                              "assets/svg/discount.svg"),
                                                          4.horizontalSpace,
                                                          Text(
                                                            NumberFormat
                                                                .currency(
                                                              symbol: symbol ??
                                                                  LocalStorage
                                                                          .getSelectedCurrency()
                                                                      .symbol,
                                                            ).format(sumPrice),
                                                            style: GoogleFonts.inter(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                fontSize: 14.sp,
                                                                color: AppStyle
                                                                    .white),
                                                          )
                                                        ],
                                                      ),
                                                    )
                                                  : const SizedBox.shrink()
                                            ],
                                          )
                                        : const SizedBox.shrink(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          4.horizontalSpace,
                          Stack(
                            children: [
                              CommonImage(
                                  imageUrl: cart?.stock?.product?.img ?? "",
                                  width: 100,
                                  height: 100,
                                  radius: 10.r),
                              (cart?.stock?.bonus != null)
                                  ? Positioned(
                                      bottom: 4.r,
                                      right: 4.r,
                                      child: Container(
                                        width: 22.w,
                                        height: 22.h,
                                        decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppStyle.blue),
                                        child: Icon(
                                          FlutterRemix.gift_2_fill,
                                          size: 16.r,
                                          color: AppStyle.white,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
          isActive ? const Divider() : const SizedBox.shrink(),
        ],
      ),
    );
  }
}

