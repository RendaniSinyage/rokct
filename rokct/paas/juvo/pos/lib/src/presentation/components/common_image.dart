import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/models/data/order_data.dart';
import 'package:admin_desktop/src/models/data/user_data.dart';
import '../theme/theme.dart';
import 'shimmers/make_shimmer.dart';

class CommonImage extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double radius;
  final bool isResponsive;
  final File? fileImage;
  final OrderData? orderData;
  final UserData? userData;

  const CommonImage({
    super.key,
    required this.imageUrl,
    this.width = double.infinity,
    this.height = 50,
    this.radius = 10,
    this.isResponsive = true,
    this.fileImage,
    this.orderData,
    this.userData,
  });

  String? _getFirstName() {
    if (orderData != null) {
      return orderData?.user?.firstname;
    } else if (userData != null) {
      return userData?.firstname;
    }
    return null;
  }

  String? _getLastName() {
    if (orderData != null) {
      return orderData?.user?.lastname;
    } else if (userData != null) {
      return userData?.lastname;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius.r),
      child: fileImage != null
          ? Image.file(
        fileImage!,
        height: height,
        width: width,
        fit: BoxFit.cover,
      )
          : AppHelpers.checkIsSvg(imageUrl)
          ? SvgPicture.network(
        '$imageUrl',
        width: isResponsive ? width.r : width,
        height: isResponsive ? height.r : height,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius.r),
            color: AppStyle.white,
          ),
        ),
      )
          : CachedNetworkImage(
        imageUrl: '$imageUrl',
        width: isResponsive ? width.r : width,
        height: isResponsive ? height.r : height,
        fit: BoxFit.cover,
        progressIndicatorBuilder: (context, url, progress) {
          return MakeShimmer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(isResponsive ? radius.r : radius),
                color: AppStyle.mainBack,
              ),
            ),
          );
        },
        errorWidget: (context, url, error) {
          // Check if this is a user-related image
          if (orderData != null || userData != null) {
            final String firstName = _getFirstName() ?? "";
            final String lastName = _getLastName() ?? "";
            final bool hasName = firstName.isNotEmpty || lastName.isNotEmpty;

            final String initials = hasName
                ? "${firstName.isNotEmpty ? firstName[0] : ""}${lastName.isNotEmpty ? lastName[0] : ""}"
                : "";

            return Container(
              width: isResponsive ? width.r : width,
              height: isResponsive ? height.r : height,
              decoration: BoxDecoration(
                borderRadius:
                BorderRadius.circular(isResponsive ? radius.r : radius),
                color: AppStyle.primary,
              ),
              alignment: Alignment.center,
              child: hasName
                  ? Text(
                initials.toUpperCase(),
                style: TextStyle(
                  color: AppStyle.black,
                  fontSize: isResponsive ? 20.r : 20,
                  fontWeight: FontWeight.w600,
                ),
              )
                  : Icon(
                FlutterRemix.account_circle_fill,
                color: AppStyle.black,
                size: isResponsive ? 20.r : 20,
              ),
            );
          }
          // Default error widget for non-user images
          return Container(
            width: isResponsive ? width.r : width,
            height: isResponsive ? height.r : height,
            decoration: BoxDecoration(
              borderRadius:
              BorderRadius.circular(isResponsive ? radius.r : radius),
              border: Border.all(color: AppStyle.border),
              color: AppStyle.mainBack,
            ),
            alignment: Alignment.center,
            child: Icon(
              FlutterRemix.image_line,
              color: AppStyle.black.withOpacity(0.5),
              size: isResponsive ? 20.r : 20,
            ),
          );
        },
      ),
    );
  }
}
