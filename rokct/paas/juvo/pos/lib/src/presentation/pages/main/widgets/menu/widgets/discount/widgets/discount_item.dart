import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/core/utils/local_storage.dart';
import 'package:admin_desktop/src/models/models.dart';
import '../../../../../../../components/components.dart';


class DiscountItem extends StatelessWidget {
  final DiscountData discountData;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final int spacing;

  const DiscountItem({
    super.key,
    required this.discountData,
    required this.onTap,
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
              Container(
                width: 4.r,
                height: 56.r,
                padding: REdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                    color: discountData.active! ? AppStyle.green : AppStyle.red,
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(10.r),
                      bottomRight: Radius.circular(10.r),
                    )),
              ),
              12.horizontalSpace,
              CommonImage(
                width: 50,
                height: 52,
                imageUrl: discountData.img,
                // errorRadius: 0,
                // fit: BoxFit.cover,
              ),
              8.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: AppHelpers.getTranslation(TrKeys.type),
                              style: GoogleFonts.inter(
                                color: AppStyle.black,
                                fontSize: 13.sp,
                                letterSpacing: -0.3,
                                fontWeight: FontWeight.w700
                              ),
                              children: [
                                TextSpan(
                                  text: ' : ',
                                  style: GoogleFonts.inter(
                                    color: AppStyle.black,
                                    fontSize: 13.sp,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                TextSpan(
                                  text: AppHelpers.getTranslation(
                                      discountData.type ?? ''),
                                  style: GoogleFonts.inter(
                                    color: AppStyle.black,
                                    fontSize: 12.sp,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        8.horizontalSpace,
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              text: discountData.type == TrKeys.fix
                                  ? AppHelpers.getTranslation(TrKeys.price)
                                  : AppHelpers.getTranslation(TrKeys.percent),
                              style: GoogleFonts.inter(
                                color: AppStyle.black,
                                fontSize: 13.sp,
                                letterSpacing: -0.3,
                              ),
                              children: [
                                TextSpan(
                                  text: discountData.type == TrKeys.fix
                                      ? '(${LocalStorage.getSelectedCurrency().symbol}):'
                                      : "(%):",
                                  style: GoogleFonts.inter(
                                    color: AppStyle.black,
                                    fontSize: 13.sp,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${discountData.price ?? "0"}',
                                  style: GoogleFonts.inter(
                                    color: AppStyle.black,
                                    fontSize: 12.sp,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    4.verticalSpace,
                    Text(
                      '${AppHelpers.dateFormat(discountData.start)} - ${AppHelpers.dateFormat(discountData.end)}',
                      style: GoogleFonts.inter(fontSize: 12.sp),
                    )
                  ],
                ),
              ),
              8.horizontalSpace,
              Row(
                children: [
                  CircleButton(
                    onTap: onTap,
                    icon: FlutterRemix.pencil_line,
                  ),
                  8.horizontalSpace,
                  CircleButton(
                    onTap: onDelete,
                    icon: FlutterRemix.delete_bin_line,
                  ),
                ],
              ),
              12.horizontalSpace,
            ],
          ),
        ],
      ),
    );
  }
}

