import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/theme.dart';


class ShopTabBarItem extends StatelessWidget {
  final String title;
  final bool isActive;

  const ShopTabBarItem({
    super.key,
    required this.title,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: isActive ? AppStyle.primary : AppStyle.white,
        borderRadius: BorderRadius.circular(10.r),
        boxShadow: [
          BoxShadow(
            color: AppStyle.white.withOpacity(0.07),
            spreadRadius: 0,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 18.w),
      margin: EdgeInsets.only(right: 9.w),
      child: Text(
        title,
        style: AppStyle.interNormal(
          size: 14.sp,
          color: AppStyle.black,
        ),
      ),
    );
  }
}

