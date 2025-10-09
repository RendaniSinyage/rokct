import 'package:admin_desktop/src/presentation/theme/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/data/product_data.dart';

class ProductListItem extends StatelessWidget {
  final ProductData product;
  final Function() onTap;
  final bool isSelected;

  const ProductListItem({
    super.key,
    required this.product,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppStyle.white,
          borderRadius: BorderRadius.circular(10.r),
        ),
        padding: REdgeInsets.all(18),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18.r,
                height: 18.r,
                margin: EdgeInsets.only(right: 10.r),
                decoration: BoxDecoration(
                  color:
                      isSelected ? AppStyle.primary : AppStyle.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: !isSelected
                          ? AppStyle.hint
                          : AppStyle.primary),
                ),
                child: Icon(
                  FlutterRemix.check_line,
                  color: AppStyle.white,
                  size: 16.r,
                ),
              ),
              16.horizontalSpace,
              Expanded(
                child: Text(
                  product.translation?.title ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 15.sp,
                    color: AppStyle.black,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

