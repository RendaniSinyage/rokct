import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

class OpenWeatherIconMapper {
  static String getIconUrl(String iconCode) {
    return 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  }

  static IconData getRemixIcon(String iconCode) {
    // For daily forecast, we'll use the day version of icons
    final baseCode = iconCode.substring(0, 2); // Get main weather code

    switch (baseCode) {
    // Clear sky
      case '01':
        return Remix.sun_fill;

    // Few clouds
      case '02':
        return Remix.sun_cloudy_fill;

    // Scattered clouds
      case '03':
        return Remix.cloudy_fill;

    // Broken clouds
      case '04':
        return Remix.cloud_fill;

    // Shower rain
      case '09':
        return Remix.showers_fill;

    // Rain
      case '10':
        return Remix.heavy_showers_fill;

    // Thunderstorm
      case '11':
        return Remix.thunderstorms_fill;

    // Snow
      case '13':
        return Remix.snowy_fill;

    // Mist, fog, etc.
      case '50':
        return Remix.mist_fill;

      default:
        return Remix.sun_cloudy_fill;
    }
  }

  static bool isSevereCondition(String iconCode) {
    final baseCode = iconCode.substring(0, 2);
    return [
      '11', // Thunderstorm
    ].contains(baseCode);
  }

  static bool isPrecipitation(String iconCode) {
    final baseCode = iconCode.substring(0, 2);
    return [
      '09', // Shower rain
      '10', // Rain
      '11', // Thunderstorm
      '13', // Snow
    ].contains(baseCode);
  }

  // Helper method to get a description for the icon code
  static String getWeatherDescription(String iconCode) {
    final baseCode = iconCode.substring(0, 2);
    switch (baseCode) {
      case '01':
        return 'Clear sky';
      case '02':
        return 'Few clouds';
      case '03':
        return 'Scattered clouds';
      case '04':
        return 'Broken clouds';
      case '09':
        return 'Shower rain';
      case '10':
        return 'Rain';
      case '11':
        return 'Thunderstorm';
      case '13':
        return 'Snow';
      case '50':
        return 'Mist';
      default:
        return 'Unknown';
    }
  }
}
