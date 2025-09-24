import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/helper/blur_wrap.dart';
import '../../theme/app_style.dart';
import '../custom_toggle.dart';

class LogoutButton extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onChange;

  const LogoutButton({super.key, required this.isOpen, required this.onChange});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 6.r,
      right: 16.r,
      child: Row(
        children: [
          BlurWrap(
            radius: BorderRadius.circular(10.r),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: AppStyle.black.withOpacity(0.29),
              ),
              padding: EdgeInsets.all(4.r),
              child: CustomToggle(
                isText: true,
                key: UniqueKey(),
                controller: ValueNotifier<bool>(isOpen),
                onChange: (value) {
                  onChange();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

