import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/theme.dart';


class SizeItem extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;
  final String title;

  const SizeItem({
    super.key,
    required this.onTap,
    required this.isActive,
    required this.title,
  }) ;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: REdgeInsets.only(top: 16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppStyle.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 18.w,
                    height: 18.h,
                    decoration: BoxDecoration(
                      color: isActive ? AppStyle.green : AppStyle.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? AppStyle.black : AppStyle.greyColor,
                        width: isActive ? 4.r : 2.r,
                      ),
                    ),
                  ),
                  16.horizontalSpace,
                  Text(
                    title,
                    style: AppStyle.interNormal(
                      size: 16.sp,
                      color: AppStyle.black,
                    ),
                  ),
                ],
              ),
              16.verticalSpace,
              Divider(color: AppStyle.greyColor.withOpacity(0.2))
            ],
          ),
        ),
      ),
    );
  }
}

