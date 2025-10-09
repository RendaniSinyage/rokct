class WeatherState {
  final Map<String, dynamic> weatherData;
  final bool showTemperature;
  final String cityName;
  final int version;
  final DateTime lastUpdated;
  final bool hasError;

  WeatherState({
    required this.weatherData,
    required this.showTemperature,
    required this.cityName,
    int? version,
    DateTime? lastUpdated,
    this.hasError = false,
  })  : version = version ?? DateTime.now().millisecondsSinceEpoch,
        lastUpdated = lastUpdated ?? DateTime.now() {
    // Basic validation only
    if (!weatherData.containsKey('current') || !weatherData.containsKey('forecast')) {
      throw ArgumentError('Missing required weather data fields');
    }
  }

  // Getter for current temperature with proper type conversion
  double get temperature {
    try {
      final temp = weatherData['current']['temp_c'];
      if (temp == null) return 0.0;
      return (temp is int) ? temp.toDouble() : temp;
    } catch (e) {
      print('Error getting temperature: $e');
      return 0.0;
    }
  }

  // Getter for weather condition
  Map<String, dynamic> get condition {
    return weatherData['current']['condition'] as Map<String, dynamic>? ??
        {'text': 'Unknown', 'code': 1000};
  }

  // Getter for forecast data
  List<dynamic> get forecast {
    return weatherData['forecast']?['forecastday'] as List<dynamic>? ?? [];
  }

  // Getter for day/night status
  bool get isDay {
    return weatherData['current']?['is_day'] == 1;
  }

  // Getter for weather alerts
  List<dynamic> get alerts {
    return weatherData['alerts']?['alert'] as List<dynamic>? ?? [];
  }

  // Getter for humidity
  double get humidity {
    try {
      final hum = weatherData['current']['humidity'];
      if (hum == null) return 0.0;
      return (hum is int) ? hum.toDouble() : hum;
    } catch (e) {
      print('Error getting humidity: $e');
      return 0.0;
    }
  }

  // Get hourly forecast for specific day
  List<Map<String, dynamic>> getHourlyForecast(int dayIndex) {
    try {
      if (dayIndex < 0 || dayIndex >= forecast.length) return [];
      final dayForecast = forecast[dayIndex];
      return (dayForecast['hour'] as List<dynamic>?)
          ?.map((hour) => hour as Map<String, dynamic>)
          .toList() ?? [];
    } catch (e) {
      print('Error getting hourly forecast: $e');
      return [];
    }
  }

  // Get daily summary for specific day
  Map<String, dynamic> getDailySummary(int dayIndex) {
    try {
      if (dayIndex < 0 || dayIndex >= forecast.length) {
        return {'error': 'Invalid day index'};
      }

      final dayForecast = forecast[dayIndex];
      return {
        'date': dayForecast['date'],
        'maxtemp_c': dayForecast['day']?['maxtemp_c'] ?? 0.0,
        'mintemp_c': dayForecast['day']?['mintemp_c'] ?? 0.0,
        'avgtemp_c': dayForecast['day']?['avgtemp_c'] ?? 0.0,
        'daily_chance_of_rain': dayForecast['day']?['daily_chance_of_rain'] ?? 0,
        'condition': dayForecast['day']?['condition'] ?? {'text': 'Unknown', 'code': 1000},
        'sunrise': dayForecast['astro']?['sunrise'] ?? 'Unknown',
        'sunset': dayForecast['astro']?['sunset'] ?? 'Unknown',
      };
    } catch (e) {
      print('Error getting daily summary: $e');
      return {'error': 'Failed to get daily summary'};
    }
  }

  // Helper method to get temperature for specific hour
  double getHourlyTemperature(int dayIndex, int hour) {
    try {
      final hourlyData = getHourlyForecast(dayIndex);
      if (hour < 0 || hour >= hourlyData.length) return 0.0;

      final temp = hourlyData[hour]['temp_c'];
      return (temp is int) ? temp.toDouble() : (temp ?? 0.0);
    } catch (e) {
      print('Error getting hourly temperature: $e');
      return 0.0;
    }
  }

  // Helper method to check if there are any severe weather alerts
  bool get hasSevereAlerts {
    return alerts.any((alert) =>
    alert['severity']?.toString().toLowerCase() == 'severe' ||
        alert['severity']?.toString().toLowerCase() == 'extreme');
  }

  // Create a new instance with updated fields
  WeatherState copyWith({
    Map<String, dynamic>? weatherData,
    bool? showTemperature,
    String? cityName,
    int? version,
    DateTime? lastUpdated,
    bool? hasError,
  }) {
    return WeatherState(
      weatherData: weatherData ?? this.weatherData,
      showTemperature: showTemperature ?? this.showTemperature,
      cityName: cityName ?? this.cityName,
      version: version ?? (this.version + 1),
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'WeatherState(cityName: $cityName, '
        'showTemperature: $showTemperature, temperature: $temperature, '
        'version: $version, lastUpdated: $lastUpdated)';
  }
}
