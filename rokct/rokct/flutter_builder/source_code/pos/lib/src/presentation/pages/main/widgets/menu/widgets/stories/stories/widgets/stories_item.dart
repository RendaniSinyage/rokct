import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../../../../../models/data/stories_data.dart';
import '../../../../../../../../components/components.dart';

class StoriesItem extends StatelessWidget {
  final StoriesData stories;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int spacing;

  const StoriesItem({
    super.key,
    required this.stories,
    required this.onEdit,
    this.spacing = 1,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
      margin: EdgeInsets.only(bottom: spacing.r),
      padding: REdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            children: [
              12.horizontalSpace,
              CommonImage(
                width: 44,
                height: 48,
                imageUrl: (stories.fileUrls?.isNotEmpty ?? false)
                    ? stories.fileUrls?.first
                    : null,
              ),
              8.horizontalSpace,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        stories.product?.translation?.title ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          color: AppStyle.black,
                          fontWeight: FontWeight.w400,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                      ),
                    ),
                    8.verticalSpace,
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        8.horizontalSpace,
                        CircleButton(
                          onTap: onEdit,
                          icon: FlutterRemix.pencil_line,
                        ),
                        8.horizontalSpace,
                        CircleButton(
                          onTap: onDelete,
                          icon: FlutterRemix.delete_bin_line,
                        ),
                        8.horizontalSpace,
                      ],
                    ),
                  ],
                ),
              ),
              12.horizontalSpace,
            ],
          ),
        ],
      ),
    );
  }
}

