import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/models/data/order_data.dart';
import 'package:admin_desktop/src/models/data/user_data.dart';
import 'package:admin_desktop/src/presentation/components/components.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/order_detail/widgets/deliveryman.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';


class UserInformation extends StatelessWidget {
  final UserData? user;
  final OrderData? order;
  final UserData? selectUser;
  final ValueChanged? onChanged;
  final VoidCallback setDeliveryman;

  const UserInformation(
      {super.key,
      required this.user,
      this.order,
      this.selectUser,
      this.onChanged,
      required this.setDeliveryman});

  @override
  Widget build(BuildContext context) {
    num subTotal = 0;
    subTotal = (order?.totalPrice ?? 0) -
        (order?.tax ?? 0) -
        (order?.deliveryFee ?? 0) +
        (order?.totalDiscount ?? 0)+ (order?.couponPrice ?? 0);
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppStyle.border),
      ),
      padding: EdgeInsets.all(24.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CommonImage(
                imageUrl: user?.img ?? "",
                orderData: OrderData(user: user),
                width: 60,
                height: 60,
                radius: 30,
              ),
              16.horizontalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${AppHelpers.getTranslation(TrKeys.order)} №${order?.id}",
                    style: GoogleFonts.inter(
                        fontSize: 22.sp, fontWeight: FontWeight.w600,
                    color: AppStyle.black),
                  ),
                  6.verticalSpace,
                  Row(
                    children: [

                      10.horizontalSpace,
                      Text(
                        DateFormat("MMM d, HH:mm").format(
                            order?.createdAt?.toLocal() ?? DateTime.now()),
                        style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: AppStyle.icon),
                      ),
                    ],
                  ),
                ],
              )
            ],
          ),
          8.verticalSpace,
          const Divider(),
          8.verticalSpace,
          if (order?.orderAddress?.address?.isNotEmpty ?? false)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.deliveryAddress),
                  style: GoogleFonts.inter(
                      fontSize: 16.sp, color: AppStyle.icon),
                ),
                12.verticalSpace,
                Text(
                  order?.orderAddress?.address ?? "",
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    color: AppStyle.black,
                  ),
                ),
              ],
            ),
          12.verticalSpace,
          if (order?.phone?.isNotEmpty ?? false)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.phoneNumber),
                  style: GoogleFonts.inter(
                      fontSize: 16.sp, color: AppStyle.icon),
                ),
                12.verticalSpace,
                Text(
                  order?.phone ?? "",
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    color: AppStyle.black,
                  ),
                ),
              ],
            ),
          if (order?.table?.name?.isNotEmpty ?? false)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.tableName),
                  style: GoogleFonts.inter(
                      fontSize: 16.sp, color: AppStyle.icon),
                ),
                12.verticalSpace,
                Text(
                  order?.table?.name ?? "",
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          8.verticalSpace,
          const Divider(),
          8.verticalSpace,
          _priceInformation(subTotal),
          8.verticalSpace,
          const Divider(),
          8.verticalSpace,
          DeliverymanScreen(
            orderData: order,
            setDeliveryman: setDeliveryman,
            selectUser: selectUser,
            onChanged: onChanged,
          )
        ],
      ),
    );
  }

  Column _priceInformation(num subTotal) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppHelpers.getTranslation(TrKeys.subtotal),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              AppHelpers.numberFormat(
                subTotal,
                symbol: order?.currency?.symbol,
              ),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        20.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppHelpers.getTranslation(TrKeys.tax),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              AppHelpers.numberFormat(
                order?.tax ?? 0,
                symbol: order?.currency?.symbol,
              ),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        20.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppHelpers.getTranslation(TrKeys.deliveryFee),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              AppHelpers.numberFormat(
                order?.deliveryFee ?? 0,
                symbol: order?.currency?.symbol,
              ),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        20.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppHelpers.getTranslation(TrKeys.discount),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              "-${AppHelpers.numberFormat(
                order?.totalDiscount ?? 0,
                symbol: order?.currency?.symbol,
              )}",
              style: GoogleFonts.inter(
                color: AppStyle.red,
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),  20.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppHelpers.getTranslation(TrKeys.coupon),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              "-${AppHelpers.numberFormat(
                order?.couponPrice ?? 0,
                symbol: order?.currency?.symbol,
              )}",
              style: GoogleFonts.inter(
                color: AppStyle.red,
                fontSize: 16.sp,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
        20.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppHelpers.getTranslation(TrKeys.totalPrice),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 18.sp,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.4,
              ),
            ),
            Text(
              AppHelpers.numberFormat(
                order?.totalPrice ?? 0,
                symbol: order?.currency?.symbol,
              ),
              style: GoogleFonts.inter(
                color: AppStyle.black,
                fontSize: 32.sp,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.4,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

