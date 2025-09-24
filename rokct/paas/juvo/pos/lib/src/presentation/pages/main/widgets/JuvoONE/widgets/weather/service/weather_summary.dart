import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../theme/theme.dart';
import 'weather_state.dart';

extension StringCapitalization on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}


class WeatherSummary extends StatelessWidget {
  final Map<String, dynamic> forecast;
  final WeatherState weatherState;

   WeatherSummary({
    super.key,
    required this.forecast,
    required this.weatherState,
  });

  // Variety of temperature descriptors
  final List<String> _temperatureDescriptors = [
    'feeling', 'sitting at', 'reaching', 'climbing to', 'hovering around'
  ];

  // Variety of wind descriptors
  final List<String> _windDescriptors = [
    'strong winds blowing',
    'gusty conditions with winds',
    'breezy atmosphere with wind speeds',
    'turbulent winds marking'
  ];

  // Variety of rain descriptors
  final List<String> _rainDescriptors = [
    'precipitation expected',
    'rainfall anticipated',
    'moisture on the horizon',
    'water from the sky likely'
  ];

  // Variety of humidity descriptors
  final List<String> _humidityDescriptors = [
    'moisture levels at',
    'humidity hanging around',
    'atmospheric moisture reading',
    'water vapor concentration'
  ];

  // Randomization helper
  String _randomElement(List<String> list) {
    final random = Random();
    return list[random.nextInt(list.length)];
  }

  // More varied temperature intensity descriptions
  String _describeTemperatureIntensity(double temp) {
    if (temp >= 40) return ['scorching', 'extreme', 'brutal', 'searing'][Random().nextInt(4)];
    if (temp >= 35) return ['very hot', 'intensely warm', 'sweltering', 'blazing'][Random().nextInt(4)];
    if (temp >= 30) return ['quite warm', 'notably hot', 'substantially warm', 'rather heated'][Random().nextInt(4)];
    return 'mild';
  }

  // More conversational condition translations
  String _cleanText(String text) {
    return text
        .replaceAll(' nearby', '')
        .replaceAll(' possible', '')
        .replaceAll('Patchy ', '')
        .toLowerCase();
  }

  // More nuanced period formatting
  String _formatPeriodList(List<String> periods) {
    if (periods.isEmpty) return '';
    if (periods.length == 1) return periods.first;
    if (periods.length == 2) return '${periods.first} and ${periods.last}';
    return '${periods.sublist(0, periods.length - 1).join(", ")}, and ${periods.last}';
  }

