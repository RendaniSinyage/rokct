import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import '../../../../../../../core/constants/constants.dart';
import '../../../../../../theme/theme.dart';
import 'components/badges/temperature_badge.dart';
import 'service/open_weather_icon_mapper.dart';
import 'service/open_weather_service.dart';

class ExtendedForecastView extends ConsumerWidget {
  const ExtendedForecastView({super.key});

  Widget _buildForecastCard({
    required DateTime date,
    required double temperature,
    required Map<String, dynamic> condition,
    required int rainChance,
  }) {
    return Padding(
      padding: EdgeInsets.only(right: 16.w),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60.sp,
                height: 60.sp,
                decoration: BoxDecoration(
                  color: AppStyle.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: AppConstants.weatherIcon
                    ? Image.network(
                  OpenWeatherIconMapper.getIconUrl(condition['icon']),
                  width: 60.sp,
                  height: 60.sp,
                )
                    : Icon(
                  OpenWeatherIconMapper.getRemixIcon(condition['icon']),
                  size: 60.sp,
                  color: AppStyle.black,
                ),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: TemperatureBadge(
                  temperature: temperature.round(),
                  fontSize: 12,
                ),
              ),
              if (rainChance > AppConstants.rainPOP)
                Positioned(
                  right: -4,
                  top: 20,
                  child: TemperatureBadge(
                    temperature: rainChance,
                    suffix: '%',
                    fontSize: 12,
                    backgroundColor: AppStyle.red,
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            DateFormat('EEEE').format(date),
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: AppStyle.black,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            condition['description'].toString().capitalize(),
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              letterSpacing: -0.3,
              color: AppStyle.icon,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openWeatherAsync = ref.watch(openWeatherProvider);

    return openWeatherAsync.when(
      data: (state) {
        final additionalDays = state.getAdditionalDaysData();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Divider(
                color: AppStyle.black.withOpacity(0.1),
                height: 1,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: additionalDays.map((forecast) {
                    final day = forecast['day'];
                    final condition = day['condition'];
                    final date = DateTime.parse(forecast['date']);

                    return _buildForecastCard(
                      date: date,
                      temperature: day['avgtemp_c'],
                      condition: condition,
                      rainChance: day['daily_chance_of_rain'],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => Padding(
        padding: EdgeInsets.all(24.sp),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppStyle.black),
          ),
        ),
      ),
      error: (error, stackTrace) => Padding(
        padding: EdgeInsets.all(24.sp),
        child: Center(
          child: Text(
            'Failed to load extended forecast',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppStyle.icon,
            ),
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
