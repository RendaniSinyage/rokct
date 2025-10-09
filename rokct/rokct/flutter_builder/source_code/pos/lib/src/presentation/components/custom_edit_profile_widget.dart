import 'dart:io';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'components.dart';

class CustomEditWidget extends StatelessWidget {
  final bool isEmptyorNot;
  final bool isLoading;
  final int height;
  final double width;
  final int radius;
  final bool isEmptyorNot2;
  final String image;
  final String localStoreImage;
  final String imagePath;
  final Function()? onthisTap;
  const CustomEditWidget({
    super.key,
    this.height = 108,
    this.width = 108,
    this.radius = 100,
    this.isLoading = false,
    required this.isEmptyorNot,
    required this.image,
    required this.isEmptyorNot2,
    required this.imagePath,
    required this.localStoreImage,
    this.onthisTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        isLoading ? MakeShimmer(child: Container(
          height: height.r,
          width: width.r,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius.r),
            color: AppStyle.shimmerBase,
          ),)) :
        Container(
          height: height.r,
          width: width.r,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius.r),
            color: AppStyle.shimmerBase,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(radius.r),
            child: (isEmptyorNot)
                ? CommonImage(
                imageUrl: localStoreImage,
                height: height.r,
                width: width.r,
                radius: radius.r)
                : isEmptyorNot2
                ? Image.file(
              File(imagePath),
              fit: BoxFit.fitWidth,
              width: width.r,
              height: height.r,
            )
                : CommonImage(
                imageUrl: image,
                height: height.r,
                width: width.r,
                radius: radius.r),
          ),
        ),
        Positioned(
          right: radius != 100 ? 4 : 0,
          bottom:  radius != 100 ? 4 : 0,
          child: GestureDetector(
            onTap: onthisTap,
            child: Container(
              width: 40.w,
              height: 40.h,
              decoration: const BoxDecoration(
                color: AppStyle.editProfileCircle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                FlutterRemix.pencil_line,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

