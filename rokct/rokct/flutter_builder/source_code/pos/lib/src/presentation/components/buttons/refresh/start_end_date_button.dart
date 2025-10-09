import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/local_storage.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/app_helpers.dart';
import '../../../pages/main/riverpod/provider/main_provider.dart';
import '../../../pages/main/widgets/income/riverpod/income_provider.dart';
import '../../../pages/main/widgets/orders_table/order_table_riverpod/order_table_provider.dart';
import '../../../pages/main/widgets/tables/riverpod/tables_provider.dart';
import '../../../theme/theme.dart';
import '../../../components/buttons/animation_button_effect.dart';
import '../../../components/filter_screen.dart';

class StartEndDateButton extends ConsumerStatefulWidget {
  const StartEndDateButton({super.key});

  @override
  ConsumerState<StartEndDateButton> createState() => _StartEndDateButtonState();
}

class _StartEndDateButtonState extends ConsumerState<StartEndDateButton> {
  bool _isHovered = false;

  bool _shouldShowDateFilter(int currentIndex, String? userRole) {
    switch (currentIndex) {
      case 1: // Orders Tables page
        return userRole == TrKeys.seller || userRole == TrKeys.waiter;

      case 3: // Tables page
        return userRole == TrKeys.seller || userRole == TrKeys.waiter;

      case 5: // Income page
        return userRole == TrKeys.seller;

      default:
        return false;
    }
  }

  Widget _buildFilterScreen(int currentIndex, WidgetRef ref) {
    switch (currentIndex) {
      case 1: // Orders Tables
        return const FilterScreen(isOrder: true);

      case 3: // Tables
        return FilterScreen(
          isTable: true,
          isBooking: ref.read(tablesProvider).isListView,
        );

      case 5: // Income
        return const FilterScreen();

      default:
        return const FilterScreen();
    }
  }

  DateTime? _getStartDate(WidgetRef ref, int currentIndex) {
    switch (currentIndex) {
      case 1:
        return ref.watch(orderTableProvider).start;
      case 3:
        return ref.watch(tablesProvider).start;
      case 5:
        return ref.watch(incomeProvider).start;
      default:
        return null;
    }
  }

  DateTime? _getEndDate(WidgetRef ref, int currentIndex) {
    switch (currentIndex) {
      case 1:
        return ref.watch(orderTableProvider).end;
      case 3:
        return ref.watch(tablesProvider).end;
      case 5:
        return ref.watch(incomeProvider).end;
      default:
        return null;
    }
  }

  void _showFilterDialog(BuildContext context, int currentIndex, WidgetRef ref) {
    AppHelpers.showAlertDialog(
      context: context,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 3,
        child: _buildFilterScreen(currentIndex, ref),
      ),
      backgroundColor: AppStyle.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(mainProvider).selectIndex;
    final userRole = LocalStorage.getUser()?.role;

    if (!_shouldShowDateFilter(currentIndex, userRole)) {
      return const SizedBox.shrink();
    }

    final startDate = _getStartDate(ref, currentIndex);
    final endDate = _getEndDate(ref, currentIndex);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () => _showFilterDialog(context, currentIndex, ref),
        child: AnimationButtonEffect(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 10.r, horizontal: 16.r),
            decoration: BoxDecoration(
              color: AppStyle.white,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Row(
              children: [
                Icon(
                  FlutterRemix.calendar_check_line,
                  color: _isHovered ? AppStyle.brandGreen : AppStyle.black,
                ),
                if (startDate != null) ...[
                  16.horizontalSpace,
                  Text(
                    "${DateFormat("MMM d,yyyy").format(startDate)} - ${DateFormat("MMM d,yyyy").format(endDate ?? DateTime.now())}",
                    style: GoogleFonts.inter(
                      fontSize: 14.sp,
                      color: AppStyle.black,
                    ),
                  )
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
