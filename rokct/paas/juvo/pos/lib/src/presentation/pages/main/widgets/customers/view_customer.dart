import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/presentation/components/components.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';

import '../../../../../core/handlers/handlers.dart';
import '../../../../../models/models.dart';
import '../JuvoONE/riverpod/provider/quickOrdersRepositoryProvider.dart';

class ViewCustomer extends StatelessWidget {
  final UserData? user;
  final VoidCallback back;

  const ViewCustomer({super.key, required this.user, required this.back});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 24.r,
        bottom: 16.r,
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              back.call();
            },
            child: Row(
              children: [
                Icon(
                  FlutterRemix.arrow_left_s_line,
                  color: AppStyle.black,
                  size: 32.r,
                ),
                Text(
                  AppHelpers.getTranslation(TrKeys.back),
                  style: GoogleFonts.inter(
                    color: AppStyle.black,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
          16.verticalSpace,
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.r, vertical: 30.r),
              decoration: BoxDecoration(
                  color: AppStyle.white,
                  borderRadius: BorderRadius.circular(10.r)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CommonImage(
                        width: 108.r,
                        height: 108.r,
                        imageUrl: user?.img ?? "",
                        userData: user,
                        radius: 54.r,
                      ),
                      28.horizontalSpace,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${user?.firstname ?? ""} ${user?.lastname ?? ""}",
                            style: GoogleFonts.inter(
                                fontSize: 24.sp, fontWeight: FontWeight.w600,
                              color: AppStyle.black),

                          ),
                          8.verticalSpace,  // Add some spacing
                          _OrderDots(user: user),
                          8.verticalSpace,
                          Text(
                            "#${AppHelpers.getTranslation(TrKeys.id)}${user?.id ?? ""}",
                            style: GoogleFonts.inter(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w500,
                                color: AppStyle.icon),
                          ),
                        ],
                      )
                    ],
                  ),
                  46.verticalSpace,
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                            color: AppStyle.black,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppStyle.primary, width: 5.r)),
                        width: 18.r,
                        height: 18.r,
                      ),
                      10.horizontalSpace,
                      Text(
                        AppHelpers.getTranslation(TrKeys.male),
                        style: TextStyle(color: AppStyle.black),
                      ),
                      32.horizontalSpace,
                      Container(
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppStyle.icon)),
                        width: 18.r,
                        height: 18.r,
                      ),
                      10.horizontalSpace,
                      Text(AppHelpers.getTranslation(TrKeys.female),
                        style: TextStyle(color: AppStyle.black),
                      ),
                    ],
                  ),
                  24.verticalSpace,
                  Row(
                    children: [
                      SizedBox(
                        width: 382.w,
                        child: OutlinedBorderTextField(
                          readOnly: true,
                          label: AppHelpers.getTranslation(TrKeys.firstname),
                          initialText: user?.firstname ?? "",
                        ),
                      ),
                      80.horizontalSpace,
                      SizedBox(
                        width: 382.w,
                        child: OutlinedBorderTextField(
                          readOnly: true,
                          label: AppHelpers.getTranslation(TrKeys.lastname),
                          initialText: user?.lastname ?? "",
                        ),
                      ),
                    ],
                  ),
                  24.verticalSpace,
                  Row(
                    children: [
                      SizedBox(
                        width: 382.w,
                        child: OutlinedBorderTextField(
                          readOnly: true,
                          label: AppHelpers.getTranslation(TrKeys.email),
                          initialText: user?.email ?? "",
                        ),
                      ),
                      80.horizontalSpace,
                      SizedBox(
                        width: 382.w,
                        child: OutlinedBorderTextField(
                          readOnly: true,
                          label: AppHelpers.getTranslation(TrKeys.phoneNumber),
                          initialText: user?.phone ?? "",
                        ),
                      ),
                    ],
                  ),
                  24.verticalSpace,
                  Row(
                    children: [
                      SizedBox(
                        width: 382.w,
                        child: OutlinedBorderTextField(
                          readOnly: true,
                          label: AppHelpers.getTranslation(TrKeys.idCode),
                          initialText:
                              "#${AppHelpers.getTranslation(TrKeys.id)}${user?.id}",
                        ),
                      ),
                      80.horizontalSpace,
                      SizedBox(
                        width: 382.w,
                        child: OutlinedBorderTextField(
                          readOnly: true,
                          label: AppHelpers.getTranslation(TrKeys.birth),
                          initialText: user?.birthday ?? "",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
class _OrderDots extends ConsumerWidget {
  final UserData? user;

  const _OrderDots({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<ApiResult<OrdersPaginateResponse>>(
      future: ref.read(ordersRepositoryProvider).getUserDeliveredOrders(
        userId: user?.id ?? 0,
        page: 1,
      ),
      builder: (context, snapshot) {
        debugPrint('FutureBuilder state: ${snapshot.connectionState}');

        int activeCount = 0;

        if (snapshot.hasData) {
          snapshot.data?.when(
            success: (response) {
              debugPrint('Response success, orders count: ${response.data?.orders?.length}');

              final deliveredOrders = response.data?.orders ?? [];
              debugPrint('Delivered orders length: ${deliveredOrders.length}');

              if (deliveredOrders.isNotEmpty) {
                try {
                  final latestOrder = deliveredOrders
                      .where((order) =>
                  order.note != null &&
                      !order.note!.contains('no_user_order') &&
                      order.note!.contains('|'))
                      .toList()
                      .firstWhereOrNull((order) {
                    final numberPart = order.note!.split('|').last.trim();
                    return int.tryParse(numberPart) != null;
                  });

                  debugPrint('Latest order note: ${latestOrder?.note}');

                  if (latestOrder?.note != null) {
                    final numberPart = latestOrder!.note!.split('|').last.trim();
                    final orderNumber = int.tryParse(numberPart) ?? 0;
                    activeCount = orderNumber.clamp(0, 4);
                    debugPrint('Active count: $activeCount');
                  }
                } catch (e) {
                  debugPrint('Error processing order: $e');
                }
              }
            },
            failure: (error) {
              debugPrint('Response failure: $error');
            },
          );
        }

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 4.r),
          child: Row(
            children: [
              for (int i = 0; i < 4; i++) ...[
                Container(
                  width: 12.r,
                  height: 12.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < activeCount ? AppStyle.green : AppStyle.unselectedBottomBarBack,
                    border: Border.all(
                      color: AppStyle.black.withOpacity(0.1),
                      width: 1.r,
                    ),
                  ),
                ),
                if (i < 3) SizedBox(width: 8.r),
              ],
            ],
          ),
        );
      },
    );
  }
}
