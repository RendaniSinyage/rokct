import 'package:admin_desktop/src/core/constants/constants.dart';
import 'package:admin_desktop/src/core/utils/utils.dart';
import 'package:admin_desktop/src/models/response/income_chart_response.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../../theme/theme.dart';

class ChartPage extends StatefulWidget {
  final List<num> price;
  final List<DateTime> times;
  final List<IncomeChartResponse> chart;
  final bool isDay;

  const ChartPage(
      {super.key,
        required this.price,
        required this.chart,
        required this.times,
        required this.isDay});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  List<Color> gradientColors = [
    AppStyle.primary.withOpacity(0.5),
    AppStyle.transparent,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260.h,
      padding: EdgeInsets.only(
        left: 12.r,  // Reduced left padding to accommodate axis labels
        //right: 12.r,
        top: 30.r,
        bottom: 12.r, // Reduced bottom padding
      ),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.r), color: AppStyle.white),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppHelpers.getTranslation(TrKeys.saleChart),
            style: GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight: FontWeight.w600,
                color: AppStyle.black),
          ),
          24.verticalSpace,
          Expanded(
            child: widget.chart.isNotEmpty
                ? LineChart(
              mainData(),
            )
                : Center(
              child: Text(
                AppHelpers.getTranslation(TrKeys.needOrder),
                style: GoogleFonts.inter(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w600,
                    color: AppStyle.black),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    final style = GoogleFonts.inter(
      fontSize: 10.sp,
      color: AppStyle.black,
    );

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
          DateFormat(widget.isDay ? "HH:00" : "MMM d")
              .format(widget.times[value.ceil()]),
          style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    final style = GoogleFonts.inter(
      fontSize: 12.sp,
      color: AppStyle.black,
    );
    return Text(
        AppHelpers.numberFormat(
          widget.price[value.toInt()],
          decimalDigits: 0,
        ),
        style: style,
        textAlign: TextAlign.left);
  }

  String getTooltipText(double x, double y) {
    final date = widget.times[x.toInt()];
    final amount = widget.price[y.toInt()];
    return '${DateFormat(widget.isDay ? "HH:00" : "MMM d").format(date)}\n${NumberFormat.currency(
      decimalDigits: 0,
      symbol: LocalStorage.getSelectedCurrency().symbol,
    ).format(amount)}';
  }

  LineChartData mainData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return const FlLine(
              color: AppStyle.iconButtonBack, strokeWidth: 1, dashArray: [10]);
        },
      ),
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          //tooltipBgColor: AppStyle.black.withOpacity(0.8),
          tooltipRoundedRadius: 8.r,
          tooltipPadding: EdgeInsets.symmetric(horizontal: 12.r, vertical: 8.r),
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((spot) {
              return LineTooltipItem(
                getTooltipText(spot.x, spot.y),
                GoogleFonts.inter(
                  color: AppStyle.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList();
          },
        ),
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((index) {
            return TouchedSpotIndicatorData(
              FlLine(
                color: AppStyle.primary,
                strokeWidth: 2,
              ),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: AppStyle.white,
                  strokeWidth: 2,
                  strokeColor: AppStyle.primary,
                ),
              ),
            );
          }).toList();
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30.r,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 80.r,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: false,
      ),
      minX: 0,
      maxX: widget.times.length.toDouble() - 1,
      minY: 0,
      maxY: 6,
      lineBarsData: [
        LineChartBarData(
          spots: [
            for (int index = 0; index < widget.times.length; index++)
              FlSpot(
                  index.toDouble(),
                  widget.price.findPriceIndex(widget.isDay
                      ? widget.chart.findPriceWithHour(widget.times[index])
                      : widget.chart.findPrice(widget.times[index]))),
          ],
          isCurved: true,
          color: AppStyle.primary,
          barWidth: 5,
          isStrokeCapRound: true,
          dotData: const FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
            ),
          ),
        ),
      ],
    );
  }
}
