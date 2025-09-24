import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class SectionsItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool isDivider;

  const SectionsItem({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.isDivider = true
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        color: AppStyle.transparent,
        child: Column(
          children: [
            Row(
              children: [
                Icon(icon, size: 24),
                16.horizontalSpace,
                Text(
                  title,
                  style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      color: AppStyle.black,
                      fontWeight: FontWeight.bold)
                ),
              ],
            ),
            12.verticalSpace,
            if(isDivider)
              const Divider(color: AppStyle.hint),
          ],
        ),
      ),
    );
  }
}

