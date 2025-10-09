import 'package:admin_desktop/src/presentation/components/buttons/animation_button_effect.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/app_style.dart';

class SectionButton extends StatelessWidget {
  final String title;
  final Widget? icon;
  final Widget? prefixIcon;
  late final double height;
  late final bool isLoading;
  late final bool isActive;
  late final bool isTab;
  late final bool isShadow;
  late final Color bgColor;
  late final Color borderColor;
  late final Color textColor;
  final double? textSize;
  final double? paddingSize;
  final Function()? onTap;

  SectionButton({
    super.key,
    required this.title,
    required this.onTap,
    double? height,
    bool? isLoading,
    bool? isActive,
    Color? bgColor,
    Color? borderColor,
    Color? textColor,
    this.icon,
    this.prefixIcon,
    this.textSize,
    this.paddingSize,
    bool? isTab,
    bool? isShadow,
  }) {
    this.height = height ?? 50;
    this.isLoading = isLoading ?? false;
    this.isActive = isActive ?? true;
    this.bgColor = bgColor ?? AppStyle.primary;
    this.borderColor = borderColor ?? AppStyle.transparent;
    this.textColor = textColor ?? AppStyle.white;
    this.isTab = isTab ?? false;
    this.isShadow = isShadow ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AnimationButtonEffect(
      child: Material(
        borderRadius: BorderRadius.circular(15.r),
        color: isActive ? bgColor : AppStyle.white,
        child: InkWell(
          borderRadius: BorderRadius.circular(15.r),
          onTap: isTab
              ? onTap
              : isActive
              ? onTap
              : null,
          child: Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.r),
                border: Border.all(color: borderColor),
                color: isActive ? bgColor : AppStyle.white,
                boxShadow: isShadow
                    ? [
                  BoxShadow(
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                    color: AppStyle.black.withOpacity(0.07),
                  )
                ]
                    : []),
            height: height.r,
            padding: REdgeInsets.symmetric(horizontal: paddingSize ?? 24),
            alignment: Alignment.center,
            child: isLoading
                ? SizedBox(
              height: 24.r,
              width: 24.r,
              child: CircularProgressIndicator(
                strokeWidth: 2.r,
                color: isActive ? AppStyle.white : AppStyle.black,
              ),
            )
                : icon ??
                Row(
                  children: [
                    prefixIcon ?? const SizedBox.shrink(),
                    prefixIcon != null
                        ? 12.r.horizontalSpace
                        : const SizedBox.shrink(),
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                        fontSize: textSize?.sp ?? 14.sp,
                        color: isActive
                            ? AppStyle.black
                            : AppStyle.reviewText,
                      ),
                    )
                  ],
                ),
          ),
        ),
      ),
    );
  }
}
