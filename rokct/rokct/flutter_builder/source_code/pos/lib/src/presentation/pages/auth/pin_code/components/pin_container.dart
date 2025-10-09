import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../theme/app_style.dart';

class PinContainer extends StatelessWidget {
  final bool isActive;
  const PinContainer({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24.r,
      width: 24.r,
      margin: EdgeInsets.only(right: 12.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? AppStyle.primary.withOpacity(0.9)
            : AppStyle.transparent,
        border: Border.all(
          color: isActive
              ? AppStyle.transparent
              : AppStyle.outlineButtonBorder.withOpacity(0.7),
          width: 2.r,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppStyle.primary.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                )
              ]
            : null,
      ),
    );
  }
}

