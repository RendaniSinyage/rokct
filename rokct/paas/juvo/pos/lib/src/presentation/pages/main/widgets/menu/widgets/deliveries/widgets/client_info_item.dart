import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:admin_desktop/src/core/utils/app_helpers.dart';

class ClientInfoItem extends StatelessWidget {
  final String title;
  final String label;

  const ClientInfoItem({super.key, required this.title, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: REdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppHelpers.getTranslation(label),
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppStyle.selectedItemsText,
              fontWeight: FontWeight.w600
            ),
          ),
          2.verticalSpace,
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

