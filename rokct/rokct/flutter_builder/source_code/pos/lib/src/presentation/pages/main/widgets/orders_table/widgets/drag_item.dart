import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../../../generated/assets.dart';
import '../../../../../../core/constants/constants.dart';
import '../../../../../../core/utils/utils.dart';
import '../../../../../../models/data/order_data.dart';
import '../../../../../components/components.dart';
import '../../../../../theme/theme.dart';
import '../../../riverpod/provider/main_provider.dart';
import '../icon_title.dart';
import 'custom_popup_item.dart';

// Timer state provider
final orderTimerProvider = StateNotifierProvider.family<OrderTimerNotifier, OrderTimerState, String>(
      (ref, orderId) => OrderTimerNotifier(),
);

// Timer state
class OrderTimerState {
  final String timeDifference;
  final String timeRange;
  final DateTime? lastUpdate;
  final String status;
  final DateTime? endTime;

  OrderTimerState({
    this.timeDifference = '',
    this.timeRange = '',
    this.lastUpdate,
    this.status = '',
    this.endTime,
  });

  OrderTimerState copyWith({
    String? timeDifference,
    String? timeRange,
    DateTime? lastUpdate,
    String? status,
    DateTime? endTime,
  }) {
    return OrderTimerState(
      timeDifference: timeDifference ?? this.timeDifference,
      timeRange: timeRange ?? this.timeRange,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      status: status ?? this.status,
      endTime: endTime ?? this.endTime,
    );
  }
}

class OrderTimerNotifier extends StateNotifier<OrderTimerState> {
  Timer? _timer;

  OrderTimerNotifier() : super(OrderTimerState());

