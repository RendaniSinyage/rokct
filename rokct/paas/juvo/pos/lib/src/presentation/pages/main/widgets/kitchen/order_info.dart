import 'package:admin_desktop/src/core/utils/time_service.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/kitchen/riverpod/kitchen_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/kitchen/widgets/order_details_item.dart';
import 'package:admin_desktop/src/presentation/theme/app_style.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/constants/constants.dart';
import '../../../../../core/utils/app_helpers.dart';
import '../../../../components/components.dart';

class OrderInfo extends ConsumerStatefulWidget {
  const OrderInfo({super.key});

  @override
  ConsumerState<OrderInfo> createState() => _OrderInfoState();
}

class _OrderInfoState extends ConsumerState<OrderInfo> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(kitchenProvider);
    final event = ref.read(kitchenProvider.notifier);

    return Container(
      margin: EdgeInsets.only(right: 16.r, top: 16.r, bottom: 16.r),
      padding: REdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: state.selectOrder != null
          ? SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                6.verticalSpace,
                Text(
                  AppHelpers.getTranslation(TrKeys.order),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 18.sp,
                    color: AppStyle.black,
                  ),
                ),
                10.verticalSpace,
                Row(
                  children: [
                    Text(
                      "#${AppHelpers.getTranslation(TrKeys.id)}${state.selectOrder?.id}",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp,
                        color: AppStyle.icon,
                      ),
                    ),
                    12.horizontalSpace,
                    Container(
                      width: 8.r,
                      height: 8.r,
                      decoration: const BoxDecoration(
                        color: AppStyle.icon,
                        shape: BoxShape.circle,
                      ),
                    ),
                    12.horizontalSpace,
                    Text(
                      TimeService.dateFormatMDYHm(
                        state.selectOrder?.createdAt?.toLocal(),
                      ),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: 16.sp,
                        color: AppStyle.icon,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                10.verticalSpace,
                Text(
                  AppHelpers.getTranslation(TrKeys.totalItem),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 18.sp,
                    color: AppStyle.black,
                  ),
                ),
                ListView.builder(
                  padding: EdgeInsets.only(top: 16.r, right: 16.r),
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: state.selectOrder?.details?.length ?? 0,
                  itemBuilder: (context, index) {
                    return OrderDetailsItem(
                      orderDetail: state.selectOrder?.details?[index],
                      onEdit: (id, status) {
                        event.updateOrderDetailStatus(
                          status: status,
                          id: id,
                          success: () {},
                        );
                      },
                    );
                  },
                ),
              ],
            ),
            const Divider(),
            if (state.selectOrder?.note != null &&
                state.selectOrder!.note!.isNotEmpty)
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppHelpers.getTranslation(TrKeys.note),
                        style: GoogleFonts.inter(
                          color: AppStyle.black,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          state.selectOrder?.note ?? '',
                          textAlign: TextAlign.end,
                          style: GoogleFonts.inter(
                            color: AppStyle.black,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              ),
            8.verticalSpace,
            if (state.selectOrder?.status != TrKeys.canceled &&
                state.selectOrder?.status != TrKeys.ready)
              Column(
                children: [
                  16.verticalSpace,
                  LoginButton(
                    title: AppHelpers.getTranslation(
                      state.selectOrder?.status == TrKeys.accepted
                          ? TrKeys.startCooking
                          : TrKeys.ready,
                    ),
                    onPressed: () => event.changeStatus(),
                  ),
                  16.verticalSpace,
                  LoginButton(
                    titleColor: AppStyle.white,
                    title: AppHelpers.getTranslation(TrKeys.cancel),
                    bgColor: AppStyle.red,
                    onPressed: () => _showCancelConfirmation(context, event),
                  ),
                  16.verticalSpace,
                ],
              ),
            _buildStatusMessage(state.selectOrder),
          ],
        ),
      )
          : Center(
        child: Text(
          state.orders.isEmpty
              ? AppHelpers.getTranslation(TrKeys.thereAreNoOrders)
              : AppHelpers.getTranslation(TrKeys.noOrderIsSelected),
        ),
      ),
    );
  }

  Widget _buildStatusMessage(dynamic order) {
    if (order == null) return const SizedBox.shrink();

    String? messageKey;
    switch (order.status) {
      case TrKeys.canceled:
        messageKey = TrKeys.thisOrderCancelled;
        break;
      case TrKeys.ready:
        messageKey = TrKeys.thisOrderReady;
        break;
      case TrKeys.onAWay:
        messageKey = TrKeys.thisOrderOnWay;
        break;
      case TrKeys.delivered:
        messageKey = TrKeys.thisOrderDelivered;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Center(
      child: Text(
        AppHelpers.getTranslation(messageKey),
        style: AppStyle.interNormal(color: AppStyle.black),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context, dynamic event) {
    AppHelpers.showAlertDialog(
      context: context,
      backgroundColor: AppStyle.white,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
        ),
        padding: EdgeInsets.all(16.r),
        width: 300.r,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${AppHelpers.getTranslation(TrKeys.areYouSureChange)} ${AppHelpers.getTranslation(TrKeys.cancel)}",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(),
            ),
            16.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: LoginButton(
                    title: AppHelpers.getTranslation(TrKeys.cancel),
                    onPressed: () => context.maybePop(),
                    bgColor: AppStyle.transparent,
                  ),
                ),
                24.horizontalSpace,
                Expanded(
                  child: LoginButton(
                    title: AppHelpers.getTranslation(TrKeys.apply),
                    onPressed: () {
                      context.maybePop();
                      event.changeStatus(status: TrKeys.canceled);
                    },
                    bgColor: AppStyle.red,
                    titleColor: AppStyle.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
