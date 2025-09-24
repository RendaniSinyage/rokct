import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../../core/utils/utils.dart';
import 'weather_notifier.dart';
import 'weather_state.dart';

class WeatherService {
  static const String geoNamesUrl = 'http://api.geonames.org/findNearbyJSON';
  static const String geoNamesUsername = 'juvoplatforms';

  final http.Client _client;
  final _connectivityController = StreamController<bool>.broadcast();
  StreamSubscription<bool>? _connectivitySubscription;
  static const int maxRetries = 3;
  DateTime? _lastWeatherUpdate;

  WeatherService({http.Client? client})
      : _client = client ?? http.Client() {
    _initializeConnectivityMonitoring();
  }

  void _initializeConnectivityMonitoring() {
    AppConnectivity.connectivity().then((isConnected) {
      _connectivityController.add(isConnected);
    });

    // Check connectivity less frequently and only emit distinct values
    _connectivitySubscription = Stream.periodic(const Duration(minutes: 5))
        .asyncMap((_) => AppConnectivity.connectivity())
        .distinct()
        .listen((isConnected) {
      _connectivityController.add(isConnected);
      if (isConnected) {
        _handleConnectionRestored();
      }
    });
  }

  Stream<bool> get connectivityStream => _connectivityController.stream;

  Future<bool> checkConnectivity() async {
    return AppConnectivity.connectivity();
  }

  Future<void> _handleConnectionRestored() async {
    try {
      // Check if we've updated recently
      if (_lastWeatherUpdate != null &&
          DateTime.now().difference(_lastWeatherUpdate!) < const Duration(minutes: 30)) {
        print('Skipping connection restored update - too recent');
        return;
      }

      final location = LocalStorage.getShopLocation();
      if (location != null) {
        await getCurrentWeather(
            location.latitude ?? AppConstants.demoLatitude,
            location.longitude ?? AppConstants.demoLongitude
        );
        _lastWeatherUpdate = DateTime.now();
      }
    } catch (e) {
      print('Error refreshing weather data after connection restored: $e');
    }
  }

  Future<String> _getCityFromCoordinates(double lat, double lon) async {
    // First, check if we have a cached city name
    final cachedCityName = await _getCachedCityName(lat, lon);
    if (cachedCityName != null) {
      return cachedCityName;
    }

    if (!await checkConnectivity()) {
      return 'messina,za'; // Default location if no connectivity
    }

    try {
      final uri = Uri.parse('$geoNamesUrl?lat=$lat&lng=$lon&username=$geoNamesUsername');
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['geonames']?.isNotEmpty) {
          final cityData = data['geonames'][0];
          final cityName = cityData['name'];
          final countryCode = cityData['countryCode'].toString().toLowerCase();
          final fullCityName = '$cityName,$countryCode';

          // Cache the city name
          await _cacheCityName(lat, lon, fullCityName);
          return fullCityName;
        }
      }
      return 'messina,za'; // Default location if API fails
    } catch (e) {
      print('Error getting city name: $e');
      return 'messina,za'; // Default location on error
    }
  }

  Future<void> _cacheCityName(double lat, double lon, String cityName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'city_cache_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
      await prefs.setString(cacheKey, cityName);
    } catch (e) {
      print('Error caching city name: $e');
    }
  }

  Future<String?> _getCachedCityName(double lat, double lon) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'city_cache_${lat.toStringAsFixed(4)}_${lon.toStringAsFixed(4)}';
      return prefs.getString(cacheKey);
    } catch (e) {
      print('Error getting cached city name: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getCurrentWeather(double lat, double lon) async {
    if (!await checkConnectivity()) {
      throw WeatherServiceException('No internet connection');
    }

    try {
      // Always get city name first (or use default)
      final cityLocation = await _getCityFromCoordinates(lat, lon);
      print('Using location for weather: $cityLocation');

      final weatherData = await _fetchWithRetry(
        'api/v1/rest/weather',
        {
          'q': cityLocation,
          'days': '3',
          'alerts': 'yes'
        },
      );

      _lastWeatherUpdate = DateTime.now();
      return weatherData;
    } catch (e) {
      print('Weather fetch error: $e');
      throw WeatherServiceException('Failed to fetch weather data: $e');
    }
  }

  Future<Map<String, dynamic>> _fetchWithRetry(
      String endpoint,
      Map<String, String> queryParams, {
        int attempt = 1,
      }) async {
    try {
      final url = '${AppConstants.baseUrl}$endpoint';
      final uri = Uri.parse(url).replace(queryParameters: queryParams);
      final token = LocalStorage.getToken();

      final response = await _client.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.statusCode == 204 ? '{}' : response.body);
      }

      switch (response.statusCode) {
        case 401:
          throw WeatherServiceException('Unauthorized - Invalid token');
        case 100:
          throw WeatherServiceException('not logged in');
        case 403:
          throw WeatherServiceException('Access forbidden');
        case 429:
          throw WeatherServiceException('Too many requests');
        default:
          throw WeatherServiceException(
            'Failed to load weather data: ${response.statusCode}',
          );
      }
    } catch (e) {
      if (attempt < maxRetries && await checkConnectivity()) {
        final waitTime = Duration(milliseconds: 1000 * attempt);
        await Future.delayed(waitTime);
        return _fetchWithRetry(endpoint, queryParams, attempt: attempt + 1);
      }
      rethrow;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
    _client.close();
  }
}

class WeatherServiceException implements Exception {
  final String message;
  final int? statusCode;

  WeatherServiceException(this.message, {this.statusCode});

  @override
  String toString() => 'WeatherServiceException: $message';
}

// Providers
final weatherServiceProvider = Provider((ref) => WeatherService());

final weatherProvider = StateNotifierProvider<WeatherNotifier, AsyncValue<WeatherState>>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  return WeatherNotifier(weatherService);
});

final connectivityProvider = StreamProvider<bool>((ref) {
  final weatherService = ref.watch(weatherServiceProvider);
  return weatherService.connectivityStream;
});
