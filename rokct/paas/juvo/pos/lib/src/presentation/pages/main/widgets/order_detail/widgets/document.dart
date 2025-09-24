import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/time_service.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:admin_desktop/src/models/data/order_data.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../../components/components.dart';
import '../../../../../theme/app_style.dart';

class DocumentScreen extends StatelessWidget {
  final OrderData? orderData;

  const DocumentScreen({super.key, required this.orderData});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppStyle.border),
      ),
      padding: EdgeInsets.symmetric(vertical: 20.r, horizontal: 16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedBorderTextField(
                  readOnly: true,
                  label: null,
                  textController: TextEditingController(
                      text:
                          "${orderData?.user?.firstname ?? ""} ${orderData?.user?.lastname ?? ""}"),
                  suffixIcon: const Icon(FlutterRemix.arrow_down_s_line,
                      color: AppStyle.black),
                ),
              ),
              42.horizontalSpace,
              Expanded(
                child: OutlinedBorderTextField(
                  readOnly: true,
                  textController: TextEditingController(
                      text: orderData?.orderAddress?.address ?? ""),
                  label: null,
                  suffixIcon: const Icon(FlutterRemix.arrow_down_s_line,
                      color: AppStyle.black),
                ),
              ),
            ],
          ),
          12.verticalSpace,
          Row(
            children: [
              Expanded(
                child: OutlinedBorderTextField(
                  readOnly: true,
                  textController: TextEditingController(
                      text:
                          "${orderData?.currency?.title ?? ""} (${orderData?.currency?.symbol ?? ""})"),
                  label: null,
                  suffixIcon: const Icon(FlutterRemix.arrow_down_s_line,
                      color: AppStyle.black),
                ),
              ),
              42.horizontalSpace,
              Expanded(
                child: OutlinedBorderTextField(
                  readOnly: true,
                  textController: TextEditingController(
                      text: AppHelpers.getTranslation(
                          orderData?.transaction?.paymentSystem?.tag ?? "")),
                  label: null,
                  suffixIcon: const Icon(FlutterRemix.arrow_down_s_line,
                      color: AppStyle.black),
                ),
              ),
            ],
          ),
          8.verticalSpace,
          const Divider(),
          8.verticalSpace,
          Text(
            AppHelpers.getTranslation(TrKeys.shippingInformation),
            style:
                GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18.r,
                    color: AppStyle.black),
          ),
          16.verticalSpace,
          _paymentType(),
          16.verticalSpace,
          Row(
            children: [
              Expanded(
                child: OutlinedBorderTextField(
                  readOnly: true,
                  textController: TextEditingController(
                    text: TimeService.dateFormatYMDHm(orderData?.deliveryDate),
                  ),
                  label: null,
                  suffixIcon: const Icon(FlutterRemix.arrow_down_s_line,
                      color: AppStyle.black),
                ),
              ),
              42.horizontalSpace,
              Expanded(
                child: OutlinedBorderTextField(
                  readOnly: true,
                  textController: TextEditingController(
                      text: orderData?.deliveryTime ?? ""),
                  label: null,
                  suffixIcon: const Icon(FlutterRemix.arrow_down_s_line,
                      color: AppStyle.black),
                ),
              ),
            ],
          ),
          16.verticalSpace,
          if (orderData?.note != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.note),
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600, fontSize: 18.r,
                      color: AppStyle.black),
                ),
                Text(
                  orderData?.note ?? '',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 16.r,
                      color: AppStyle.reviewText),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Row _paymentType() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: orderData?.deliveryType == TrKeys.delivery
                  ? AppStyle.primary
                  : AppStyle.editProfileCircle,
              borderRadius: BorderRadius.circular(6.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 10.r),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppStyle.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppStyle.black),
                    ),
                    padding: EdgeInsets.all(6.r),
                    child: Icon(
                      FlutterRemix.takeaway_fill,
                      size: 18.sp,
                      color: AppStyle.black,
                    ),
                  ),
                  8.horizontalSpace,
                  Text(
                    AppHelpers.getTranslation(TrKeys.delivery),
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, fontWeight: FontWeight.w600,
                        color: AppStyle.black),
                  )
                ],
              ),
            ),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: orderData?.deliveryType == TrKeys.pickup
                  ? AppStyle.primary
                  : AppStyle.editProfileCircle,
              borderRadius: BorderRadius.circular(6.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 10.r),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppStyle.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppStyle.black),
                    ),
                    padding: EdgeInsets.all(6.r),
                    child: const Icon(Remix.walk_fill,
                    color: AppStyle.black),
                  ),
                  8.horizontalSpace,
                  Text(
                    AppHelpers.getTranslation(TrKeys.takeAway),
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, fontWeight: FontWeight.w600,
                        color: AppStyle.black),
                  )
                ],
              ),
            ),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: orderData?.deliveryType == TrKeys.dine
                  ? AppStyle.primary
                  : AppStyle.editProfileCircle,
              borderRadius: BorderRadius.circular(6.r),
            ),
            padding: EdgeInsets.symmetric(vertical: 10.r),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppStyle.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppStyle.black),
                    ),
                    padding: EdgeInsets.all(6.r),
                    child: const Icon(Remix.sofa_fill,
                        color: AppStyle.black),
                  ),
                  8.horizontalSpace,
                  Text(
                    AppHelpers.getTranslation(TrKeys.dine),
                    style: GoogleFonts.inter(
                        fontSize: 14.sp, fontWeight: FontWeight.w600,
                        color: AppStyle.black),
                  )
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}

