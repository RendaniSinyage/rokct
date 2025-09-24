import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../../../../../theme/theme.dart';


class TemperatureBadge extends StatelessWidget {
  final int temperature;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final double borderWidth;
  final Color? backgroundColor;
  final String? suffix;
  final bool showShadow;

  const TemperatureBadge({
    super.key,
    required this.temperature,
    this.fontSize = 12.0,
    this.padding,
    this.borderWidth = 1.5,
    this.backgroundColor,
    this.suffix,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? EdgeInsets.symmetric(
        horizontal: 6.sp,
        vertical: 3.sp,
      ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppStyle.black,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(
          color: AppStyle.white,
          width: borderWidth,
        ),
        boxShadow: showShadow ? [
          BoxShadow(
            color: AppStyle.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ] : null,
      ),
      child: Text(
        '$temperature${suffix ?? '°'}',
        style: TextStyle(
          color: AppStyle.white,
          fontSize: fontSize.sp,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}
