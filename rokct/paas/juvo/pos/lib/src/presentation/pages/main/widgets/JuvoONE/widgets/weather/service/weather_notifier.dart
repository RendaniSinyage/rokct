import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../../../../core/constants/constants.dart';
import '../../../../../../../../core/utils/utils.dart';
import 'weather_service.dart';
import 'weather_state.dart';

class WeatherNotifier extends StateNotifier<AsyncValue<WeatherState>> {
  final WeatherService _weatherService;
  Timer? _temperatureTimer;
  Timer? _refreshTimer;
  StreamSubscription? _connectivitySubscription;
  DateTime? _lastUpdate;
  static const Duration _temperatureDuration = Duration(seconds: 5);

  WeatherNotifier(this._weatherService) : super(const AsyncValue.loading()) {
    _loadWeather();
    _setupRefreshTimer();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    _connectivitySubscription = _weatherService.connectivityStream.listen((isConnected) {
      if (isConnected && state.hasValue && state.value!.hasError) {
        refreshWeather();
      }
    });
  }

  void _setupRefreshTimer() {
    _refreshTimer?.cancel();
    print('Setting up weather refresh timer for ${AppConstants.weatherRefresher.inMinutes} minutes');
    _refreshTimer = Timer.periodic(
      AppConstants.weatherRefresher,
          (_) {
        print('Weather refresh timer triggered');
        _loadWeather();
      },
    );
  }

  void resetTemperatureTimer() {
    if (state.hasValue) {
      state = AsyncValue.data(state.value!.copyWith(showTemperature: true));
      _startTemperatureTimer();
    }
  }

  Future<void> refreshWeather({bool isManual = false}) async {
    // Check if this is a manual refresh
    if (!isManual &&
        _lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!) < const Duration(minutes: 30)) {
      print('Skipping automatic refresh - last update was too recent');
      return;
    }

    try {
      final location = LocalStorage.getShopLocation();
      final double latitude = location?.latitude ?? AppConstants.demoLatitude;
      final double longitude = location?.longitude ?? AppConstants.demoLongitude;

      print('Refreshing weather for lat: $latitude, lon: $longitude');

      final weatherData = await _weatherService.getCurrentWeather(latitude, longitude);
      _lastUpdate = DateTime.now();

      state = AsyncValue.data(WeatherState(
        weatherData: weatherData,
        showTemperature: true,
        cityName: weatherData['location']['name'],
        hasError: false,
        lastUpdated: _lastUpdate,
      ));

      _startTemperatureTimer();
    } catch (e, stack) {
      print('Error refreshing weather: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> _loadWeather() async {
    if (_lastUpdate != null &&
        DateTime.now().difference(_lastUpdate!) < const Duration(minutes: 30)) {
      print('Skipping weather load - last update was too recent');
      return;
    }

    try {
      final location = LocalStorage.getShopLocation();
      final double latitude = location?.latitude ?? AppConstants.demoLatitude;
      final double longitude = location?.longitude ?? AppConstants.demoLongitude;

      final weatherData = await _weatherService.getCurrentWeather(latitude, longitude);
      _lastUpdate = DateTime.now();

      state = AsyncValue.data(WeatherState(
        weatherData: weatherData,
        showTemperature: true,
        cityName: weatherData['location']['name'],
        hasError: false,
        lastUpdated: _lastUpdate,
      ));

      _startTemperatureTimer();
    } catch (e) {
      if (!state.hasValue) {
        state = AsyncValue.error(e, StackTrace.current);
      } else {
        state = AsyncValue.data(state.value!.copyWith(
          version: DateTime.now().millisecondsSinceEpoch,
          hasError: true,
          lastUpdated: DateTime.now(),
        ));
      }
    }
  }

  void _startTemperatureTimer() {
    _temperatureTimer?.cancel();
    _temperatureTimer = Timer(_temperatureDuration, () {
      if (state.hasValue) {
        state = AsyncValue.data(state.value!.copyWith(showTemperature: false));
      }
    });
  }

  @override
  void dispose() {
    _temperatureTimer?.cancel();
    _refreshTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
