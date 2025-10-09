import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../theme/theme.dart';
import 'buttons_bouncing_effect.dart';

class CustomButton extends StatelessWidget {
  final Icon? icon;
  final String title;
  final bool isLoading;
  final Function()? onPressed;
  final Color background;
  final Color borderColor;
  final Color textColor;
  final double weight;
  final double radius;

  const CustomButton({
    super.key,
    required this.title,
    required this.onPressed,
    required this.background,
    required this.textColor,
    required this.borderColor,
    this.isLoading = false,
    this.weight = double.infinity,
    this.radius = 8,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ButtonsBouncingEffect(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          side: BorderSide(
              color: borderColor == Colors.transparent ? background : borderColor,
              width: 2.r),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius.r),
          ),
          minimumSize: Size(weight, 50.h),
          backgroundColor: background,
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
          width: 20.r,
          height: 20.r,
          child: CircularProgressIndicator(
            color: textColor,
            strokeWidth: 2.r,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon == null
                ? const SizedBox()
                : Row(
              children: [
                icon!,
                10.horizontalSpace,
              ],
            ),
            Text(
              title,
              style: AppStyle.interNormal(
                size: 15,
                color: textColor,
                letterSpacing: -14 * 0.01,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
