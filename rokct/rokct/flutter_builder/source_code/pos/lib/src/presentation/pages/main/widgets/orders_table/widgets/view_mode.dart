import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../components/buttons/animation_button_effect.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';

// ViewMode widget
class ViewMode extends StatelessWidget {
  final String title;
  final bool isActive;
  final bool showText;
  final IconData icon;
  final VoidCallback onTap;

  const ViewMode({
    super.key,
    required this.title,
    required this.isActive,
    required this.showText,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationButtonEffect(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(12.r),
          onTap: onTap,
          child: Container(
            width: showText ? 100.w : 50.w,  // Adjust width based on text visibility
            padding: EdgeInsets.symmetric(vertical: 10.r),
            decoration: BoxDecoration(
              color: isActive ? AppStyle.primary : AppStyle.transparent,
              border: Border.all(
                color: isActive ? AppStyle.primary : AppStyle.border,
              ),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? AppStyle.white : AppStyle.reviewText,
                  size: 20.r,
                ),
                if (showText) ...[
                  14.horizontalSpace,
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w500,
                      color: isActive ? AppStyle.white : AppStyle.reviewText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
