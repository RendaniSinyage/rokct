import 'package:admin_desktop/src/presentation/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../components/buttons/animation_button_effect.dart';

class PinButton extends StatelessWidget {
  final String? title;
  final IconData? iconData;
  final VoidCallback onTap;

  const PinButton({
    Key? key,
    this.title,
    this.iconData,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimationButtonEffect(
      child: Material(
        color: AppStyle.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Ink(
            height: 72.r,
            width: 72.r,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppStyle.white,
                  AppStyle.white.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: AppStyle.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: title != null
                  ? Text(
                      title!,
                      style: GoogleFonts.inter(
                        color: AppStyle.black,
                        fontWeight: FontWeight.w600,
                        fontSize: 28.sp,
                      ),
                    )
                  : iconData != null
                      ? Icon(
                          iconData!,
                          size: 28.r,
                          color: AppStyle.black.withOpacity(0.8),
                        )
                      : const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}

