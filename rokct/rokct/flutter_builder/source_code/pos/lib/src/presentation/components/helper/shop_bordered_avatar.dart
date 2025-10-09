import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/theme.dart';
import 'blur_wrap.dart';
import 'common_image.dart';

class ShopBorderedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final double imageSize;
  final double borderRadius;
  final Color bgColor;

  const ShopBorderedAvatar({
    super.key,
    this.imageUrl,
    required this.size,
    required this.imageSize,
    required this.borderRadius,
    this.bgColor = AppStyle.greyColor,
  });

  @override
  Widget build(BuildContext context) {
    return BlurWrap(
      radius: BorderRadius.circular(borderRadius.r),
      child: Container(
        width: size.r,
        height: size.r,
        color: bgColor,
        alignment: Alignment.center,
        child: CommonImage(
          url: imageUrl,
          width: imageSize,
          height: imageSize,
          radius: imageSize / 2,
        ),
      ),
    );
  }
}

