import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/theme.dart';


class TextLoading extends StatelessWidget {
  final int height;
  final int width;
  final int radius;

  const TextLoading({
    super.key,
    this.height = 20,
    this.width = 70,
    this.radius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height.r,
      width: width.r,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius.r),
        color: AppStyle.border,
      ),
    );
  }
}

