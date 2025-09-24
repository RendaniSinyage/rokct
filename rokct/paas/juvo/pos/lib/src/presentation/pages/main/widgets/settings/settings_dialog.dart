import 'package:admin_desktop/src/core/routes/app_router.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';

import '../../../../../core/constants/constants.dart';
import '../../../../../core/utils/app_helpers.dart';
import '../../../../../core/utils/local_storage.dart';
import '../../../../theme/app_style.dart';
import '../JuvoONE/components/toggles/maintenance_data_toggle.dart';
import '../JuvoONE/utils/open_cash_drawer.dart';
import '../JuvoONE/widgets/toggles.dart';
import '../language/languages_modal.dart';
import '../language/riverpod/provider/languages_provider.dart';
import '../menu/widgets/deliveries/deliveries_page.dart';
import '../menu/widgets/discount/discount_page.dart';
import '../menu/widgets/stories/stories/stories_page.dart';
import '../profile/edit_profile/edit_profile_page.dart';

class SettingsMenu extends ConsumerWidget {
  const SettingsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = LocalStorage.getUser();
    final isSeller = user?.role == TrKeys.seller;
    final double menuHeight = isSeller
        ? MediaQuery.of(context).size.height / 1.2  // Original height for sellers
        : MediaQuery.of(context).size.height / 1.8;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: menuHeight,
        width: MediaQuery.of(context).size.width / 4,
        color: AppStyle.white,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Remix.settings_6_fill,
                      color: AppStyle.black),
                  const SizedBox(width: 3),
                  Text(
                    'Settings',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 22,
                      color: AppStyle.black,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(FlutterRemix.close_fill,
                        color: AppStyle.black),
                  ),
                  const Divider(),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  _buildMenuItem(
                    context,
                    icon: Remix.account_pin_box_fill,
                    title: AppHelpers.getTranslation(TrKeys.profile),
                    onTap: () => AppHelpers.showAlertDialog(
                          context: context,
                          child: const ProfilePage(),
                      width: MediaQuery.of(context).size.width - 30.w,),

                  ),
                  _buildMenuItem(
                    context,
                    icon: Remix.question_line,
                    title: AppHelpers.getTranslation(TrKeys.help),
                    onTap: () =>  context.pushRoute(const HelpRoute())
                  ),
                  const Divider(),
                  _buildMenuItem(
                    context,
                    icon: FlutterRemix.global_line,
                    title: AppHelpers.getTranslation(TrKeys.language),
                    onTap: () => _showLanguageDialog(context, ref),
                  ),
                  _buildMenuItem(
                    context,
                    icon: FlutterRemix.percent_line,
                    title: AppHelpers.getTranslation(TrKeys.discount),
                    onTap: () => _showDiscountDialog(context),
                  ),
                  _buildMenuItem(
                    context,
                    icon: FlutterRemix.time_line,
                    title: AppHelpers.getTranslation(TrKeys.stories),
                    onTap: () => _showStoriesDialog(context),
                  ),

                  _buildMenuItem(
                    context,
                    icon: FlutterRemix.truck_line,
                    title: AppHelpers.getTranslation(TrKeys.deliveries),
                    onTap: () => _showDeliveriesDialog(context),
                  ),

                  if (user?.role == TrKeys.seller) ...[
                    const Divider(),
                    _buildMenuItemWithCustomLeading(
                      context,
                      leading: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          border: Border.all(color: AppStyle.black, width: 2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Icon(
                            AppConstants.secondScreen ? Remix.tv_2_fill : Remix.tv_2_line,
                            color: AppStyle.black,
                            size: 18,
                          ),
                        ),
                      ),
                      title: 'Customer Display',
                      onTap: () {},
                      trailing: const SecondScreenToggle(),
                    ),
                  const Divider(),
                  _buildMenuItemWithCustomLeading(
                    context,
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppStyle.black, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          AppConstants.skipPin ? FlutterRemix.lock_unlock_fill : FlutterRemix.lock_fill,
                          color: AppStyle.black,
                          size: 18,
                        ),
                      ),
                    ),
                    title: 'Skip PIN',
                    onTap: () {},
                    trailing: const SkipPINToggle(),
                  ),
                  _buildMenuItemWithCustomLeading(
                    context,
                    leading: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppStyle.black, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          AppConstants.autoDeliver ? FlutterRemix.truck_fill : FlutterRemix.truck_fill,
                          color: AppStyle.black,
                          size: 18,
                        ),
                      ),
                    ),
                    title: 'Auto update Order Status',
                    onTap: () {},
                    trailing: const autoDeliver(),
                  ),
                  _buildMenuItem(
                    context,
                    icon: FlutterRemix.list_settings_line,
                    title: AppHelpers.getTranslation(TrKeys.cashDrawer),
                    onTap: () =>  _showCashDrawerConfigScreenDialog(context),
                  ),
                    16.verticalSpace,
                  ],

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap, Widget? trailing}) {
    return ListTile(
      leading: Icon(icon, color: AppStyle.black),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: AppStyle.black,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildMenuItemWithCustomLeading(BuildContext context,
      {required Widget leading, required String title, required VoidCallback onTap, Widget? trailing}) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 16,
          color: AppStyle.black,
        ),
      ),
      onTap: onTap,
      trailing: trailing,
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    ref.read(languagesProvider.notifier).getLanguages(context);
    showDialog(
        context: context,
        builder: (_) => Dialog(
          alignment: Alignment.center,
          backgroundColor: AppStyle.white,
          child: Container(
            width: MediaQuery.of(context).size.width / 4,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5
            ),
            child: Consumer(
              builder: (context, ref, child) => LanguagesModal(
                afterUpdate: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
        )
    );
  }

  void _showDiscountDialog(BuildContext context) {
    AppHelpers.showAlertDialog(
        context: context,
        child: SizedBox(
          height: MediaQuery.of(context).size.height / 1.5,
          width: MediaQuery.of(context).size.width / 2,
          child: const DiscountPage(),
        ),
        backgroundColor: AppStyle.bg
    );
  }

  void _showStoriesDialog(BuildContext context) {
    AppHelpers.showAlertDialog(
        context: context,
        child: SizedBox(
            height: MediaQuery.of(context).size.height / 1.5,
            width: MediaQuery.of(context).size.width / 2,
            child: const StoriesPage()
        ),
        backgroundColor: AppStyle.white);
  }

  void _showCashDrawerConfigScreenDialog(BuildContext context) {
    AppHelpers.showAlertDialog(
        context: context,
        child: SizedBox(
            height: MediaQuery.of(context).size.height / 1.5,
            width: MediaQuery.of(context).size.width / 2,
            child: const CashDrawerConfigScreen()
        ),
        backgroundColor: AppStyle.white);
  }

  void _showDeliveriesDialog(BuildContext context) {
    AppHelpers.showAlertDialog(
        backgroundColor: AppStyle.bg,
        context: context,
        child: SizedBox(
            height: MediaQuery.of(context).size.height / 1.5,
            width: MediaQuery.of(context).size.width / 2,
            child: const DeliveriesPage()
        )
    );
  }
}