  Widget _buildSummary() {
    final day = forecast['day'];
    final hours = forecast['hour'] as List?;
    final location = weatherState.cityName;
    final date = DateTime.parse(forecast['date']);
    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final alerts = forecast['alerts']?['alert'] as List? ?? [];
    final isCurrentWeather = hours == null || hours.isEmpty;

    List<String> summaryLines = [];

    // Process alerts first with more conversational tone
    if (alerts.isNotEmpty) {
      for (var alert in alerts) {
        summaryLines.add('⚠️ Heads up: ${alert['headline']} - ${alert['desc']}');
      }
    }

    if (isCurrentWeather) {
      // More dynamic current weather summary
      String currentLine = [
        'Right now in $location',
        'Currently, $location is experiencing',
        'Weather reports for $location show'
      ][Random().nextInt(3)];

      currentLine += ' ${_cleanText(day['condition']['text'])}';

      // More varied temperature description
      final tempDescriptor = _randomElement(_temperatureDescriptors);
      final temperatureIntensity = _describeTemperatureIntensity(day['avgtemp_c']);

      currentLine += ' with a $temperatureIntensity temperature ${tempDescriptor} ${day['avgtemp_c'].toStringAsFixed(1)}°c';
      summaryLines.add(currentLine);

      // More nuanced conditions line
      List<String> conditions = [];

      // Wind conditions with variety
      if (day['maxwind_kph'] >= 40) {
        conditions.add('${_randomElement(_windDescriptors)} up to ${day['maxwind_kph'].round()} km/h');
      }

      // Precipitation with varied language
      if (day['daily_will_it_rain'] == 1 && day['daily_chance_of_rain'] > AppConstants.rainPOP && day['totalprecip_mm'] > 0) {
        conditions.add('${_randomElement(_rainDescriptors)} of ${day['totalprecip_mm'].toStringAsFixed(1)} mm');
      }

      // Humidity with variety
      conditions.add('${_randomElement(_humidityDescriptors)} ${day['avghumidity'].round()}%');

      // UV warning with conversational tone
      if (day['uv'] >= 8) {
        conditions.add([
          'high UV index - protect yourself',
          'sunscreen recommended',
          'intense sun exposure expected',
          'UV levels demanding caution'
        ][Random().nextInt(4)]);
      }

      String conditionsLine = conditions.join(', ') + '.';
      conditionsLine = conditionsLine[0].toUpperCase() + conditionsLine.substring(1);
      summaryLines.add(conditionsLine);
    } else {
      // Forecast weather analysis with time periods
      Map<String, List<Map<String, dynamic>>> timePeriods = {
        'early morning': [], // 00:00 - 05:59
        'morning': [],      // 06:00 - 11:59
        'afternoon': [],    // 12:00 - 16:59
        'evening': [],      // 17:00 - 20:59
        'night': [],        // 21:00 - 23:59
      };

      for (var hour in hours) {
        final hourNum = DateTime.parse(hour['time']).hour;
        if (hourNum >= 0 && hourNum < 6) timePeriods['early morning']!.add(hour);
        else if (hourNum >= 6 && hourNum < 12) timePeriods['morning']!.add(hour);
        else if (hourNum >= 12 && hourNum < 17) timePeriods['afternoon']!.add(hour);
        else if (hourNum >= 17 && hourNum < 21) timePeriods['evening']!.add(hour);
        else timePeriods['night']!.add(hour);
      }

      // Analyze conditions for each period
      Map<String, Map<String, dynamic>> periodConditions = {};
      for (var period in timePeriods.entries) {
        var hours = period.value;
        if (hours.isEmpty) continue;

        periodConditions[period.key] = {
          'rain': hours.any((h) => h['will_it_rain'] == 1 && h['chance_of_rain'] >= 70),
          'heavy_rain': hours.any((h) => h['will_it_rain'] == 1 && h['chance_of_rain'] >= 90),
          'thunder': hours.any((h) => h['condition']['text'].toLowerCase().contains('thunder')),
          'snow': hours.any((h) => h['will_it_snow'] == 1),
          'high_uv': hours.any((h) => h['uv'] >= 8),
          'strong_wind': hours.any((h) => h['wind_kph'] >= 40),
          'fog': hours.any((h) => h['condition']['text'].toLowerCase().contains('fog') ||
              h['condition']['text'].toLowerCase().contains('mist')),
          'drizzle': hours.any((h) => h['condition']['text'].toLowerCase().contains('drizzle')),
          'high_temp': hours.any((h) => h['temp_c'] >= 35),
        };
      }

      // Weather description variations
      List<String> introVariations = [
        isToday ? 'Weather today in $location' : 'Weather this ${DateFormat('EEEE').format(date).toLowerCase()} in $location',
        'Looking ahead to ${isToday ? "today's" : "this"} forecast for $location',
        '${isToday ? "Today's" : DateFormat('EEEE').format(date).capitalizeFirst()} weather outlook for $location'
      ];
      String mainLine = _randomElement(introVariations);

      // Build weather condition description
      List<String> weatherPeriods = [];
      List<String> conditionPhrases = [];

      // Thunderstorm periods
      var thunderPeriods = periodConditions.entries
          .where((e) => e.value['thunder'])
          .map((e) => e.key)
          .toList();
      if (thunderPeriods.isNotEmpty) {
        weatherPeriods.add('thunderstorms during ${_formatPeriodList(thunderPeriods)}');
      }

      // Heavy rain periods
      var heavyRainPeriods = periodConditions.entries
          .where((e) => e.value['heavy_rain'] && !e.value['thunder'])
          .map((e) => e.key)
          .toList();
      if (heavyRainPeriods.isNotEmpty) {
        weatherPeriods.add('heavy rain during ${_formatPeriodList(heavyRainPeriods)}');
      }

      // Regular rain periods
      if (day['daily_will_it_rain'] == 1 && day['daily_chance_of_rain'] > AppConstants.rainPOP) {
        var rainPeriods = periodConditions.entries
            .where((e) => e.value['rain'] && !e.value['heavy_rain'] && !e.value['thunder'])
            .map((e) => e.key)
            .toList();
        if (rainPeriods.isNotEmpty) {
          weatherPeriods.add('rain during ${_formatPeriodList(rainPeriods)}');
        }
      }

      // Drizzle periods
      var drizzlePeriods = periodConditions.entries
          .where((e) => e.value['drizzle'] && !e.value['rain'] && !e.value['thunder'])
          .map((e) => e.key)
          .toList();
      if (drizzlePeriods.isNotEmpty) {
        weatherPeriods.add('light drizzle during ${_formatPeriodList(drizzlePeriods)}');
      }

      // Snow periods
      var snowPeriods = periodConditions.entries
          .where((e) => e.value['snow'])
          .map((e) => e.key)
          .toList();
      if (snowPeriods.isNotEmpty) {
        weatherPeriods.add('snow during ${_formatPeriodList(snowPeriods)}');
      }

      // Fog periods
      var fogPeriods = periodConditions.entries
          .where((e) => e.value['fog'])
          .map((e) => e.key)
          .toList();
      if (fogPeriods.isNotEmpty) {
        weatherPeriods.add('foggy conditions during ${_formatPeriodList(fogPeriods)}');
      }

      // High temperature periods
      var highTempPeriods = periodConditions.entries
          .where((e) => e.value['high_temp'])
          .map((e) => e.key)
          .toList();
      if (highTempPeriods.length > timePeriods.length / 2) {
        conditionPhrases.add('it will be very hot for most of the day');
      } else if (highTempPeriods.isNotEmpty) {
        conditionPhrases.add('expect very hot conditions during ${_formatPeriodList(highTempPeriods)}');
      }

      // Strong wind periods
      var windyPeriods = periodConditions.entries
          .where((e) => e.value['strong_wind'])
          .map((e) => e.key)
          .toList();
      if (windyPeriods.length > timePeriods.length / 2) {
        conditionPhrases.add('strong winds will persist throughout the day');
      } else if (windyPeriods.isNotEmpty) {
        conditionPhrases.add('expect strong winds during ${_formatPeriodList(windyPeriods)}');
      }

      // Build the weather description
      if (weatherPeriods.isNotEmpty) {
        mainLine += ' will have ${weatherPeriods.join(', ')}';
        if (conditionPhrases.isNotEmpty) {
          mainLine += '. Additionally, ${conditionPhrases.join(', ')}';
        }
      } else {
        mainLine += ' will be ${_cleanText(day['condition']['text'])}';
        if (conditionPhrases.isNotEmpty) {
          mainLine += '. ${conditionPhrases.join(', ')}';
        }
      }

      // Temperature description with variation
      if (day['maxtemp_c'] >= 35) {
        mainLine += '. Extremely hot with temperatures soaring to ${day['maxtemp_c'].toStringAsFixed(1)}°c';
      } else {
        mainLine += '. Daytime temperatures will peak at ${day['maxtemp_c'].toStringAsFixed(1)}°c';
      }
      mainLine += ' and dipping to ${day['mintemp_c'].toStringAsFixed(1)}°c as night falls';
      summaryLines.add(mainLine);

      // Detailed conditions line
      List<String> conditions = [];

      // Precipitation
      if (day['daily_will_it_rain'] == 1 && day['daily_chance_of_rain'] > AppConstants.rainPOP && day['totalprecip_mm'] > 0) {
        conditions.add('expecting around ${day['totalprecip_mm'].toStringAsFixed(1)} mm of precipitation');
      }

      // Humidity
      conditions.add('humidity levels hovering around ${day['avghumidity'].round()}%');

      // UV warning
      if (day['uv'] >= 8) {
        var uvWarning = 'UV index running high';
        if (weatherPeriods.any((p) => p.contains('rain') || p.contains('thunder'))) {
          uvWarning += ' between the showers';
        }
        uvWarning += ' - take precautions';
        conditions.add(uvWarning);
      }

      // Wind conditions
      if (day['maxwind_kph'] >= 40 && windyPeriods.isEmpty) {
        conditions.add('winds potentially reaching up to ${day['maxwind_kph'].round()} km/h');
      }

      String conditionsLine = conditions.join(', ') + '.';
      conditionsLine = conditionsLine[0].toUpperCase() + conditionsLine.substring(1);
      summaryLines.add(conditionsLine);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: summaryLines.map((line) => Padding(
        padding: EdgeInsets.only(bottom: 8.h),
        child: Text(
          line,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            color: line.startsWith('⚠️') ? AppStyle.red : AppStyle.black,
            height: 1.5,
          ),
        ),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildSummary();
  }
}
