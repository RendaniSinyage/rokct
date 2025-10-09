import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/utils/utils.dart';
import '../../theme/theme.dart';
import '../buttons/button_effect_animation.dart';

class CommonImage extends StatelessWidget {
  final String? url;
  final File? fileImage;
  final double? width;
  final String? preview;
  final double? height;
  final double radius;
  final double errorRadius;
  final Color? errorBackground;
  final BoxFit? fit;
  final String? name;
  final String? title;
  final VoidCallback? onDelete;

  const CommonImage({
    super.key,
    this.url,
    this.width,
    this.height,
    this.radius = 10,
    this.errorRadius = 10,
    this.errorBackground,
    this.fit,
    this.fileImage,
    this.preview,
    this.name,
    this.title,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
        borderRadius: BorderRadius.circular(radius.r),
        child: preview != null
            ? Stack(
                children: [
                  CachedNetworkImage(
                    height: height?.r,
                    width: width?.r,
                    imageUrl: preview ?? "",
                    fit: fit,
                    progressIndicatorBuilder: (context, url, progress) {
                      return Container(
                        height: height?.r,
                        width: width?.r,
                        decoration: const BoxDecoration(
                          color: AppStyle.shimmerBase,
                        ),
                        child: (width ?? 0) > 58
                            ? Center(
                                child: Text(
                                  AppHelpers.getTranslation(
                                      AppHelpers.getAppName().toString()),
                                  style: AppStyle.interNormal(
                                      color: AppStyle.textGrey, size: 12),
                                ),
                              )
                            : const SizedBox.shrink(),
                      );
                    },
                    errorWidget: (context, url, error) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(radius.r),
                          color: name == null
                              ? AppStyle.shimmerBase
                              : AppStyle.primary,
                        ),
                        alignment: Alignment.center,
                        child: name == null
                            ? const Icon(FlutterRemix.file_unknow_line)
                            : Text(
                                name?.substring(0, 1) ?? "",
                                style: AppStyle.interNormal(
                                  color: AppStyle.white,
                                  size: (height ?? 0) / 2.5,
                                ),
                              ),
                      );
                    },
                  ),
                  Positioned.fill(
                    child: Center(
                      child: ButtonEffectAnimation(
                        onTap: () {
                          // Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: (context) => VideoPage(
                          //           url: url,
                          //           onDelete: onDelete,
                          //         )));
                        },
                        child: Container(
                          padding: EdgeInsets.all(8.r),
                          decoration: BoxDecoration(
                              color: AppStyle.white.withOpacity(0.8),
                              shape: BoxShape.circle),
                          child: const Icon(
                            FlutterRemix.play_fill,
                            color: AppStyle.black,
                          ),
                        ),
                      ),
                    ),
                  )
                ],
              )
            : fileImage != null
                ? Image.file(
                    fileImage!,
                    height: height,
                    width: width,
                    fit: fit,
                  )
                : AppHelpers.checkIsSvg(url)
                    ? SvgPicture.network(
                        '$url',
                        width: width?.r,
                        height: height?.r,
                        fit: BoxFit.cover,
                        placeholderBuilder: (_) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(radius.r),
                            color: AppStyle.white,
                          ),
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: '$url',
                        width: width?.r,
                        height: height?.r,
                        fit: fit ?? BoxFit.cover,
                        progressIndicatorBuilder: (_, __, ___) => Container(
                          height: height?.r,
                          width: width?.r,
                          decoration: const BoxDecoration(
                            color: AppStyle.shimmerBase,
                          ),
                          child: (width ?? 0) > 58
                              ? Center(
                                  child: Text(
                                    AppHelpers.getTranslation(
                                        AppHelpers.getAppName().toString()),
                                    style: AppStyle.interNormal(
                                        color: AppStyle.textGrey, size: 12),
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(errorRadius.r),
                            color: errorBackground ?? AppStyle.greyColor,
                          ),
                          alignment: Alignment.center,
                          child: title?.isNotEmpty ?? false
                              ? Text(title!)
                              : Icon(
                                  FlutterRemix.image_line,
                                  color: AppStyle.black.withOpacity(0.5),
                                  size: 20.r,
                                ),
                        ),
                      ));
  }
}

