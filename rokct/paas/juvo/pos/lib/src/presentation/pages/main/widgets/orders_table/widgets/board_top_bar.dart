import 'package:admin_desktop/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';

class BoardTopBar extends StatelessWidget {
  final String title;
  final String count;
  final VoidCallback onTap;
  final bool isLoading;
  final Color color;

  const BoardTopBar({
    super.key,
    required this.title,
    required this.count,
    required this.onTap,
    required this.isLoading,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
     margin: const EdgeInsets.only(right: 6,left: 6,bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppStyle.black,
            ),
          ),
          12.horizontalSpace,
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100), color: color),
            child: Text(
              count,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppStyle.white,
              ),
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: onTap,
            child: isLoading
                ? Lottie.asset(
                    Assets.lottieRefresh,
                    width: 32,
                    height: 32,
                    fit: BoxFit.fill,
                  )
                :  const Icon(FlutterRemix.refresh_line,size: 24,
              color: AppStyle.black),
          ),
        ],
      ),
    );
  }
}

