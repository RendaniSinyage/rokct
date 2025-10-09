import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/utils/local_storage.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_helpers.dart';
import '../../../pages/main/widgets/JuvoONE/widgets/dashboard/dash_tabs.dart';
import '../../../pages/main/widgets/JuvoONE/widgets/dashboard/providers/content_provider.dart';
import '../../../pages/main/widgets/customers/components/custom_add_customer_dialog.dart';
import '../../../pages/main/widgets/income/riverpod/income_provider.dart';
import '../../../pages/main/widgets/orders_table/order_table_riverpod/order_table_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/sale_history/riverpod/sale_history_provider.dart';
import '../../../pages/main/widgets/orders_table/widgets/view_mode.dart';
import '../../../pages/main/widgets/tables/riverpod/tables_provider.dart';
import '../../../theme/theme.dart';
import '../../../pages/main/riverpod/provider/main_provider.dart';
import '../../components.dart';
import 'package:remixicon/remixicon.dart';

class ViewModeButton extends ConsumerStatefulWidget {
  const ViewModeButton({super.key});

  @override
  ConsumerState<ViewModeButton> createState() => _ViewModeButtonState();
}

class _ViewModeButtonState extends ConsumerState<ViewModeButton> {
  Timer? _textVisibilityTimer;
  bool _showText = false;

  @override
  void dispose() {
    _textVisibilityTimer?.cancel();
    super.dispose();
  }

