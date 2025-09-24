import 'package:admin_desktop/src/presentation/components/buttons/confirm_button.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/profile/edit_profile/riverpod/provider/edit_profile_provider.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';

class SelectMap extends ConsumerWidget {
  const SelectMap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifierMap = ref.read(editProfileProvider.notifier);
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Container(
        height: MediaQuery.sizeOf(context).height / 4,
        width: (MediaQuery.sizeOf(context).width - 100) / 4,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r),
          color: AppStyle.white,
        ),
        padding: REdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
        AppHelpers.getTranslation(
        TrKeys.selectMap),
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 28.r),
            ),
            20.verticalSpace,
            ConfirmButton(
                title: AppHelpers.getTranslation(
                    TrKeys.shopLocation),
                onTap: () {
                  Navigator.pop(context);
                  notifierMap.setShopEdit(2);
                }),
            16.verticalSpace,
            ConfirmButton(
                title: AppHelpers.getTranslation(
                    TrKeys.deliveryZone),
                onTap: () {
                  Navigator.pop(context);
                  notifierMap.setShopEdit(3);
                }),
            16.verticalSpace,
          ],
        ),
      ),
    );
  }
}

