import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../components/buttons/button_effect_animation.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';

class SelectItem extends StatelessWidget {
  final VoidCallback onTap;
  final bool isActive;
  final bool isLast;
  final String title;

  const SelectItem({
    super.key,
    required this.onTap,
    required this.isLast,
    required this.title, required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonEffectAnimation(
      onTap: onTap,
      child: Column(
        children: [
          5.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 18.r,
                height: 18.r,
                margin: EdgeInsets.only(right: 10.r),
                decoration: BoxDecoration(
                  color: isActive ? AppStyle.primary : AppStyle.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: !isActive ? AppStyle.hint : AppStyle.primary),
                ),
                child: Icon(
                  FlutterRemix.check_line,
                  color: AppStyle.white,
                  size: 16.r,
                ),
              ),
              4.horizontalSpace,
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                  color: AppStyle.black,
                ),
              ),
            ],
          ),
          10.verticalSpace,
          if(!isLast)const Divider(color: AppStyle.hint),
          5.verticalSpace,
        ],
      ),
    );
  }
}

