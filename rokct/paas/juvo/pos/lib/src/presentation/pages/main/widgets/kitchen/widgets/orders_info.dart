import 'dart:async';
import 'dart:math' as math;
import 'package:admin_desktop/generated/assets.dart';
import 'package:admin_desktop/src/core/utils/time_service.dart';
import 'package:admin_desktop/src/models/data/order_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../core/constants/constants.dart';
import '../../../../../../core/utils/app_helpers.dart';
import '../../../../../theme/theme.dart';

class FlipNumber extends StatefulWidget {
  final String value;
  final Color textColor;
  final Color backgroundColor;

  const FlipNumber({
    required this.value,
    required this.textColor,
    required this.backgroundColor,
    Key? key,
  }) : super(key: key);

  @override
  State<FlipNumber> createState() => _FlipNumberState();
}

class _FlipNumberState extends State<FlipNumber> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _flipAnimation;
  late Animation<double> _scaleAnimation;
  String oldValue = '00';

  @override
  void initState() {
    super.initState();
    oldValue = widget.value;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeInOut),
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0),
        weight: 50.0,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void didUpdateWidget(FlipNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      oldValue = oldWidget.value;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 32.r,
            height: 32.r,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(6.r),
              boxShadow: [
                BoxShadow(
                  color: widget.backgroundColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(_flipAnimation.value * math.pi),
              child: _flipAnimation.value < 0.5
                  ? Center(
                child: Text(
                  oldValue,
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor,
                  ),
                ),
              )
                  : Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateX(math.pi),
                child: Center(
                  child: Text(
                    widget.value,
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: widget.textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class OrdersInfo extends StatefulWidget {
  final bool active;
  final OrderData orderData;

  const OrdersInfo({super.key, required this.active, required this.orderData});

  @override
  State<OrdersInfo> createState() => _OrdersInfoState();
}

class _OrdersInfoState extends State<OrdersInfo> {
  Timer? _timer;
  int _elapsedMinutes = 0;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    if (widget.orderData.status == 'cooking' && widget.orderData.updatedAt != null) {
      startTimer();
    } else if (widget.orderData.status == 'ready') {
      calculateFinalTime();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void calculateFinalTime() {
    if (widget.orderData.createdAt != null && widget.orderData.updatedAt != null) {
      final difference = widget.orderData.updatedAt!.difference(widget.orderData.createdAt!);
      setState(() {
        _elapsedMinutes = difference.inMinutes;
        _hours = difference.inHours;
        _minutes = difference.inMinutes % 60;
        _seconds = difference.inSeconds % 60;
      });
    }
  }

  void startTimer() {
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateTime();
      }
    });
  }

  void _updateTime() {
    if (widget.orderData.updatedAt != null) {
      final difference = DateTime.now().difference(widget.orderData.updatedAt!);
      setState(() {
        _elapsedMinutes = difference.inMinutes;
        _hours = difference.inHours;
        _minutes = difference.inMinutes % 60;
        _seconds = difference.inSeconds % 60;
      });
    }
  }

  Widget _buildTimer() {
    if (widget.orderData.status == 'cooking' && _elapsedMinutes >= 60) {
      return Text(
        'Delayed',
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: AppStyle.red,
        ),
      );
    }

    final isReady = widget.orderData.status == 'ready';
    final backgroundColor = isReady ? AppStyle.black.withOpacity(0.5) : AppStyle.black;
    final textColor = isReady
        ? AppStyle.white.withOpacity(0.5)
        : (_elapsedMinutes >= 30 ? AppStyle.rate : AppStyle.white);
    final colonColor = isReady
        ? AppStyle.black.withOpacity(0.5)
        : (_elapsedMinutes >= 30 ? AppStyle.rate : AppStyle.black);

    return Row(
      children: [
        if (isReady || (!isReady && _hours > 0)) ...[
          FlipNumber(
            value: _hours.toString().padLeft(2, '0'),
            backgroundColor: backgroundColor,
            textColor: textColor,
          ),
          Padding(
            padding: REdgeInsets.symmetric(horizontal: 4),
            child: Text(
              ':',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: colonColor,
              ),
            ),
          ),
        ],
        FlipNumber(
          value: _minutes.toString().padLeft(2, '0'),
          backgroundColor: backgroundColor,
          textColor: textColor,
        ),
        Padding(
          padding: REdgeInsets.symmetric(horizontal: 4),
          child: Text(
            ':',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: colonColor,
            ),
          ),
        ),
        FlipNumber(
          value: _seconds.toString().padLeft(2, '0'),
          backgroundColor: backgroundColor,
          textColor: textColor,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: REdgeInsets.only(bottom: 12),
      width: 228.r,
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadiusDirectional.circular(10),
        boxShadow: [
          BoxShadow(
              offset: const Offset(0, 5),
              blurRadius: 8.r,
              color: widget.active ? AppStyle.shadowSecond : AppStyle.transparent
          )
        ],
        border: Border.all(
            color: widget.active ? AppStyle.primary : AppStyle.transparent
        ),
      ),
      child: Padding(
        padding: REdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  "#${AppHelpers.getTranslation(TrKeys.id)}${widget.orderData.id ?? ''}",
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: AppStyle.black,
                  ),
                ),
                const Spacer(),
                if (widget.orderData.status == 'cooking' || widget.orderData.status == 'ready')
                  _buildTimer(),
              ],
            ),
            4.verticalSpace,
            Divider(
              color: AppStyle.icon.withOpacity(0.6),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppHelpers.getTranslation(TrKeys.orderTime),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppStyle.black
                  ),
                ),
                Text(
                  TimeService.dateFormatMDHm(widget.orderData.createdAt?.toLocal()),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: AppStyle.icon
                  ),
                ),
              ],
            ),
            Divider(
              color: AppStyle.icon.withOpacity(0.6),
            ),
            4.verticalSpace,
            const Spacer(),
            Row(
              children: [
                Container(
                  height: 30.r,
                  width: 30.r,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppStyle.black)
                  ),
                  child: Center(
                      child: widget.orderData.deliveryType == TrKeys.dine
                          ? SvgPicture.asset(Assets.svgDine, color: AppStyle.black)
                          : Icon(
                        widget.orderData.deliveryType == TrKeys.pickup
                            ? FlutterRemix.walk_line
                            : FlutterRemix.e_bike_2_fill,
                        size: 18,
                        color: AppStyle.black,
                      )
                  ),
                ),
                8.horizontalSpace,
                widget.orderData.deliveryType == TrKeys.pickup
                    ? Text(
                  AppHelpers.getTranslation(TrKeys.takeAway),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppStyle.black
                  ),
                )
                    : widget.orderData.deliveryType == TrKeys.dine
                    ? Text(
                  AppHelpers.getTranslation(TrKeys.dine),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppStyle.black
                  ),
                )
                    : Text(
                  AppHelpers.getTranslation(TrKeys.delivery),
                  style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppStyle.black
                  ),
                )
              ],
            ),
            const Spacer(flex: 2),
            Container(
              padding: REdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: AppHelpers.getStatusColor(widget.orderData.status),
                borderRadius: BorderRadius.circular(100.r),
              ),
              child: Text(
                AppHelpers.getTranslation(widget.orderData.status ?? ''),
                style: GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: AppStyle.white
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
