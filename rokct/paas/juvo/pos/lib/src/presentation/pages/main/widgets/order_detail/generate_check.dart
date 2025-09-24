// ignore_for_file: depend_on_referenced_packages

import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/core/utils/time_service.dart';
import 'package:admin_desktop/src/models/data/addons_data.dart';
import 'package:admin_desktop/src/models/data/order_data.dart';
import 'package:admin_desktop/src/presentation/components/components.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/order_detail/print_page.dart';
import 'package:admin_desktop/src/core/utils/local_storage.dart';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/theme.dart';

class GenerateCheckPage extends StatefulWidget {
  final OrderData? orderData;

  const GenerateCheckPage({super.key, required this.orderData});

  @override
  State<GenerateCheckPage> createState() => _GenerateCheckPageState();
}

class _GenerateCheckPageState extends State<GenerateCheckPage> {
  @override
  Widget build(BuildContext context) {
    num subTotal = 0;
    subTotal = ((widget.orderData?.totalPrice ?? 0) -
        (widget.orderData?.tax ?? 0) -
        (widget.orderData?.deliveryFee ?? 0) +
        (widget.orderData?.totalDiscount ?? 0));

    // Get current user safely
    final currentUser = LocalStorage.getUser();
    final currentUserName = currentUser?.firstname ?? "";

    // Get order user safely
    final orderUser = widget.orderData?.user;
    final orderUserName = orderUser?.firstname ?? "";

    // Show client row if either:
    // 1. Current user is logged in and different from order user
    // 2. Order has a user but current user is not logged in
    final shouldShowClientRow = (currentUser != null && orderUser != null &&
        currentUserName != orderUserName) ||
        (currentUser == null && orderUser != null);

    return Container(
      decoration: BoxDecoration(
          color: AppStyle.white, borderRadius: BorderRadius.circular(10.r)),
      padding: EdgeInsets.all(16.r),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              AppHelpers.getTranslation(TrKeys.orderSummary),
              style: GoogleFonts.inter(
                  fontSize: 22.sp, fontWeight: FontWeight.w600,
                  color: AppStyle.black),
            ),
            8.verticalSpace,
            Text(
              "№${widget.orderData?.id}",
              style: GoogleFonts.inter(
                  fontSize: 16.sp, fontWeight: FontWeight.w500,
                  color: AppStyle.black),
            ),
            12.verticalSpace,
            Row(
              children: List.generate(
                  20,
                      (index) => Expanded(
                    child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.r),
                        height: 2,
                        color: AppStyle.iconButtonBack),
                  )),
            ),
            12.verticalSpace,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 100.w,
                  child: Text(
                    AppHelpers.getTranslation(TrKeys.shopName),
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, fontWeight: FontWeight.w500,
                        color: AppStyle.black),
                  ),
                ),
                Text(
                  widget.orderData?.shop?.translation?.title ?? "",
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w400,
                      color: AppStyle.black),
                )
              ],
            ),
            8.verticalSpace,
            if (shouldShowClientRow) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 100.w,
                    child: Text(
                      AppHelpers.getTranslation(TrKeys.client),
                      style: GoogleFonts.inter(
                          fontSize: 14.sp, fontWeight: FontWeight.w500,
                          color: AppStyle.black),
                    ),
                  ),
                  Text(
                    "${orderUser?.firstname ?? ""} ${orderUser?.lastname ?? ""}",
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, fontWeight: FontWeight.w400,
                        color: AppStyle.black),
                  )
                ],
              ),
              8.verticalSpace,
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 80.w,
                  child: Text(
                    AppHelpers.getTranslation(TrKeys.date),
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, fontWeight: FontWeight.w500,
                        color: AppStyle.black),
                  ),
                ),
                Text(
                  TimeService.dateFormatYMDHm(widget.orderData?.createdAt),
                  style: GoogleFonts.inter(
                      fontSize: 12.sp, fontWeight: FontWeight.w400,
                      color: AppStyle.black),
                )
              ],
            ),
            10.verticalSpace,
            Divider(
              thickness: 2.r,
            ),
            ListView.builder(
                padding: EdgeInsets.only(top: 16.r),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: widget.orderData?.details?.length ?? 0,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.r),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${widget.orderData?.details?[index].stock?.product?.translation?.title ?? ""} x ${widget.orderData?.details?[index].quantity ?? ""}",
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14.sp,
                                        color: AppStyle.black),
                                  ),
                                  6.verticalSpace,
                                  for (Addons e in (widget
                                      .orderData?.details?[index].addons ??
                                      []))
                                    Text(
                                      "${e.stocks?.product?.translation?.title ?? ""} ( ${AppHelpers.numberFormat(
                                        (e.price ?? 0) / (e.quantity ?? 1),
                                        symbol: widget
                                            .orderData?.currency?.symbol ??
                                            "",
                                      )} x ${(e.quantity ?? 1)} )",
                                      style: GoogleFonts.inter(
                                        fontSize: 14.sp,
                                        color: AppStyle.unselectedTab,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              AppHelpers.numberFormat(
                                widget.orderData?.details?[index].totalPrice ?? 0,
                                symbol: widget.orderData?.currency?.symbol,
                              ),
                              style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14.sp,
                                  color: AppStyle.black),
                            )
                          ],
                        ),
                        10.verticalSpace,
                        Row(
                          children: List.generate(
                              20,
                                  (index) => Expanded(
                                child: Container(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 4.r),
                                    height: 2,
                                    color: AppStyle.iconButtonBack),
                              )),
                        )
                      ],
                    ),
                  );
                }),
            Row(
              children: List.generate(
                  20,
                      (index) => Expanded(
                    child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.r),
                        height: 2,
                        color: AppStyle.iconButtonBack),
                  )),
            ),
            20.verticalSpace,
            Row(
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.subtotal),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w500,
                      color: AppStyle.black),
                ),
                const Spacer(),
                Text(
                  AppHelpers.numberFormat(
                    subTotal,
                  ),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w400,
                      color: AppStyle.black),
                )
              ],
            ),
            10.verticalSpace,
            Row(
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.tax),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w500,
                      color: AppStyle.black),
                ),
                const Spacer(),
                Text(
                  AppHelpers.numberFormat(
                    widget.orderData?.tax ?? 0,
                  ),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w400,
                      color: AppStyle.black),
                )
              ],
            ),
            10.verticalSpace,
            Row(
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.deliveryFee),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w500,
                      color: AppStyle.black),
                ),
                const Spacer(),
                Text(
                  AppHelpers.numberFormat(
                    widget.orderData?.deliveryFee ?? 0,
                  ),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w400,
                      color: AppStyle.black),
                )
              ],
            ),
            10.verticalSpace,
            Row(
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.discount),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w500,
                      color: AppStyle.black),
                ),
                const Spacer(),
                Text(
                  AppHelpers.numberFormat(
                    widget.orderData?.totalDiscount ?? 0,
                  ),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w400,
                      color: AppStyle.black),
                )
              ],
            ),
            10.verticalSpace,
            Row(
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.totalPrice),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w700,
                      color: AppStyle.black),
                ),
                const Spacer(),
                Text(
                  AppHelpers.numberFormat(
                    widget.orderData?.totalPrice ?? 0,
                  ),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp, fontWeight: FontWeight.w400,
                      color: AppStyle.black),
                )
              ],
            ),
            10.verticalSpace,
            Row(
              children: List.generate(
                  20,
                      (index) => Expanded(
                    child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.r),
                        height: 2,
                        color: AppStyle.iconButtonBack),
                  )),
            ),
            26.verticalSpace,
            Text(
              AppHelpers.getTranslation(TrKeys.thankYou).toUpperCase(),
              style: GoogleFonts.inter(
                  fontSize: 16.sp, fontWeight: FontWeight.w500,
                  color: AppStyle.black),
            ),
            24.verticalSpace,
            LoginButton(
                title: AppHelpers.getTranslation(TrKeys.print),
                onPressed: () async {
                  if (context.mounted) {
                    AppHelpers.showAlertDialog(
                        context: context,
                        child: PrintPage(orderData: widget.orderData));
                  }
                })
          ],
        ),
      ),
    );
  }
}