  void _startTextHideTimer() {
    _textVisibilityTimer?.cancel();
    _textVisibilityTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showText = false;
        });
      }
    });
  }

  bool _shouldShowViewMode(int currentIndex, String? userRole) {
    switch (currentIndex) {
      case 1: // Orders Tables page
        return userRole == TrKeys.seller || userRole == TrKeys.waiter || userRole == 'admin';
      case 2: // Customers page
        return userRole == TrKeys.seller || userRole == 'admin';
      case 3: // Tables page
        return userRole == TrKeys.seller || userRole == TrKeys.waiter;
      case 4: // Sale History page
        return userRole == TrKeys.seller;
      case 5: // Income page
        return userRole == TrKeys.seller;
      case 7: // Income page
        return userRole == TrKeys.seller;
      default:
        return false;
    }
  }

  List<String> _getIncomeList() {
    return [
      TrKeys.day,
      TrKeys.week,
      TrKeys.month,
    ];
  }

  bool _getListViewState(WidgetRef ref, int currentIndex) {
    switch (currentIndex) {
      case 1:
        return ref.watch(orderTableProvider).isListView;
      case 3:
        return ref.watch(tablesProvider).isListView;
      default:
        return false;
    }
  }

  void _handleViewModeChange(WidgetRef ref, int currentIndex, int mode) {
    setState(() {
      _showText = true;
    });
    _startTextHideTimer();

    switch (currentIndex) {
      case 1:
        ref.read(orderTableProvider.notifier).changeViewMode(mode);
        break;
      case 3:
        ref.read(tablesProvider.notifier).changeViewMode(mode);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final currentIndex = ref.watch(mainProvider).selectIndex;
    final userRole = LocalStorage.getUser()?.role;

    if (!_shouldShowViewMode(currentIndex, userRole)) {
      return const SizedBox.shrink();
    }

    // Special case for Income page
    if (currentIndex == 5 && userRole == TrKeys.seller) {
      final state = ref.watch(incomeProvider);
      final event = ref.read(incomeProvider.notifier);
      final list = _getIncomeList();

      return Row(
        children: [
          ...list.map(
                (e) => GestureDetector(
              onTap: () {
                event.changeIndex(e);
              },
              child: AnimationButtonEffect(
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 12.r, horizontal: 18.r),
                  margin: EdgeInsets.only(right: 8.r),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10.r),
                    color: state.selectType == e
                        ? AppStyle.primary
                        : AppStyle.white,
                  ),
                  child: Text(
                    AppHelpers.getTranslation(e),
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: state.selectType == e
                          ? AppStyle.white
                          : AppStyle.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Special case for Sale History page
    if (currentIndex == 4 && userRole == TrKeys.seller) {
      final state = ref.watch(saleHistoryProvider);
      final notifier = ref.read(saleHistoryProvider.notifier);
      List statusList = [TrKeys.cashDrawer, TrKeys.todaySale, TrKeys.saleHistory];

      return Row(
        children: [
          ...statusList.asMap().entries.map((entry) {
            int i = entry.key;
            String status = entry.value;
            return Padding(
              padding: REdgeInsets.only(left: 8),
              child: ConfirmButton(
                paddingSize: 18,
                textSize: 14,
                isActive: state.selectIndex == i,
                title: AppHelpers.getTranslation(status),
                textColor: AppStyle.black,
                isTab: true,
                isShadow: true,
                onTap: () => notifier.changeIndex(i),
              ),
            );
          }),
        ],
      );
    }

  ///For Dashboard
    if (currentIndex == 7 && userRole == TrKeys.seller) {
      final selectedViewMode = ref.watch(dashboardViewModeProvider);

      return Row(
        children: [
          ...dashboardTabTitles.asMap().entries.map((entry) {
            int i = entry.key;
            String title = entry.value;
            return Padding(
              padding: REdgeInsets.only(left: 8),
              child: ConfirmButton(
                paddingSize: 18,
                textSize: 14,
                isActive: selectedViewMode == i,
                title: AppHelpers.getTranslation(title),
                textColor: AppStyle.black,
                isTab: true,
                isShadow: true,
                onTap: () {
                  // Change view mode
                  ref.read(dashboardViewModeProvider.notifier).changeViewMode(i);

                  // Change content based on tab
                  ref.read(dashboardContentProvider.notifier).changeContent(
                      dashboardTabWidgets[i]
                  );
                },
              ),
            );
          }),
        ],
      );
    }

    if (currentIndex == 2 && userRole == 'admin') {
      final selectedViewMode = ref.watch(dashboardViewModeProvider);

      return Row(
        children: [
          ...dashboardTabTitles.asMap().entries.map((entry) {
            int i = entry.key;
            String title = entry.value;
            return Padding(
              padding: REdgeInsets.only(left: 8),
              child: ConfirmButton(
                paddingSize: 18,
                textSize: 14,
                isActive: selectedViewMode == i,
                title: AppHelpers.getTranslation(title),
                textColor: AppStyle.black,
                isTab: true,
                isShadow: true,
                onTap: () {
                  // Change view mode
                  ref.read(dashboardViewModeProvider.notifier).changeViewMode(i);

                  // Change content based on tab
                  ref.read(dashboardContentProvider.notifier).changeContent(
                      dashboardTabWidgets[i]
                  );
                },
              ),
            );
          }),
        ],
      );
    }

    // Special case for Customers page
    if (currentIndex == 2 && userRole == TrKeys.seller) {
      return IconTextButton(
        radius: BorderRadius.circular(10.r),
        height: 56.r,
        backgroundColor: AppStyle.primary,
        iconData: Icons.add,
        icon: AppStyle.black,
        title: AppHelpers.getTranslation(TrKeys.addCustomer),
        textColor: AppStyle.black,
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddCustomerDialog(),
          );
        },
      );
    }

    // Modified view mode implementation for board/list view
    final isListView = _getListViewState(ref, currentIndex);

    return Row(
      children: [
        if (!isListView)
          ViewMode(
            title: AppHelpers.getTranslation(TrKeys.board),
            isActive: true,
            showText: _showText,
            icon: Remix.dashboard_line,
            onTap: () => _handleViewModeChange(ref, currentIndex, 1),
          )
        else
          ViewMode(
            title: AppHelpers.getTranslation(TrKeys.list),
            isActive: true,
            showText: _showText,
            icon: Remix.menu_fill,
            onTap: () => _handleViewModeChange(ref, currentIndex, 0),
          ),
      ],
    );
  }
}
