import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/core/utils/local_storage.dart';
import 'package:admin_desktop/src/presentation/components/custom_scaffold.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/sale_history/riverpod/sale_history_notifier.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/sale_history/riverpod/sale_history_state.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/sale_history/sale_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/JuvoONE/components/close_shift_dialog.dart';
import '../../../../components/components.dart';
import '../../../../theme/app_style.dart';
import 'riverpod/sale_history_provider.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class SaleHistory extends ConsumerStatefulWidget {
  const SaleHistory({super.key});

  @override
  ConsumerState<SaleHistory> createState() => _SaleHistoryState();
}

class _SaleHistoryState extends ConsumerState<SaleHistory> {
  double _floatAmount = 0.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(saleHistoryProvider.notifier)
        ..fetchSale()
        ..fetchSaleCarts();
      _loadFloatAmount();
    });
  }

  Future<void> _loadFloatAmount() async {
    double amount = LocalStorage.getFloatAmount();
    setState(() {
      _floatAmount = amount;
    });
  }

  bool get _isDesktop {
    return !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  }

  void _showFloatDialog() {
    final TextEditingController controller = TextEditingController(text: _floatAmount.toString());
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          AppHelpers.getTranslation(TrKeys.openingDrawerAmount),
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: AppStyle.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: AppStyle.black),
              decoration: InputDecoration(
                prefix: Text(
                  '${LocalStorage.getSelectedCurrency().symbol} ',
                  style: TextStyle(color: AppStyle.black),
                ),
                hintText: AppHelpers.getTranslation(TrKeys.amount),
                hintStyle: TextStyle(color: AppStyle.black.withOpacity(0.5)),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: AppStyle.black),
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            16.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.enableJuvoONE
                          ? AppStyle.blueBonus
                          : AppStyle.brandGreen,
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onPressed: () async {
                      if (controller.text.isNotEmpty) {
                        double amount = double.parse(controller.text);
                        await LocalStorage.setFloatAmount(amount);
                        setState(() {
                          _floatAmount = amount;
                        });
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      }
                    },
                    child: Text(
                      AppHelpers.getTranslation(TrKeys.confirm),
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: AppStyle.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: AppStyle.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(saleHistoryProvider);
    final event = ref.read(saleHistoryProvider.notifier);
    bool isDesktop = _isDesktop;
    return CustomScaffold(
      body: (c) => ListView(
        padding: EdgeInsets.symmetric(vertical: 20.r, horizontal: 16.r),
        shrinkWrap: true,
        children: [
          if (state.selectIndex == 2) _saleCarts(state),
          16.verticalSpace,
          SaleTab(
            isMoreLoading: state.isMoreLoading,
            isLoading: state.isLoading,
            list: state.selectIndex == 0
                ? state.listDriver
                : state.selectIndex == 1
                ? state.listToday
                : state.listHistory,
            hasMore: state.hasMore,
            viewMore: () {
              event.fetchSalePage();
            },
          )
        ],
      ),
    );
  }

  Widget _saleCarts(SaleHistoryState state) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 30.r),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: AppStyle.white),
            child: InkWell(
              onTap: () async {
                // First check if there's an unclosed shift
                if (LocalStorage.needsToCloseShift()) {
                  if (context.mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => CloseShiftDialog(
                        onLogout: () {
                          // Handle closing previous shift
                          LocalStorage.closeShift();
                          Navigator.of(context).pop();
                          // Show new float dialog after closing shift
                          _showFloatDialog();
                        },
                      ),
                    );
                  }
                } else {
                  _showFloatDialog();
                }
              },
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppHelpers.getTranslation(TrKeys.openingDrawerAmount),
                        style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          color: AppStyle.black,
                        ),
                      ),
                      20.verticalSpace,
                      Text(
                        NumberFormat.currency(
                          symbol: LocalStorage.getSelectedCurrency().symbol,
                        ).format(_floatAmount),
                        style: GoogleFonts.inter(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w600,
                          color: AppStyle.black,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppStyle.primary.withOpacity(0.01),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 32.r,
                          spreadRadius: 12.r,
                          color: AppStyle.primary.withOpacity(0.5),
                        )
                      ],
                    ),
                    child: const Icon(
                      Remix.wallet_3_fill,
                      color: AppStyle.black,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 30.r),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: AppStyle.white),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.getTranslation(TrKeys.cashPaymentSale),
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        color: AppStyle.black,
                      ),
                    ),
                    20.verticalSpace,
                    Text(
                      NumberFormat.currency(
                        symbol: LocalStorage.getSelectedCurrency().symbol,
                      ).format(state.saleCart?.cash ?? 0),
                      style: GoogleFonts.inter(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w600,
                        color: AppStyle.black,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppStyle.starColor.withOpacity(0.01),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 32.r,
                        spreadRadius: 12.r,
                        color: AppStyle.starColor.withOpacity(0.5),
                      )
                    ],
                  ),
                  child: const Icon(
                    Remix.money_dollar_circle_fill,
                    color: AppStyle.black,
                  ),
                )
              ],
            ),
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 30.r),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: AppStyle.white),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.getTranslation(TrKeys.otherPaymentSale),
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        color: AppStyle.black,
                      ),
                    ),
                    20.verticalSpace,
                    Text(
                      NumberFormat.currency(
                        symbol: LocalStorage.getSelectedCurrency().symbol,
                      ).format(ref.read(saleHistoryProvider.notifier).getNonCashTotal()),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 24.sp,
                        color: AppStyle.black,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppStyle.blue.withOpacity(0.01),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 32.r,
                        spreadRadius: 12.r,
                        color: AppStyle.blue.withOpacity(0.5),
                      )
                    ],
                  ),
                  child: const Icon(
                    Remix.bank_card_fill,
                    color: AppStyle.black,
                  ),
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _topWidgets(SaleHistoryState state, SaleHistoryNotifier notifier) {
    List statusList = [TrKeys.cashDrawer, TrKeys.todaySale, TrKeys.saleHistory];
    return Row(
      children: [
        const Icon(
          Remix.equalizer_2_fill,
          color: AppStyle.black,
        ),
        for (int i = 0; i < statusList.length; i++)
          Padding(
            padding: REdgeInsets.only(left: 8),
            child: ConfirmButton(
              paddingSize: 18,
              textSize: 14,
              isActive: state.selectIndex == i,
              title: AppHelpers.getTranslation(statusList[i]),
              textColor: AppStyle.black,
              isTab: true,
              isShadow: true,
              onTap: () => notifier.changeIndex(i),
            ),
          )
      ],
    );
  }
}
