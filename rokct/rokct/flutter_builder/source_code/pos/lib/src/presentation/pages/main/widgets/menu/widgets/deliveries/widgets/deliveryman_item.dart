import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../../../../../../../components/components.dart';

class DeliverymanItem extends StatelessWidget {
  final UserData user;
  final ValueChanged<String> onTap;
  const DeliverymanItem({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: REdgeInsets.only(bottom: 8),
      width: double.infinity,
      height: 124.r,
      decoration: BoxDecoration(
        color: AppStyle.white,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
           12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    CommonImage(
                      imageUrl: user.img,
                      width: 48,
                      height: 48,
                      radius: 14,
                      // errorRadius: 14,
                    ),
                    10.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AutoSizeText(
                            '${user.firstname} ${user.lastname ?? ''}',
                            style: GoogleFonts.inter(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700
                            ),
                            maxLines: 1,
                          ),
                          4.verticalSpace,
                          Text(
                            user.phone ?? '',
                            style: GoogleFonts.inter(
                                fontSize: 16.sp, 
                                color: AppStyle.selectedItemsText,
                                fontWeight: FontWeight.w600
                            ),
                          ),
                          const Divider(height: 4),
                        ],
                      ),
                    ),
                    // 16.horizontalSpace,
                    // if (status.isNotEmpty)
                    //   StatusButton(
                    //     status: status,
                    //     onTap: () => onTap(status),
                    //   ),
                    // if (status.isNotEmpty)
                    // 24.horizontalSpace,
                  ],
                ),
                4.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppHelpers.getTranslation(TrKeys.email),
                            style: GoogleFonts.inter(
                              fontSize: 16.sp,
                              color: AppStyle.selectedItemsText,
                            ),
                          ),
                          2.verticalSpace,
                          Text(
                            user.email ?? '',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp),
                          ),
                        ],
                      ),
                    ),
                    12.horizontalSpace,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppHelpers.getTranslation(TrKeys.gender),
                          style: GoogleFonts.inter(
                            fontSize: 16.sp,
                            color: AppStyle.selectedItemsText,
                          ),
                        ),
                        2.verticalSpace,
                        Text(
                          AppHelpers.getTranslation(user.gender ?? ""),
                          style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 16.sp),
                        ),
                      ],
                    ),
                    24.horizontalSpace,
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

