import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import '../../../../../../../core/constants/constants.dart';
import '../../../../../../theme/theme.dart';
import 'components/badges/temperature_badge.dart';
import 'rain_feedback.dart';
import 'weather_forecast_dialog.dart';
import 'weather_icon.dart';
import 'service/weather_state.dart';
import 'service/weather_service.dart';
import 'weather_status_text.dart';

class WeatherWidget extends ConsumerWidget {
  const WeatherWidget({super.key});

  Map<String, dynamic>? _getCurrentHourData(WeatherState state) {
    final todayForecast = state.forecast.isNotEmpty ? state.forecast[0] : null;
    if (todayForecast == null) {
      return null;
    }

    final now = DateTime.now();
    final hourlyData = todayForecast['hour'] as List<dynamic>;

    try {
      return hourlyData.firstWhere(
            (hour) => DateTime.parse(hour['time']).hour == now.hour,
      );
    } catch (e) {
      print('Error getting current hour data: $e');
      return null;
    }
  }

  int? _getChanceOfRain(WeatherState state) {
    final currentHourData = _getCurrentHourData(state);
    return currentHourData?['chance_of_rain'] as int?;
  }

  String _cleanText(String text) {
    return text.replaceAll(' nearby', '')
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

  num? _getUV(WeatherState state) {
    final currentHourData = _getCurrentHourData(state);
    return currentHourData?['uv'] as num?;
  }

  Widget _buildWeatherStatusText(WeatherState weatherState) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 3), (i) => i),
      builder: (context, snapshot) {
        if (snapshot.data == null) return const SizedBox.shrink();

        final cyclePosition = snapshot.data! % 2;
        String displayText;
        Color textColor;

        if (weatherState.alerts.isNotEmpty && cyclePosition == 1) {
          displayText = _cleanText(weatherState.alerts.first['event'] ?? 'Weather Alert');
          textColor = AppStyle.red;
        } else {
          final currentHourData = _getCurrentHourData(weatherState);
          displayText = _cleanText(currentHourData?['condition']?['text'] ?? '');
          textColor = AppStyle.black;
        }

        return Padding(
          padding: EdgeInsets.only(top: 0.5.sp),
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: 10.sp,
              color: textColor,
              height: 1,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weatherAsync = ref.watch(weatherProvider);

    return weatherAsync.when(
      data: (weatherState) {
        final currentHourData = _getCurrentHourData(weatherState);
        if (currentHourData == null) {
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        SizedBox(
                          width: 16.sp,
                          height: 16.sp,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppStyle.white,
                          ),
                        ),
                        SizedBox(width: 8.sp),
                        Text(
                          'Retrying...',
                          style: TextStyle(color: AppStyle.white),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 2),
                    backgroundColor: AppStyle.black,
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                try {
                  await ref.read(weatherProvider.notifier).refreshWeather();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Retry failed: ${e.toString()}',
                          style: TextStyle(color: AppStyle.white),
                        ),
                        backgroundColor: AppStyle.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No weather data - Tap to retry',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppStyle.red,
                      height: 1,
                    ),
                  ),
                  SizedBox(width: 4.sp),
                  Icon(
                    Remix.refresh_line,
                    size: 16.sp,
                    color: AppStyle.red,
                  ),
                ],
              ),
            ),
          );
        }

        final uv = _getUV(weatherState);
        final currentCondition = currentHourData['condition'];
        final chanceOfRain = _getChanceOfRain(weatherState);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (context) => WeatherForecastDialog(weatherState: weatherState),
              );
            },
            child: Tooltip(
              message: !weatherState.showTemperature ? '${weatherState.cityName} Weather' : '',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Weather Icon and Status Section
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: 40.sp,
                            height: 40.sp,
                            child: WeatherIcon(
                              condition: currentCondition,
                              size: 40.sp,
                              color: AppStyle.black,
                              isNight: !weatherState.isDay,
                            ),
                          ),
                          if (weatherState.showTemperature)
                            Positioned(
                              left: 36.sp,
                              top: -4,
                              child: TemperatureBadge(
                                temperature: currentHourData['temp_c'].round(),
                                fontSize: 10,
                                backgroundColor: AppStyle.black.withOpacity(0.8),
                              ),
                            ),
                          if (!weatherState.showTemperature) ...[
                            if (currentHourData['will_it_rain'] == 1 &&
                                chanceOfRain != null &&
                                chanceOfRain >= AppConstants.rainPOP)
                              Positioned(
                                left: 36.sp,
                                top: -4,
                                child: TemperatureBadge(
                                  temperature: chanceOfRain,
                                  suffix: '%',
                                  fontSize: 10,
                                  backgroundColor: AppStyle.red,
                                ),
                              ),
                            if (uv != null &&
                                currentHourData['humidity'] != null &&
                                uv >= WeatherForecastDialog.minUV &&
                                currentHourData['humidity'] >= WeatherForecastDialog.minHumidity)
                              Positioned(
                                left: 36.sp,
                                top: (chanceOfRain != null &&
                                    chanceOfRain >= AppConstants.rainPOP &&
                                    currentHourData['will_it_rain'] == 1) ? 20 : -4,
                                child: TemperatureBadge(
                                  temperature: uv.round(),
                                  suffix: 'UV',
                                  fontSize: 10,
                                  backgroundColor: _getUvBadgeColor(uv),
                                ),
                              ),
                          ],
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 0.5.sp),
                        child: Text(
                          _cleanText(currentCondition['text']),
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppStyle.black,
                            height: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Weather Text/City Name Section
                  Padding(
                    padding: EdgeInsets.only(left: 8.sp),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: weatherState.showTemperature
                          ? Text(
                        weatherState.cityName,
                        key: const ValueKey('cityname'),
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppStyle.black,
                          height: 1,
                        ),
                      )
                          : RainFeedbackWidget(
                        key: const ValueKey('feedback'),
                        weatherState: weatherState,
                        showCityName: false,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => SizedBox(
        width: 24.sp,
        height: 24.sp,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppStyle.black,
        ),
      ),
      error: (error, stack) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    SizedBox(
                      width: 16.sp,
                      height: 16.sp,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppStyle.white,
                      ),
                    ),
                    SizedBox(width: 8.sp),
                    Text(
                      'Retrying...',
                      style: TextStyle(color: AppStyle.white),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: AppStyle.black,
                behavior: SnackBarBehavior.floating,
              ),
            );

            try {
              await ref.read(weatherProvider.notifier).refreshWeather();
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Retry failed: ${e.toString()}',
                      style: TextStyle(color: AppStyle.white),
                    ),
                    backgroundColor: AppStyle.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Failed to fetch weather - Tap to retry',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppStyle.red,
                  height: 1,
                ),
              ),
              SizedBox(width: 4.sp),
              Icon(
                Remix.refresh_line,
                size: 16.sp,
                color: AppStyle.red,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
