import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../generated/assets.dart';
import '../../theme/theme.dart';


class NoDataInfo extends StatelessWidget {
  final String title;

  const NoDataInfo({super.key, required this.title}) ;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 32.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(Assets.pngNoProducts, width: 205.w, height: 206.h),
          Text(
            title,
            style: AppStyle.interRegular(
              size: 14.sp,
              color: AppStyle.black,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          )
        ],
      ),
    );
  }
}