  void updateTimer(String status, DateTime startTime, DateTime? endTime) {
    if (state.status != status || _timer == null) {
      _timer?.cancel();

      final shouldUseEndTime = status == TrKeys.ready && endTime != null;
      final finalEndTime = shouldUseEndTime ? endTime : null;

      state = state.copyWith(
        status: status,
        endTime: finalEndTime,
      );

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        final now = DateTime.now();
        final targetEndTime = finalEndTime ?? now;

        state = state.copyWith(
          timeDifference: _calculateTimeDifference(startTime, targetEndTime),
          timeRange: _formatTimeRange(startTime, targetEndTime),
          lastUpdate: now,
        );
      });
    }
  }

  String _calculateTimeDifference(DateTime start, DateTime end) {
    final difference = end.difference(start);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  String _formatTimeRange(DateTime start, DateTime end) {
    final startFormat = DateFormat('h:mma').format(start.toLocal()).toLowerCase();
    final endFormat = DateFormat('h:mma').format(end.toLocal()).toLowerCase();
    return '$startFormat - $endFormat';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class DragItem extends ConsumerStatefulWidget {
  final OrderData orderData;
  final bool isDrag;

  const DragItem({super.key, required this.orderData, this.isDrag = false});

  @override
  ConsumerState<DragItem> createState() => _DragItemState();
}

class _DragItemState extends ConsumerState<DragItem> {
  bool _shouldShowUserInfo() {
    final currentUser = LocalStorage.getUser();

    if (currentUser?.id == widget.orderData.user?.id) {
      return false;
    }

    if (currentUser?.role == 'seller') {
      return currentUser?.id != widget.orderData.shop?.seller?.id;
    }

    return true;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTimer();
    });
  }

  void _initializeTimer() {
    final currentStatus = widget.orderData.status ?? '';
    ref.read(orderTimerProvider(widget.orderData.id.toString()).notifier).updateTimer(
      currentStatus,
      widget.orderData.createdAt ?? DateTime.now(),
      currentStatus == TrKeys.ready ? widget.orderData.updatedAt : null,
    );
  }

  @override
  void didUpdateWidget(DragItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderData.status != widget.orderData.status) {
      _initializeTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showUserInfo = _shouldShowUserInfo();
    final currentStatus = widget.orderData.status ?? '';
    final orderId = widget.orderData.id.toString();
    final timerState = ref.watch(orderTimerProvider(orderId));

    double getProgressPercentage() {
      switch (currentStatus) {
        case TrKeys.newOrder:
          return 0.0;
        case TrKeys.accepted:
          return 0.2;
        case TrKeys.cooking:
          return 0.4;
        case TrKeys.ready:
          return 0.6;
        case TrKeys.onAWay:
          return 0.8;
        case TrKeys.delivered:
        case TrKeys.canceled:
          return 1.0;
        default:
          return 0.0;
      }
    }

    Color getProgressColor() {
      switch (currentStatus) {
        case TrKeys.newOrder:
          return AppStyle.blue;
        case TrKeys.accepted:
          return AppStyle.deepPurple;
        case TrKeys.cooking:
          return AppStyle.rate;
        case TrKeys.ready:
          return AppStyle.revenueColor;
        case TrKeys.onAWay:
          return AppStyle.black;
        case TrKeys.delivered:
          return AppStyle.primary;
        case TrKeys.canceled:
          return AppStyle.red;
        default:
          return AppStyle.primary;
      }
    }

    Widget buildDeliveryTypeContainer() {
      final progress = getProgressPercentage();
      final color = getProgressColor();

      return Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppStyle.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppStyle.border,
                valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.5)),
                minHeight: 44,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppHelpers.getTranslation(
                              widget.orderData.deliveryType ?? "",
                            ),
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppStyle.black,
                            ),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppStyle.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(4),
                  height: 35,
                  width: 35,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppStyle.black),
                    shape: BoxShape.circle,
                    color: AppStyle.white,
                  ),
                  child: (widget.orderData.deliveryType ?? "") == TrKeys.dine
                      ? Padding(
                    padding: const EdgeInsets.all(4),
                    child: SvgPicture.asset(Assets.svgDine),
                  )
                      : Icon(
                    (widget.orderData.deliveryType ?? "") == TrKeys.delivery
                        ? FlutterRemix.e_bike_2_fill
                        : FlutterRemix.walk_line,
                    size: 16,
                    color: AppStyle.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return InkWell(
      child: Transform.rotate(
        angle: widget.isDrag ? (3.14 * (0.03)) : 0,
        child: Container(
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: widget.isDrag ? AppStyle.icon.withOpacity(0.3) : null,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: AppStyle.white,
          ),
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showUserInfo) ...[
                    CommonImage(
                      imageUrl: widget.orderData.user?.img,
                      orderData: widget.orderData,
                      height: 42,
                      width: 42,
                      radius: 32,
                      isResponsive: false,
                    ),
                    6.horizontalSpace,
                  ],
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (showUserInfo)
                            Text(
                              widget.orderData.user?.firstname ?? "",
                              maxLines: 1,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppStyle.black,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          Text(
                            "№${widget.orderData.id}",
                            style: GoogleFonts.inter(
                              fontSize: (showUserInfo) ? 14 : 22,
                              color: (showUserInfo) ? AppStyle.hint : AppStyle.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  CustomPopup(
                    orderData: widget.orderData,
                    isLocation: widget.orderData.deliveryType == TrKeys.delivery,
                  ),
                ],
              ),
              6.verticalSpace,
              const Divider(height: 2),
              12.verticalSpace,
              IconTitle(
                icon: FlutterRemix.calendar_2_line,
                value: DateFormat("d MMM yy")
                    .format(widget.orderData.createdAt?.toLocal() ?? DateTime.now()),
              ),
              IconTitle(
                icon: FlutterRemix.money_dollar_circle_line,
                value: AppHelpers.numberFormat(
                  widget.orderData.totalPrice ?? 0,
                  symbol: widget.orderData.currency?.symbol,
                ),
              ),
              IconTitle(
                icon: FlutterRemix.money_euro_circle_line,
                value: widget.orderData.transaction?.paymentSystem?.tag ?? "- -",
              ),
              if (widget.orderData.deliveryman?.firstname?.isNotEmpty ?? false)
                IconTitle(
                  icon: FlutterRemix.car_line,
                  value: widget.orderData.deliveryman?.firstname ?? "- -",
                ),
              if (widget.orderData.table?.name?.isNotEmpty ?? false)
                IconTitle(
                  icon: Icons.table_restaurant_outlined,
                  value: widget.orderData.table?.name ?? "- -",
                ),
              if (widget.orderData.orderAddress?.address?.isNotEmpty ?? false)
                IconTitle(
                  icon: FlutterRemix.map_pin_2_line,
                  value: widget.orderData.orderAddress?.address ?? "- -",
                ),
              if (widget.orderData.transaction?.status?.isNotEmpty ?? false)
                IconTitle(
                  icon: FlutterRemix.money_dollar_circle_line,
                  value: widget.orderData.transaction?.status ?? "- -",
                ),
              12.verticalSpace,
              buildDeliveryTypeContainer(),
              12.verticalSpace,
              Row(
                children: [
                  Text(
                    timerState.timeDifference,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppStyle.black,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    timerState.timeRange,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppStyle.hint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        ref.read(mainProvider.notifier).setOrder(widget.orderData);
      },
    );
  }
}
