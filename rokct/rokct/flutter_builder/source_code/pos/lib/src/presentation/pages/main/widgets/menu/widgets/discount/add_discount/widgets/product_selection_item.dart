import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/models/models.dart';

class FoodProductItem extends StatelessWidget {
  final Stocks stockData;
  final Function() onTap;
  final bool isSelected;

  const FoodProductItem({
    super.key,
    required this.stockData,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: REdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppStyle.white,
            borderRadius: BorderRadius.circular(10.r),
          ),
          padding: REdgeInsets.all(18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 18.r,
                height: 18.r,
                decoration: BoxDecoration(
                  color: isSelected ? AppStyle.primary : AppStyle.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppStyle.primary : AppStyle.selectedItemsText,
                    width: isSelected ? 2 : 2,
                  ),
                ),
                child: isSelected
                    ? Icon(
                        FlutterRemix.check_fill,
                        size: 12.r,
                        color: AppStyle.white,
                      )
                    : const SizedBox.shrink(),
              ),
              12.horizontalSpace,
              Flexible(
                child: SizedBox(
                  width: MediaQuery.sizeOf(context).width - 110.r,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${stockData.product?.translation?.title}",
                        style: GoogleFonts.inter(
                            fontSize:14.sp,
                          color: AppStyle.black,
                          fontWeight: FontWeight.w400
                        ),
                      ),
                      6.horizontalSpace,
                      for (Extras e in stockData.extras ?? [])
                        if (ExtrasType.color !=
                            AppHelpers.getExtraTypeByValue(e.group?.type))
                          Row(
                            children: [
                              Text(
                                "${e.group?.translation?.title}:",
                                style: GoogleFonts.inter(
                                  fontSize: 14.sp,
                                  color: AppStyle.black,
                                  fontWeight: FontWeight.w400
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              2.horizontalSpace,
                              Text(
                                e.value ?? "",
                                style: GoogleFonts.inter(
                                    fontSize: 14.sp,
                                    color: AppStyle.black,
                                    fontWeight: FontWeight.w400
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              6.horizontalSpace,
                            ],
                          ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

