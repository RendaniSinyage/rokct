import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/menu/widgets/deliveries/deliveries_page.dart';
import 'package:admin_desktop/src/presentation/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/discount/discount_page.dart';
import 'widgets/sections_item.dart';
import 'widgets/stories/stories/stories_page.dart';


class MenuModal extends ConsumerWidget {
  final VoidCallback? afterUpdate;

  const MenuModal({super.key, this.afterUpdate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        SectionsItem(
          onTap: () {
            AppHelpers.showAlertDialog(
                context: context,
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height / 1.5,
                  width: MediaQuery.sizeOf(context).width / 2,
                  child: const DiscountPage(),
                ),
                backgroundColor: AppStyle.bg);
          },
          title: AppHelpers.getTranslation(TrKeys.discount),
          icon: FlutterRemix.percent_line,
        ),
        SectionsItem(
          onTap: () {
            AppHelpers.showAlertDialog(
                context: context,
                child: SizedBox(
                    height: MediaQuery.sizeOf(context).height / 1.5,
                    width: MediaQuery.sizeOf(context).width / 2,
                    child: const StoriesPage()));
          },
          title: AppHelpers.getTranslation(TrKeys.stories),
          icon: FlutterRemix.time_line,
        ),
        //story
        // if(LocalStorage.getShop()?.deliveryType == 2)
        SectionsItem(
          isDivider: false,
          icon: FlutterRemix.truck_line,
          onTap: () {
            AppHelpers.showAlertDialog(
                backgroundColor: AppStyle.bg,
                context: context,
                child: SizedBox(
                    height: MediaQuery.sizeOf(context).height / 1.5,
                    width: MediaQuery.sizeOf(context).width / 2,
                    child: const DeliveriesPage()));
          },
          title: AppHelpers.getTranslation(TrKeys.deliveries),
        ),
      ],
    );
  }
}

