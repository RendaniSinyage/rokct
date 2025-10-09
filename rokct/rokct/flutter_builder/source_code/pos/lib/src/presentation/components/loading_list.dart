import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/theme.dart';


class LoadingList extends StatelessWidget {
  final int itemCount;
  final int horizontalPadding;
  final int verticalPadding;
  final int itemBorderRadius;
  final int itemPadding;
  final int itemHeight;

  const LoadingList({
    super.key,
    this.itemCount = 10,
    this.horizontalPadding = 0,
    this.verticalPadding = 0,
    this.itemBorderRadius = 10,
    this.itemPadding = 10,
    this.itemHeight = 134,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: REdgeInsets.symmetric(
        horizontal: horizontalPadding.r,
        vertical: verticalPadding.r,
      ),
      itemBuilder: (context, index) {
        return Container(
          height: itemHeight.h,
          margin: EdgeInsets.only(bottom: itemPadding.h),
          decoration: BoxDecoration(
            color: AppStyle.white,
            borderRadius: BorderRadius.circular(itemBorderRadius.r),
          ),
        );
      },
    );
  }
}

