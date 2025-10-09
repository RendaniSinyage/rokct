import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/theme.dart';

class IconTitle extends StatelessWidget {
  final String? title;
  final IconData icon;
  final String value;

  const IconTitle({
    super.key,
    this.title,
    required this.icon,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final String lowercaseValue = value.toLowerCase();
    final bool isPaid = lowercaseValue == 'paid';
    final bool isCanceled = lowercaseValue == 'canceled';
    final bool isProgress = lowercaseValue == 'progress';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
              icon,
              size: 21,
              color: AppStyle.black.withOpacity(0.4)
          ),
          6.horizontalSpace,
          Expanded(
            child: RichText(
              maxLines: 1,
              text: TextSpan(
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: AppStyle.black.withOpacity(0.8),
                ),
                children: [
                  if (title != null)
                    TextSpan(text: "$title: "),
                  TextSpan(
                    text: value,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: isCanceled
                          ? AppStyle.red
                          : isPaid
                          ? AppStyle.inStockText
                          : isProgress
                          ? AppStyle.rate
                          : AppStyle.black.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
