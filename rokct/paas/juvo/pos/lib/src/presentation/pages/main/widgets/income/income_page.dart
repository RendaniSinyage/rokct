import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/app_helpers.dart';
import 'package:admin_desktop/src/core/utils/local_storage.dart';
import 'package:admin_desktop/src/models/response/income_statistic_response.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/income/riverpod/income_provider.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/income/riverpod/income_state.dart';
import 'package:admin_desktop/src/presentation/pages/main/widgets/income/widgets/statistics_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_remix/flutter_remix.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import '../../../../components/custom_scaffold.dart';
import '../../../../theme/theme.dart';
import 'widgets/chart_page.dart';
import 'widgets/pie_chart.dart';

class InComePage extends ConsumerStatefulWidget {
  const InComePage({super.key});

  @override
  ConsumerState<InComePage> createState() => _InComePageState();
}

class _InComePageState extends ConsumerState<InComePage> {
  List list = [
    TrKeys.day,
    TrKeys.week,
    TrKeys.month,
  ];

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(incomeProvider.notifier)
        ..fetchIncomeCarts()
        ..fetchIncomeCharts()
        ..fetchIncomeStatistic()
        ..fetchExpenseData();
    });
    super.initState();
  }

  bool get _isDesktop {
    return !kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(incomeProvider);
    final event = ref.read(incomeProvider.notifier);
    return CustomScaffold(
      body: (colors) => SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20.r, horizontal: 16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _carts(state),
              10.verticalSpace,


              Row(
                children: [
                  PieChartPage(
                    statistic:
                        state.incomeStatistic ?? IncomeStatisticResponse(),
                  ),
                  10.horizontalSpace,
                  StatisticPage(statistic: state.incomeStatistic)
                ],
              ),
              10.verticalSpace,
              ChartPage(
                isDay: state.selectType == TrKeys.day,
                price: state.prices,
                chart: state.incomeCharts ?? [],
                times: state.time,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carts(IncomeState state) {
    final isManualDateSelected = state.start != null && state.end != null;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 30.r),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: AppStyle.white),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.getTranslation(TrKeys.revenue),
                      style: GoogleFonts.inter(
                          fontSize: 22.sp, fontWeight: FontWeight.w600,
                          color: AppStyle.black),
                    ),
                    16.verticalSpace,
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppStyle.green[500],
                          ),
                          padding: EdgeInsets.all(10.r),
                          child: const Icon(Remix.arrow_left_down_line),
                        ),
                        10.horizontalSpace,
                        Text(
                          NumberFormat.currency(
                            symbol: LocalStorage.getSelectedCurrency()
                                .symbol,
                          ).format(state.incomeCart?.revenue ?? 0),
                          style: GoogleFonts.inter(
                              fontSize: 24.sp, fontWeight: FontWeight.w600,
                              color: AppStyle.black),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    state.incomeCart?.revenueType == TrKeys.plus
                        ? Icon(
                      FlutterRemix.arrow_up_line,
                      color: AppStyle.inStockText,
                      size: 18.r,
                    )
                        : Icon(
                      FlutterRemix.arrow_down_line,
                      color: AppStyle.red,
                      size: 18.r,
                    ),
                    4.horizontalSpace,
                    Text(
                      "${state.incomeCart?.revenuePercent?.ceil() ?? 0}%",
                      style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          color: state.incomeCart?.revenueType == TrKeys.plus
                              ? AppStyle.inStockText
                              : AppStyle.red),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
        12.horizontalSpace,
       // if (!isManualDateSelected)
          Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.r, vertical: 30.r),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.r),
                color: AppStyle.white),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.getTranslation(TrKeys.profit),
                      style: GoogleFonts.inter(
                          fontSize: 22.sp, fontWeight: FontWeight.w600,
                          color: AppStyle.black),
                    ),
                    16.verticalSpace,
                    Row(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppStyle.revenueColor,
                          ),
                          padding: EdgeInsets.all(10.r),
                          child: const Icon(Remix.goblet_2_fill),
                        ),
                        10.horizontalSpace,
                        Text(
                          NumberFormat.currency(
                            symbol: LocalStorage.getSelectedCurrency()
                                .symbol,
                          ).format(state.expenseRevenue?.profit ?? 0),
                          style: GoogleFonts.inter(
                              fontSize: 24.sp, fontWeight: FontWeight.w600,
                              color: AppStyle.black),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    state.expenseRevenue?.expenseType == TrKeys.plus
                        ? Icon(
                      FlutterRemix.arrow_up_line,
                      color: AppStyle.inStockText,
                      size: 18.r,
                    )
                        : Icon(
                      FlutterRemix.arrow_down_line,
                      color: AppStyle.red,
                      size: 18.r,
                    ),
                    4.horizontalSpace,
                    Text(
                      "${state.expenseRevenue?.expensePercent?.ceil() ?? 0}%",
                      style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          color: state.expenseRevenue?.expenseType == TrKeys.plus
                              ? AppStyle.inStockText
                              : AppStyle.red),
                    ),
                  ],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.getTranslation(TrKeys.orders),
                      style: GoogleFonts.inter(
                          fontSize: 22.sp, fontWeight: FontWeight.w600,
                          color: AppStyle.black),
                    ),
                    16.verticalSpace,
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppStyle.primary,
                          ),
                          padding: EdgeInsets.all(10.r),
                          child: const Icon(
                            FlutterRemix.shopping_cart_fill,
                            color: AppStyle.white,
                          ),
                        ),
                        10.horizontalSpace,
                        Text(
                          AppHelpers.numberFormat(
                            state.incomeCart?.orders ?? 0,
                          ),
                          style: GoogleFonts.inter(
                              fontSize: 24.sp, fontWeight: FontWeight.w600,
                              color: AppStyle.black),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    state.incomeCart?.ordersType == TrKeys.plus
                        ? Icon(
                            FlutterRemix.arrow_up_line,
                            color: AppStyle.inStockText,
                            size: 18.r,
                          )
                        : Icon(
                            FlutterRemix.arrow_down_line,
                            color: AppStyle.red,
                            size: 18.r,
                          ),
                    4.horizontalSpace,
                    Text(
                      "${state.incomeCart?.ordersPercent?.ceil() ?? 0}%",
                      style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          color: state.incomeCart?.ordersType == TrKeys.plus
                              ? AppStyle.inStockText
                              : AppStyle.red),
                    ),
                  ],
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppHelpers.getTranslation(TrKeys.average),
                      style: GoogleFonts.inter(
                          fontSize: 22.sp, fontWeight: FontWeight.w600,
                      color: AppStyle.black),
                    ),
                    16.verticalSpace,
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppStyle.green[600],
                          ),
                          padding: EdgeInsets.all(10.r),
                          child: const Icon(Remix.arrow_up_down_line),
                        ),
                        10.horizontalSpace,
                        Text(
                          AppHelpers.numberFormat(
                            state.incomeCart?.average ?? 0,
                          ),
                          style: GoogleFonts.inter(
                              fontSize: 24.sp, fontWeight: FontWeight.w600,
                          color: AppStyle.black),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    state.incomeCart?.averageType == TrKeys.plus
                        ? Icon(
                            FlutterRemix.arrow_up_line,
                            color: AppStyle.inStockText,
                            size: 18.r,
                          )
                        : Icon(
                            FlutterRemix.arrow_down_line,
                            color: AppStyle.red,
                            size: 18.r,
                          ),
                    4.horizontalSpace,
                    Text(
                      "${state.incomeCart?.averagePercent?.ceil() ?? 0}%",
                      style: GoogleFonts.inter(
                          fontSize: 16.sp,
                          color: state.incomeCart?.averageType == TrKeys.plus
                              ? AppStyle.inStockText
                              : AppStyle.red),
                    ),
                  ],
                )
              ],
            ),
          ),
        )
      ],
    );
  }

}

