import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../../../core/constants/constants.dart';
import 'open_weather_state.dart';

class OpenWeatherService {
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';
  static String apiKey = AppConstants.openWeatherApiKey;

  // Cache configuration
  static const Duration cacheDuration = Duration(minutes: 30);
  static const String cacheKey = 'open_weather_extended_cache';
  static const int maxRetries = 3;

  final http.Client _client;

  OpenWeatherService({http.Client? client}) : _client = client ?? http.Client();

  Future<Map<String, dynamic>> getExtendedForecast(double lat, double lon) async {
    try {
      // Check cache first
      final cachedData = await _getCachedData();
      if (cachedData != null && !_isCacheExpired(cachedData['timestamp'])) {
        print('Using cached forecast data');
        return cachedData['data'];
      }

      // Validate API key and coordinates
      if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY') {
        throw Exception('Invalid OpenWeatherMap API Key');
      }

      if (lat == 0 && lon == 0) {
        throw Exception('Invalid coordinates');
      }

      print('Fetching extended forecast for coordinates: $lat, $lon');

      // Fetch fresh data with retry logic
      final data = await _fetchWithRetry(
          '$baseUrl/forecast',
          {
            'appid': apiKey,
            'lat': lat.toString(),
            'lon': lon.toString(),
            'units': 'metric', // Ensure temperatures in Celsius
          }
      );

      // Extensive validation of response
      if (data == null) {
        throw Exception('Received null data from API');
      }

      if (data['list'] == null || (data['list'] as List).isEmpty) {
        throw Exception('No forecast data available in the response');
      }

      // Print some diagnostic information
      print('Received forecast data');
      print('Total forecast entries: ${data['list'].length}');
      print('First forecast entry: ${data['list'][0]}');

      // Cache the new data
      await _cacheData(data);

      return data;
    } catch (e, stack) {
      print('Error fetching extended forecast: $e');
      print('Stack trace: $stack');

      // If fetch fails and we have cached data, return it even if expired
      final cachedData = await _getCachedData();
      if (cachedData != null) {
        print('Falling back to cached data');
        return cachedData['data'];
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _fetchWithRetry(
      String url,
      Map<String, String> queryParams, {
        int attempt = 1,
      }) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      print('Fetching URL: $uri');

      final response = await _client.get(
        uri,
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        // Additional validation
        if (responseBody['cod'] != '200') {
          print('API returned error: ${responseBody['message']}');
          throw Exception('API returned error: ${responseBody['message']}');
        }

        return responseBody;
      }

      throw OpenWeatherServiceException(
        'Failed to load weather data: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    } catch (e) {
      print('Fetch attempt $attempt failed: $e');
      if (attempt < maxRetries) {
        final waitTime = Duration(milliseconds: 1000 * attempt);
        await Future.delayed(waitTime);
        return _fetchWithRetry(url, queryParams, attempt: attempt + 1);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _getCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(cacheKey);
      if (cachedString != null) {
        return json.decode(cachedString);
      }
      return null;
    } catch (e) {
      print('Error reading cache: $e');
      return null;
    }
  }

  Future<void> _cacheData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(cacheKey, json.encode(cacheData));
    } catch (e) {
      print('Error caching data: $e');
    }
  }

  bool _isCacheExpired(int timestamp) {
    final age = DateTime.now().millisecondsSinceEpoch - timestamp;
    return age > cacheDuration.inMilliseconds;
  }

  void dispose() {
    _client.close();
  }
}

class OpenWeatherServiceException implements Exception {
  final String message;
  final int? statusCode;

  OpenWeatherServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'OpenWeatherServiceException: $message';
}

// Providers
final openWeatherServiceProvider = Provider((ref) => OpenWeatherService());

final openWeatherProvider = StateNotifierProvider<OpenWeatherNotifier, AsyncValue<OpenWeatherState>>((ref) {
  final weatherService = ref.watch(openWeatherServiceProvider);
  return OpenWeatherNotifier(weatherService);
});

class OpenWeatherNotifier extends StateNotifier<AsyncValue<OpenWeatherState>> {
  final OpenWeatherService _weatherService;

  OpenWeatherNotifier(this._weatherService) : super(const AsyncValue.loading());

  Future<void> loadExtendedForecast(double lat, double lon) async {
    try {
      state = const AsyncValue.loading();
      final weatherData = await _weatherService.getExtendedForecast(lat, lon);

      // Validate data before creating state
      if (weatherData['list'] == null || (weatherData['list'] as List).isEmpty) {
        state = AsyncValue.error(
            Exception('No forecast data available'),
            StackTrace.current
        );
        return;
      }

      state = AsyncValue.data(OpenWeatherState(
        weatherData: weatherData,
        lastUpdated: DateTime.now(),
      ));
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      print('Error loading extended forecast: $e');
    }
  }
}
