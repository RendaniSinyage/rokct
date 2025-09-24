import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../../theme/theme.dart';

class OrderStatusItem extends StatelessWidget {
  final Widget icon;
  final bool isActive;
  final bool isProgress;
  late final Color bgColor;

  OrderStatusItem({
    super.key,
    required this.icon,
    required this.isActive,
    required this.isProgress,
    Color? bgColor,
  }) {
    this.bgColor = bgColor ?? AppStyle.primary;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
          color: isActive ? bgColor : AppStyle.white, shape: BoxShape.circle),
      child: Stack(
        children: [
          Positioned(top: 12.r, left: 12.r, bottom: 10.r, right: 10.r, child: icon),
          isProgress
              ? Icon(
            Remix.timer_line,
            color: AppStyle.primary,
            size: 26.r,

          )
              : SizedBox(
            width: 52.r,
            height: 52.r,
          ),
        ],
      ),
    );
  }
}
