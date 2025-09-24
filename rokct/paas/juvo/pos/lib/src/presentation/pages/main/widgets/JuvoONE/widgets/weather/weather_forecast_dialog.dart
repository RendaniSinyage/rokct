import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import '../../../../../../../core/constants/constants.dart';
import '../../../../../../components/buttons/animation_button_effect.dart';
import '../../../../../../theme/theme.dart';
import '../../../tables/widgets/custom_refresher.dart';
import 'components/badges/temperature_badge.dart';
import 'extended_forecast_loader.dart';
import 'weather_icon.dart';
import 'service/weather_service.dart';
import 'service/weather_state.dart';
import 'service/weather_summary.dart';

class WeatherForecastDialog extends ConsumerWidget {
  final WeatherState weatherState;

  const WeatherForecastDialog({
    super.key,
    required this.weatherState,
  });

  static const minUV = 6;
  static const minHumidity = 40;

  String _cleanText(String text) {
    return text
        .replaceAll(' nearby', '')
        .replaceAll(' possible', '')
        .replaceAll('Patchy ', '');
  }

  Color _getUvBadgeColor(num uvIndex) {
    if (uvIndex >= 11) return AppStyle.red; // Extreme
    if (uvIndex >= 8) return AppStyle.orange; // Very High
    if (uvIndex >= 6) return Color(0xFFFFC107); // High (Yellow)
    if (uvIndex >= 3) return AppStyle.icon; // Moderate
    return AppStyle.black; // Low
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Remix.cloud_off_line,
              color: AppStyle.black,
              size: 48.sp,
            ),
            SizedBox(height: 16.h),
            Text(
              'No forecast data available',
              style: GoogleFonts.inter(
                fontSize: 16.sp,
                color: AppStyle.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHourlyForecast(List<dynamic> hourlyData, DateTime selectedDate) {
    if (hourlyData.isEmpty) {
      return Container(
        height: 100.h,
        child: Center(
          child: Text(
            'No hourly data available',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              color: AppStyle.icon,
            ),
          ),
        ),
      );
    }

    // Separate hours for the specific date
    final dateHours = hourlyData
        .where((hour) =>
    DateTime.parse(hour['time']).day == selectedDate.day &&
        DateTime.parse(hour['time']).month == selectedDate.month &&
        DateTime.parse(hour['time']).year == selectedDate.year)
        .toList();

    // Determine the starting index based on whether it's today or a future date
    int initialStartIndex = 0;
    final isToday = selectedDate.year == DateTime.now().year &&
        selectedDate.month == DateTime.now().month &&
        selectedDate.day == DateTime.now().day;

    if (isToday) {
      final currentHour = DateTime.now().hour;
      initialStartIndex = dateHours.indexWhere(
              (hour) => DateTime.parse(hour['time']).hour >= currentHour);
      initialStartIndex = initialStartIndex == -1 ? 0 : initialStartIndex;
    } else {
      initialStartIndex = dateHours
          .indexWhere((hour) => DateTime.parse(hour['time']).hour >= 6);
      initialStartIndex = initialStartIndex == -1 ? 0 : initialStartIndex;
    }

    final hourStartIndexNotifier = ValueNotifier<int>(initialStartIndex);
    final selectedHourNotifier =
    ValueNotifier<Map<String, dynamic>>(dateHours[initialStartIndex]);

    return ValueListenableBuilder<int>(
      valueListenable: hourStartIndexNotifier,
      builder: (context, startIndex, child) {
        startIndex = startIndex < 0 ? 0 : startIndex;

        final remainingHours = dateHours.length - startIndex;
        final hoursToTake = remainingHours < 24 ? remainingHours : 24;
        final relevantHours =
        dateHours.skip(startIndex).take(hoursToTake).toList();

        return Column(
          children: [
            ValueListenableBuilder<Map<String, dynamic>?>(
              valueListenable: selectedHourNotifier,
              builder: (context, selectedHour, _) {
                if (selectedHour == null) return SizedBox.shrink();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHourlyDetail(selectedHour),
                    SizedBox(height: 16.h),
                    Divider(
                      color: AppStyle.black.withOpacity(0.1),
                      height: 1.h,
                    ),
                    SizedBox(height: 16.h),
                  ],
                );
              },
            ),
            Stack(
              children: [
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _buildNavButton(
                      icon: Remix.arrow_left_circle_fill,
                      onTap: () {
                        if (startIndex >= 6) {
                          final newStartIndex = startIndex - 6;
                          hourStartIndexNotifier.value = newStartIndex;
                          selectedHourNotifier.value = dateHours[newStartIndex];
                        }
                      },
                      isEnabled: startIndex >= 6,
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _buildNavButton(
                      icon: Remix.arrow_right_circle_fill,
                      onTap: () {
                        final nextStartIndex = startIndex + 6;
                        if (nextStartIndex + 5 < dateHours.length) {
                          hourStartIndexNotifier.value = nextStartIndex;
                          selectedHourNotifier.value = dateHours[nextStartIndex];
                        }
                      },
                      isEnabled: startIndex + 6 < dateHours.length &&
                          startIndex + 11 < dateHours.length,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: relevantHours.map((hour) {
                        final hourTime = DateTime.parse(hour['time']);
                        final condition = hour['condition'];

                        return ValueListenableBuilder<Map<String, dynamic>?>(
                          valueListenable: selectedHourNotifier,
                          builder: (context, selectedHour, _) {
                            final isSelected = selectedHour != null &&
                                selectedHour['time'] == hour['time'];

                            return GestureDetector(
                              onTap: () {
                                selectedHourNotifier.value = hour;
                              },
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 3.w),
                                child: Column(
                                  children: [
                                    Text(
                                      DateFormat('HH:mm').format(hourTime),
                                      style: GoogleFonts.inter(
                                        fontSize: 12.sp,
                                        color: AppStyle.black,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Container(
                                      width: 50.sp,
                                      height: 50.sp,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppStyle.black.withOpacity(0.1)
                                            : AppStyle.black.withOpacity(0.05),
                                        borderRadius: BorderRadius.circular(8.r),
                                        border: isSelected
                                            ? Border.all(
                                            color: AppStyle.black, width: 2)
                                            : null,
                                      ),
                                      child: WeatherIcon(
                                        condition: condition,
                                        size: 30.sp,
                                        color: AppStyle.black,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Container(
                                      height: 100.h,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TemperatureBadge(
                                            temperature: hour['temp_c'].round(),
                                            fontSize: 10,
                                          ),
                                          if (hour['chance_of_rain'] >
                                              AppConstants.rainPOP) ...[
                                            SizedBox(height: 4.h),
                                            TemperatureBadge(
                                              temperature: hour['chance_of_rain'],
                                              suffix: '%',
                                              fontSize: 10,
                                              backgroundColor: AppStyle.red,
                                            ),
                                          ],
                                          if (hour['uv'] >= minUV &&
                                              hour['humidity'] >= minHumidity) ...[
                                            SizedBox(height: 4.h),
                                            TemperatureBadge(
                                              temperature: hour['uv'].round(),
                                              suffix: 'UV',
                                              fontSize: 10,
                                              backgroundColor:
                                              _getUvBadgeColor(hour['uv']),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildHourlyDetail(Map<String, dynamic> hour) {
    final hourTime = DateTime.parse(hour['time']);
    final now = DateTime.now();

    if (hourTime.day == now.day && hourTime.hour == now.hour) {
      final todayForecast =
      weatherState.forecast.isNotEmpty ? weatherState.forecast[0] : null;
      if (todayForecast != null) {
        final hourlyData = todayForecast['hour'] as List<dynamic>;
        try {
          final currentHourData = hourlyData.firstWhere(
                (forecastHour) =>
            DateTime.parse(forecastHour['time']).hour == now.hour,
          );
          hour = currentHourData;
        } catch (e) {
          print('Error: Current hour not found in forecast data.');
        }
      }
    }

    final condition = hour['condition'];
    final alerts = hour['alerts']?['alert'] as List? ?? [];
    final uvIndex = hour['uv'] as num;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 80.sp,
                  height: 80.sp,
                  decoration: BoxDecoration(
                    color: AppStyle.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: WeatherIcon(
                    condition: condition,
                    size: 50.sp,
                    color: AppStyle.black,
                  ),
                ),
                Positioned(
                  right: -4,
                  top: -4,
                  child: TemperatureBadge(
                    temperature: hour['temp_c'].round(),
                    fontSize: 14,
                  ),
                ),
                if (hour['will_it_rain'] == 1 &&
                    hour['chance_of_rain'] > AppConstants.rainPOP)
                  Positioned(
                    right: -4,
                    top: 20,
                    child: TemperatureBadge(
                      temperature: hour['chance_of_rain'],
                      suffix: '%',
                      fontSize: 14,
                      backgroundColor: AppStyle.red,
                    ),
                  ),
                if (hour['uv'] != null &&
                    hour['uv'] >= minUV &&
                    hour['humidity'] >= minHumidity)
                  Positioned(
                    right: -4,
                    top: hour['will_it_rain'] == 1 &&
                        hour['chance_of_rain'] > AppConstants.rainPOP
                        ? 44
                        : 20,
                    child: TemperatureBadge(
                      temperature: hour['uv'].round(),
                      suffix: 'UV',
                      fontSize: 14,
                      backgroundColor: _getUvBadgeColor(hour['uv']),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              DateFormat('HH:mm').format(hourTime),
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: AppStyle.black,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              _cleanText(condition['text'].toString()).toCapitalized(),
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                letterSpacing: -0.3,
                color: AppStyle.icon,
                height: 1.2,
              ),
              textAlign: TextAlign.start,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (alerts.isNotEmpty) ...[
              SizedBox(height: 8.h),
              ...alerts.map((alert) => Text(
                '⚠️ ${alert['headline']}',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppStyle.red,
                  height: 1.5,
                ),
              )),
            ],
          ],
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _generateHourlySummary(hour),
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  color: AppStyle.black,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 16.h),
              Wrap(
                spacing: 16.w,
                runSpacing: 8.h,
                children: [
                  _buildSmallDetailItem(
                      Remix.windy_line, '${hour['wind_kph']} km/h'),
                  _buildSmallDetailItem(
                      Remix.compass_3_line, '${hour['wind_degree']}°'),
                  _buildSmallDetailItem(
                      Remix.compass_discover_line, hour['wind_dir']),
                  _buildSmallDetailItem(
                      Remix.temp_hot_line, '${hour['pressure_mb']} mb'),
                  _buildSmallDetailItem(
                      Remix.water_flash_line, '${hour['humidity']}%'),
                  if (hour['precip_mm'] != null && hour['precip_mm'] > 0)
                    _buildSmallDetailItem(
                        Remix.heavy_showers_line, '${hour['precip_mm']} mm'),
                  _buildSmallDetailItem(Remix.cloud_line, '${hour['cloud']}%'),
                  _buildSmallDetailItem(Remix.temp_cold_line,
                      'Feels like ${hour['feelslike_c']}°C'),
                  if (hour['uv'] != null && hour['uv'] > 0)
                    _buildSmallDetailItem(Remix.sun_line,
                        'UV Index: ${hour['uv'] % 1 == 0 ? hour['uv'].round() : hour['uv'].toStringAsFixed(1)}'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _generateHourlySummary(Map<String, dynamic> hour) {
    final hourTime = DateTime.parse(hour['time']);
    final condition = hour['condition'];
    final List<String> summaryParts = [];

    // Build main weather description
    String mainLine = 'At ${DateFormat('HH:mm').format(hourTime)}';
    mainLine += ' it will be ${_cleanText(condition['text']).toLowerCase()}';

    // Add temperature description
    if (hour['temp_c'] >= 35) {
      mainLine +=
      ' with very hot temperature of ${hour['temp_c'].toStringAsFixed(1)}°C';
    } else {
      mainLine += ' with temperature of ${hour['temp_c'].toStringAsFixed(1)}°C';
    }
    summaryParts.add(mainLine);

    // Build conditions line
    List<String> conditions = [];

    // Wind conditions
    if (hour['wind_kph'] >= 40) {
      conditions.add(
          'strong winds with gusts up to ${hour['wind_kph'].round()} km/h');
    }

    // Precipitation
    if (hour['will_it_rain'] == 1 &&
        hour['chance_of_rain'] > AppConstants.rainPOP &&
        hour['precip_mm'] > 0) {
      conditions
          .add('precipitation of ${hour['precip_mm'].toStringAsFixed(1)} mm');
    }

    // Humidity
    conditions.add('humidity will be ${hour['humidity']}%');

    // UV warning
    if (hour['uv'] >= 8) {
      conditions.add('high UV index, take precautions');
    }

    // Feels like temperature if significantly different
    if ((hour['feelslike_c'] - hour['temp_c']).abs() >= 3) {
      conditions
          .add('it will feel like ${hour['feelslike_c'].toStringAsFixed(1)}°C');
    }

    String conditionsLine = conditions.join(', ') + '.';
    conditionsLine =
        conditionsLine[0].toUpperCase() + conditionsLine.substring(1);
    summaryParts.add(conditionsLine);

    return summaryParts.join(' ');
  }

  Widget _buildSmallDetailItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16.sp,
          color: AppStyle.black,
        ),
        SizedBox(width: 4.w),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            color: AppStyle.black,
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isEnabled,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          child: Icon(
            icon,
            color: isEnabled ? AppStyle.black : AppStyle.black.withOpacity(0.2),
            size: 24.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedView(Map<String, dynamic> forecast) {
    final day = forecast['day'];
    final astro = forecast['astro'];
    final date = DateTime.parse(forecast['date']);
    final condition = day['condition'];
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    final showHourly = ValueNotifier<bool>(false);
    List<Widget> allDetails = _buildDetailItems(forecast);

    return LayoutBuilder(
      builder: (context, constraints) {
        final rows = _distributeDetailsInRows(allDetails, constraints);

        return ValueListenableBuilder<bool>(
          valueListenable: showHourly,
          builder: (context, isHourlyView, child) {
            if (isHourlyView) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hourly Forecast - ${isToday ? 'Today' : DateFormat('EEEE').format(date)}',
                    style: GoogleFonts.inter(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                      color: AppStyle.black,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  _buildHourlyForecast(forecast['hour'], date),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                WeatherSummary(
                  forecast: forecast,
                  weatherState: weatherState,

                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  child: Divider(
                    color: AppStyle.black.withOpacity(0.1),
                    height: 1,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (forecast['hour'] != null) {
                      showHourly.value = !showHourly.value;
                    }
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 80.sp,
                            height: 80.sp,
                            decoration: BoxDecoration(
                              color: AppStyle.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: WeatherIcon(
                              condition: condition,
                              size: 50.sp,
                              color: AppStyle.black,
                            ),
                          ),
                          Positioned(
                            right: -4,
                            top: -4,
                            child: TemperatureBadge(
                              temperature: day['avgtemp_c'].round(),
                              fontSize: 14,
                            ),
                          ),
                          if (day['daily_chance_of_rain'] >
                              AppConstants.rainPOP)
                            Positioned(
                              right: -4,
                              top: 20,
                              child: TemperatureBadge(
                                temperature: day['daily_chance_of_rain'],
                                suffix: '%',
                                fontSize: 14,
                                backgroundColor: AppStyle.red,
                              ),
                            ),
                          if (day['uv'] >= minUV &&
                              day['avghumidity'] >= minHumidity)
                            Positioned(
                              right: -4,
                              top: day['daily_chance_of_rain'] >
                                  AppConstants.rainPOP
                                  ? 44
                                  : 20,
                              child: TemperatureBadge(
                                temperature: day['uv'].round(),
                                suffix: 'UV',
                                fontSize: 14,
                                backgroundColor: _getUvBadgeColor(day['uv']),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderInfo(isToday, date, condition),
                            SizedBox(height: 8.h),
                            Wrap(
                              spacing: 16.w,
                              runSpacing: 8.h,
                              children: allDetails,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentWeatherDetailView(Map<String, dynamic> currentWeather) {
    if (currentWeather == null) {
      return _buildEmptyState();
    }

    // Get current hour data from today's forecast instead of current weather
    final todayForecast =
    weatherState.forecast.isNotEmpty ? weatherState.forecast[0] : null;
    if (todayForecast == null) {
      return _buildEmptyState();
    }

    final now = DateTime.now();
    final hourlyData = todayForecast['hour'] as List<dynamic>;
    final currentHourData = hourlyData.firstWhere(
          (hour) => DateTime.parse(hour['time']).hour == now.hour,
      orElse: () =>
      currentWeather, // Fallback to current weather if hour not found
    );

    final condition = currentHourData['condition'] ?? {};
    List<Widget> allDetails = [];

    void addDetailIfValid(dynamic value, IconData icon, String suffix,
        {String? prefix}) {
      if (value != null &&
          value.toString().isNotEmpty &&
          value.toString() != 'null' &&
          (value is! num || (value is num && value > 0))) {
        final displayValue = value is num
            ? (value % 1 == 0
            ? value.round().toString()
            : value.toStringAsFixed(1))
            : value.toString();
        allDetails.add(_buildSmallDetailItem(
          icon,
          '${prefix ?? ''}$displayValue$suffix',
        ));
      }
    }

    // Add weather details in a specific order
    addDetailIfValid(currentHourData['temp_c'], Remix.temp_cold_line, '°C');
    addDetailIfValid(currentHourData['wind_kph'], Remix.windy_line, ' km/h');

    if (currentHourData['wind_dir'] != null) {
      addDetailIfValid(
          '${currentHourData['wind_degree']}° ${currentHourData['wind_dir']}',
          Remix.compass_3_line,
          '');
    }

    addDetailIfValid(
        currentHourData['pressure_mb'], Remix.temp_hot_line, ' mb');
    addDetailIfValid(currentHourData['humidity'], Remix.water_flash_line, '%');
    addDetailIfValid(
        currentHourData['precip_mm'], Remix.heavy_showers_line, ' mm');
    addDetailIfValid(currentHourData['cloud'], Remix.cloud_line, '%');

    if (currentHourData['feelslike_c'] != null &&
        (currentHourData['feelslike_c'] - currentHourData['temp_c']).abs() >=
            2) {
      addDetailIfValid(
          currentHourData['feelslike_c'], Remix.temp_cold_line, '°C',
          prefix: 'Feels like ');
    }

    addDetailIfValid(currentHourData['uv'], Remix.sun_line, '',
        prefix: 'UV Index: ');

    // Create forecast data structure for WeatherSummary
    final forecastData = {
      'day': {
        'condition': condition,
        'avgtemp_c': currentHourData['temp_c'],
        'maxtemp_c': currentHourData['temp_c'],
        'mintemp_c': currentHourData['temp_c'],
        'maxwind_kph': currentHourData['wind_kph'],
        'totalprecip_mm': currentHourData['precip_mm'],
        'avghumidity': currentHourData['humidity'],
        'uv': currentHourData['uv'],
        'daily_chance_of_rain': currentHourData['chance_of_rain'],
      },
      'hour': [],
      'date': DateTime.now().toString(),
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            WeatherSummary(
              forecast: forecastData,
              weatherState: weatherState,
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.h),
              child: Divider(
                color: AppStyle.black.withOpacity(0.1),
                height: 1,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      child: WeatherIcon(
                        condition: condition,
                        size: 60.sp,
                        color: AppStyle.black,
                      ),
                    ),
                    Positioned(
                      right: -4,
                      top: -4,
                      child: TemperatureBadge(
                        temperature: currentHourData['temp_c']?.round() ?? 0,
                        fontSize: 12,
                      ),
                    ),
                    if ((currentHourData['chance_of_rain'] ?? 0) >
                        AppConstants.rainPOP)
                      Positioned(
                        right: -4,
                        top: 20,
                        child: TemperatureBadge(
                          temperature: currentHourData['chance_of_rain'],
                          suffix: '%',
                          fontSize: 12,
                          backgroundColor: AppStyle.red,
                        ),
                      ),
                    if ((currentHourData['uv'] ?? 0) >= minUV &&
                        (currentHourData['humidity'] ?? 0) >= minHumidity)
                      Positioned(
                        right: -4,
                        top: (currentHourData['chance_of_rain'] ?? 0) >
                            AppConstants.rainPOP
                            ? 44
                            : 20,
                        child: TemperatureBadge(
                          temperature: currentHourData['uv']?.round() ?? 0,
                          suffix: 'UV',
                          fontSize: 12,
                          backgroundColor:
                          _getUvBadgeColor(currentHourData['uv'] ?? 0),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderInfo(true, DateTime.now(), condition),
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 16.w,
                        runSpacing: 8.h,
                        children: allDetails,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildDetailItems(Map<String, dynamic> forecast) {
    final day = forecast['day'];
    final astro = forecast['astro'];
    final List<Widget> allDetails = [];

    void addDetailIfValid(dynamic value, IconData icon, String suffix,
        {String? prefix}) {
      if (value != null &&
          value.toString().isNotEmpty &&
          value.toString() != 'null' &&
          (value is! num || (value is num && value > 0))) {
        final displayValue = value is num
            ? (value % 1 == 0
            ? value.round().toString()
            : value.toStringAsFixed(1))
            : value.toString();
        allDetails.add(_buildSmallDetailItem(
          icon,
          '${prefix ?? ''}$displayValue$suffix',
        ));
      }
    }

    addDetailIfValid(
        day['daily_chance_of_rain'], Remix.water_percent_line, '%');
    addDetailIfValid(day['totalprecip_mm'], Remix.heavy_showers_line, ' mm');
    addDetailIfValid(day['avghumidity'], Remix.water_flash_line, '%');
    addDetailIfValid(day['maxwind_kph'], Remix.windy_line, ' km/h');
    addDetailIfValid(
        forecast['hour']?[0]?['wind_degree'], Remix.compass_3_line, '°');
    addDetailIfValid(
        forecast['hour']?[0]?['wind_dir'], Remix.compass_discover_line, '');
    addDetailIfValid(
        forecast['hour']?[0]?['pressure_mb'], Remix.temp_hot_line, ' mb');
    addDetailIfValid(day['totalsnow_cm'], Remix.snowy_line, ' cm');
    addDetailIfValid(astro['sunrise'], Remix.sun_line, '');
    addDetailIfValid(astro['sunset'], Remix.moon_line, '');

    return allDetails;
  }

  List<List<Widget>> _distributeDetailsInRows(
      List<Widget> items, BoxConstraints constraints) {
    const double itemSpacing = 16.0;
    final itemWidth = 80.0;
    final maxItemsPerRow =
    (constraints.maxWidth / (itemWidth + itemSpacing)).floor();

    final rows = <List<Widget>>[];
    var currentRow = <Widget>[];
    var currentRowCount = 0;
    var totalRows = 0;

    for (var item in items) {
      if (totalRows >= 3) break;

      if (currentRowCount < maxItemsPerRow) {
        currentRow.add(item);
        currentRowCount++;
      } else {
        rows.add(List.from(currentRow));
        currentRow = [item];
        currentRowCount = 1;
        totalRows++;
      }
    }

    if (currentRow.isNotEmpty && totalRows < 3) {
      rows.add(currentRow);
    }

    return rows;
  }

  Widget _buildHeaderInfo(
      bool isToday, DateTime date, Map<String, dynamic> condition) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isToday ? 'Today' : DateFormat('EEEE').format(date),
          style: GoogleFonts.inter(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            color: AppStyle.black,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          _cleanText(condition['text'].toString()).toCapitalized(),
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            letterSpacing: -0.3,
            color: AppStyle.icon,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentWeatherCard(AsyncValue<WeatherState> weatherAsync) {
    if (!weatherAsync.hasValue) {
      return const SizedBox.shrink();
    }

    // Get current hour data from today's forecast
    final todayForecast = weatherAsync.value!.forecast.isNotEmpty
        ? weatherAsync.value!.forecast[0]
        : null;
    if (todayForecast == null) {
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final hourlyData = todayForecast['hour'] as List<dynamic>;
    final currentHourData = hourlyData.firstWhere(
          (hour) => DateTime.parse(hour['time']).hour == now.hour,
      orElse: () => weatherAsync.value!.weatherData['current'],
    );

    final condition = currentHourData['condition'];

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
                child: WeatherIcon(
                  condition: condition,
                  size: 60.sp,
                  color: AppStyle.black,
                ),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: TemperatureBadge(
                  temperature: currentHourData['temp_c'].round(),
                  fontSize: 12,
                ),
              ),
              if (currentHourData['will_it_rain'] == 1 &&
                  currentHourData['chance_of_rain'] > AppConstants.rainPOP)
                Positioned(
                  right: -4,
                  top: 20,
                  child: TemperatureBadge(
                    temperature: currentHourData['chance_of_rain'],
                    suffix: '%',
                    fontSize: 12,
                    backgroundColor: AppStyle.red,
                  ),
                ),
              if (currentHourData['uv'] != null &&
                  currentHourData['uv'] >= minUV &&
                  currentHourData['humidity'] >= minHumidity)
                Positioned(
                  right: -4,
                  top: currentHourData['will_it_rain'] == 1 &&
                      currentHourData['chance_of_rain'] >
                          AppConstants.rainPOP
                      ? 44
                      : 20,
                  child: TemperatureBadge(
                    temperature: currentHourData['uv'].round(),
                    suffix: 'UV',
                    fontSize: 12,
                    backgroundColor: _getUvBadgeColor(currentHourData['uv']),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'Now',
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: AppStyle.black,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _cleanText(condition['text'].toString()).toCapitalized(),
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

  Widget _buildForecastCard(Map<String, dynamic> forecast) {
    final date = DateTime.parse(forecast['date']);
    final day = forecast['day'];
    final condition = day['condition'];
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());

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
                child: WeatherIcon(
                  condition: condition,
                  size: 60.sp,
                  color: AppStyle.black,
                ),
              ),
              Positioned(
                right: -4,
                top: -4,
                child: TemperatureBadge(
                  temperature: day['avgtemp_c'].round(),
                  fontSize: 12,
                ),
              ),
              if (day['daily_will_it_rain'] == 1 &&
                  day['daily_chance_of_rain'] > AppConstants.rainPOP)
                Positioned(
                  right: -4,
                  top: 20,
                  child: TemperatureBadge(
                    temperature: day['daily_chance_of_rain'],
                    suffix: '%',
                    fontSize: 12,
                    backgroundColor: AppStyle.red,
                  ),
                ),
              if (day['uv'] >= minUV && day['avghumidity'] >= minHumidity)
                Positioned(
                  right: -4,
                  top: day['daily_will_it_rain'] == 1 &&
                      day['daily_chance_of_rain'] > 0
                      ? 44
                      : 20,
                  child: TemperatureBadge(
                    temperature: day['uv'].round(),
                    suffix: 'UV',
                    fontSize: 12,
                    backgroundColor: _getUvBadgeColor(day['uv']),
                  ),
                ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            isToday ? 'Today' : DateFormat('EEEE').format(date),
            style: GoogleFonts.inter(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3,
              color: AppStyle.black,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            _cleanText(condition['text'].toString()).toCapitalized(),
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

  Widget _buildForecastOverview(AsyncValue<WeatherState> weatherAsync,
      List<dynamic> forecastDays, ValueNotifier<int?> selectedIndex) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: ((60.sp + 32.w) *
                  (forecastDays.length + 1)), // Proper width calculation
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => selectedIndex.value = -1,
                    child: _buildCurrentWeatherCard(weatherAsync),
                  ),
                  ...List.generate(
                    forecastDays.length,
                        (index) {
                      final forecast = forecastDays[index];
                      final isLastCard = index == forecastDays.length - 1;
                      return GestureDetector(
                        onTap: () => selectedIndex.value = index,
                        child: Padding(
                          padding: isLastCard
                              ? EdgeInsets.only(right: 16.w)
                              : EdgeInsets.zero,
                          child: _buildForecastCard(forecast),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogHeader(BuildContext context, WidgetRef ref,
      WeatherState weatherState, AsyncValue<WeatherState> weatherAsync,
      {bool isDetailView = false, required VoidCallback onBack}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Weather Forecast',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                color: AppStyle.black,
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              'Updated at ${weatherState.weatherData['current']['last_updated'].toString().substring(11)}',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: AppStyle.icon,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        Row(
          children: [
            AnimationButtonEffect(
              child: Container(
                decoration: BoxDecoration(
                  color: AppStyle.white,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.all(10.r),
                child: CustomRefresher(
                  onTap: () => _handleRefresh(context, ref),
                  isLoading: weatherAsync.maybeWhen(
                    loading: () => true,
                    orElse: () => false,
                  ),
                ),
              ),
            ),
            _buildIconButton(
              icon: isDetailView ? Remix.arrow_left_line : Icons.close,
              onTap: isDetailView ? onBack : () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimationButtonEffect(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.all(8.sp),
            child: Icon(
              icon,
              color: AppStyle.black,
              size: 20.sp,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleRefresh(BuildContext context, WidgetRef ref) async {
    try {
      // Explicitly trigger a manual refresh
      await ref.read(weatherProvider.notifier).refreshWeather(isManual: true);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to fetch weather data',
              style: TextStyle(
                color: AppStyle.white,
                fontSize: 12.sp,
              ),
            ),
            backgroundColor: AppStyle.black,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    // Use initial state from props if no data yet
    final currentState = weatherAsync.value ?? weatherState;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.r),
      ),
      backgroundColor: AppStyle.white,
      child: StatefulBuilder(
        builder: (context, setState) {
          final forecastDays = currentState.forecast;
          final selectedIndex = ValueNotifier<int?>(null);

          if (forecastDays.isEmpty) {
            return _buildEmptyState();
          }

          final isLoading = weatherAsync.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );

          return Stack(
            children: [
              Padding(
                padding: EdgeInsets.all(24.sp),
                child: SizedBox(
                  width: 400.w,
                  child: ValueListenableBuilder<int?>(
                    valueListenable: selectedIndex,
                    builder: (context, selected, child) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDialogHeader(
                            context,
                            ref,
                            currentState,
                            weatherAsync,
                            isDetailView: selected != null,
                            onBack: () {
                              selectedIndex.value = null;
                            },
                          ),
                          SizedBox(height: 16.h),
                          if (selected != null)
                            selected == -1
                                ? _buildCurrentWeatherDetailView(currentState.weatherData['current'])
                                : _buildDetailedView(forecastDays[selected])
                          else
                            _buildForecastOverview(weatherAsync, forecastDays, selectedIndex),
                        ],
                      );
                    },
                  ),
                ),
              ),
              if (isLoading)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(16.sp),
                    child: SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppStyle.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

extension StringExtension on String {
  String toCapitalized() =>
      length > 0 ? '${this[0].toUpperCase()}${substring(1)}' : '';
}
